extends Node
## 全局背单词：多词书合并 + 简易间隔复习 + 出牌前拼写门控。
## 词书来源：builtin_default（res://data/vocab_words.json）、res://data/vocab_books/*.json、user://vocab_books/*.json
## 启用列表：UserSettingsData.settings_vocab_enabled_book_ids
## 导入：import_book_from_json_text / import_book_from_user_absolute_path
## API 例句缓存：user://vocab_example_cache.json（每日按顺序预生成 + 出牌按需写入）；profile 仍可有 profile_vocab_example_overrides 覆盖。

const LEGACY_VOCAB_PATH := "res://data/vocab_words.json"
const PACKAGED_BOOKS_DIR := "res://data/vocab_books/"
const USER_BOOKS_DIR := "user://vocab_books/"
const JSON_BOOKS_DIR := "res://json/"
const VOCAB_EXAMPLE_CACHE_PATH := "user://vocab_example_cache.json"
const BUILTIN_DEFAULT_ID := "builtin_default"
## 遗物「初稿免责」：每场战斗第一次 **答错 / 点「看答案」**（非跳过）时，不记 SRS 失败且仍允许本张牌打出。
const ARTIFACT_ARCHIVIST_FIRST_DRAFT_ID := "artifact_archivist_first_draft"
## 出牌前复习题型（与 UserSettingsData.settings_vocab_combat_review_mode 一致）
const VOCAB_REVIEW_MODE_SPELL := "spell"
const VOCAB_REVIEW_MODE_MEANING := "meaning"
const VOCAB_REVIEW_MODE_MC4 := "mc4"
const EXAMPLE_API_BATCH_SIZE := 10
const BACKGROUND_EXAMPLE_PREFETCH_WORDS := 12
const BACKGROUND_EXAMPLE_PREFETCH_START_DELAY_SECONDS := 2.0
const BACKGROUND_EXAMPLE_PREFETCH_DELAY_SECONDS := 6.0
## 仅英文提示自评：记得 / 不记得（不记得可标记回未学）
const VOCAB_REVIEW_MODE_RECALL := "recall"
## 学习环节 id 的固定顺序（与 settings_vocab_learn_steps_enabled 组合）
const VOCAB_LEARN_STEP_ORDER: Array[String] = ["en2zh", "zh2en", "spell", "dictation"]

## 背单词模式
const VOCAB_MODE_PER_CARD := "per_card"  ## 每张牌复习一次（现有模式）
const VOCAB_MODE_PER_TURN := "per_turn"  ## 每回合一个单词，按顺序学习/复习

const OPENAI_EXAMPLE_SYSTEM_BASE := """你是英语学习词书编辑。用户会给出词条的英文 headword、中文释义、词性、以及游戏里的默写题干说明。
请生成 2～4 条英文例句，尽量覆盖不同义项或用法；每条配一行简短中文 gloss 标明该句侧重的义（可与释义栏对应）。
每条必须另附 sentence_zh：对该英文例句的完整、自然的中文翻译（整句译意，不要只重复 gloss；不要留空字符串）。
例句里必须自然包含该英文单词（可用适当词形变化）。根据词性确保例句中单词的用法正确（如动词用谓语、名词用主宾等）。不要编造不存在的专有名词剧情。
禁止在 sentence、gloss、sentence_zh 的文本里写入任何 BBCode（如 [center]、[/color]）或 HTML 标签。
只输出 JSON 对象，格式严格如下（不要 markdown 代码围栏）：
{"examples":[{"sentence":"英文例句","gloss":"中文义项提示","sentence_zh":"该句完整中文翻译"},...]}
"""

const OPENAI_EXAMPLE_SYSTEM_BATCH := """你是英语学习词书编辑。用户会给出若干词条信息（英文 headword、中文释义、词性、所属词书、领域偏好）。
请为每个词条生成 2～3 条英文例句，尽量覆盖不同义项或用法；每条配一行简短中文 gloss 标明该句侧重的义（可与释义栏对应）。
每条必须另附 sentence_zh：对该英文例句的完整、自然的中文翻译（整句译意，不要只重复 gloss；不要留空字符串）。
例句里必须自然包含该英文单词（可用适当词形变化）。根据词性确保例句中单词的用法正确（如动词用谓语、名词用主宾等）。不要编造不存在的专有名词剧情。
请根据「词书」和「领域偏好」调整例句风格：例如考研词汇用学术/真题风格，影视领域用词可融入电影场景，游戏领域用词可融入游戏剧情。
禁止在 sentence、gloss、sentence_zh 的文本里写入任何 BBCode 或 HTML 标签。
只输出 JSON 对象，格式严格如下（不要 markdown 代码围栏）：
{"batch":[{"word_id":"词条ID","examples":[{"sentence":"英文例句","gloss":"中文义项提示","sentence_zh":"该句完整中文翻译"},...]},...]}
"""

const OPENAI_GENERATE_BOOK_SYSTEM := """你是英语学习词书编辑。用户会描述想要什么类型的英语词汇（场景、考试、领域、难度等）。
请直接生成一份完整词书 JSON 对象，格式严格如下：
{
  "book_id": "ai_<英文简称>",
  "book_name": "<中文书名>",
  "words": [
    {
      "id": "<英文单词>",
      "study_headword": "<英文单词>",
      "study_meaning": "<中文释义>",
      "study_phonetic": "<IPA音标>",
      "study_pos": "<词性，如 v./n./adj.>",
      "prompt": "[center]释义：<中文释义>\\n请写出对应英文单词[/center]",
      "answers": ["<英文单词>"]
    }
  ]
}
规则：
- book_id 以 ai_ 开头，后接有意义的英文简称（如 ai_toefl_core）
- book_name 用简洁中文
- 每个 word 的 id 用英文单词本身（小写，无空格）
- answers 数组内只放一个元素：该英文单词
- prompt 中的 \\n 为换行符，BBCode 原样保留
- study_meaning 写完整的中文释义
- study_phonetic 写 IPA 音标，用斜杠包裹，如 /əˈbændən/
- study_pos 写词性缩写，多个词性用 / 分隔，如 v./n. 或 adj./n.
- 严格按用户要求的数量生成
- 只输出 JSON 对象，不要 markdown 代码围栏
- 不要在 JSON 外输出任何解释文字
"""

const PRESET_DOMAIN_ZH: Dictionary = {
	"film_tv": "影视",
	"anime": "动漫 / 二次元",
	"exam_style": "考研 / 真题风",
	"daily": "日常口语",
	"news": "新闻 / 评论",
	"game_scifi": "游戏 / 科幻",
}
const DEFAULT_EXAMPLE_DOMAIN_PRESETS: Array[String] = ["game_scifi", "daily"]

var _words: Array[Dictionary] = []
var _id_to_word: Dictionary = {}  # word id → word Dictionary (index for O(1) lookup)
var _profile_dirty: bool = false  # defer save_profile() to batch writes
var _overlay: WordReviewOverlay = null
var _combat_first_draft_forgiveness_used: bool = false
## book_id -> 绝对路径（res:// 或 user://）
var _book_id_to_path: Dictionary[String, String] = {}
## 开局「每日顺序预生成」与出牌「按需例句」可能同时进行；共用一个 HTTPRequest 时第二发会 ERR_BUSY，例句静默失败。
var _example_http_batch: HTTPRequest
var _example_http_ondemand: HTTPRequest
var _example_fetch_in_progress: Dictionary[String, bool] = {}
## 模型仍不给 sentence_zh 时本局标记放弃，避免每张牌都重复打 API
var _vocab_example_zh_gave_up_ids: Dictionary = {}
var _example_cache_loaded: bool = false
var _example_cache_entries: Dictionary = {}
var _sequential_batch_busy: bool = false
var _example_prefetch_busy: bool = false
var _example_prefetch_timer_pending: bool = false
var _example_prefetch_requested_this_run: int = 0
## 项目根 res://.env 或 DOTENV_PATH（与 tools/generate_vocab_examples.py 一致）；Godot 不会自动把 .env 注入 OS 环境变量。
var _dotenv_parsed: bool = false
var _dotenv_values: Dictionary = {}

## 每回合模式状态
var _per_turn_current_word_id: String = ""  ## 当前回合的单词ID
var _per_turn_current_step_index: int = 0  ## 当前单词的复习步骤索引（en2zh→zh2en→spell→dictation）


func _ensure_project_dotenv_loaded() -> void:
	if _dotenv_parsed:
		return
	_dotenv_parsed = true
	# 先读项目根 .env，再读 DOTENV_PATH（后者可覆盖同名键）。不要「读完第一个就 break」，否则系统里误设的 DOTENV_PATH 会挡住仓库里的 .env。
	var paths: Array[String] = []
	var res_env := "res://.env"
	paths.append(res_env)
	var abs_env := ProjectSettings.globalize_path(res_env).strip_edges()
	if not abs_env.is_empty() and abs_env != res_env:
		paths.append(abs_env)
	var from_os := OS.get_environment("DOTENV_PATH").strip_edges()
	if not from_os.is_empty():
		paths.append(from_os)
	var seen: Dictionary = {}
	var loaded_any: bool = false
	for p: String in paths:
		if p.is_empty() or seen.get(p, false):
			continue
		seen[p] = true
		if not FileAccess.file_exists(p):
			continue
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null:
			continue
		loaded_any = true
		while not f.eof_reached():
			_apply_dotenv_line(str(f.get_line()))
		f.close()
	if loaded_any and str(_dotenv_values.get("OPENAI_API_KEY", "")).strip_edges().is_empty():
		push_warning(
			"VocabStudy: 已读取 .env 文件但未得到 OPENAI_API_KEY；请检查是否为 KEY=value 单行、无多余引号未闭合，或 Key 写在其它 env 文件而未被上述路径覆盖。"
		)


func _apply_dotenv_line(line_raw: String) -> void:
	var line := line_raw.strip_edges()
	if line.is_empty() or line.begins_with("#"):
		return
	var eq := line.find("=")
	if eq <= 0:
		return
	var key := line.substr(0, eq).strip_edges()
	while key.begins_with("\ufeff"):
		key = key.substr(1)
	if key.is_empty():
		return
	var val := line.substr(eq + 1).strip_edges()
	while val.begins_with("\ufeff"):
		val = val.substr(1)
	if val.length() >= 2:
		var q0 := val[0]
		var q1 := val[val.length() - 1]
		if (q0 == "\"" and q1 == "\"") or (q0 == "'" and q1 == "'"):
			val = val.substr(1, val.length() - 2).strip_edges()
	# 多文件合并时：后读文件里「空值」不覆盖先读到的非空值（避免 DOTENV_PATH 里 OPENAI_API_KEY= 抹掉项目 .env 里的 Key）
	if val.strip_edges().is_empty():
		var prev: String = str(_dotenv_values.get(key, "")).strip_edges()
		if not prev.is_empty():
			return
	_dotenv_values[key] = val


func _ready() -> void:
	_example_http_batch = HTTPRequest.new()
	_example_http_batch.timeout = 120
	add_child(_example_http_batch)
	_example_http_ondemand = HTTPRequest.new()
	_example_http_ondemand.timeout = 120
	add_child(_example_http_ondemand)
	reload_from_settings()
	if not Signals.combat_started.is_connected(_on_combat_started_reset_first_draft):
		Signals.combat_started.connect(_on_combat_started_reset_first_draft)
	# 应用启动时直接调用例句预生成（无需等待 run_started）
	_on_run_started_vocab_example_batch()
	# 仍需监听 run_started 来重置 per_turn 状态和清理标记
	if not Signals.run_started.is_connected(_on_run_started_vocab_example_batch):
		Signals.run_started.connect(_on_run_started_vocab_example_batch)
	if not Signals.run_ended.is_connected(_on_run_ended_vocab_example_prefetch):
		Signals.run_ended.connect(_on_run_ended_vocab_example_prefetch)
	if not Signals.map_location_selected.is_connected(_on_vocab_example_prefetch_opportunity):
		Signals.map_location_selected.connect(_on_vocab_example_prefetch_opportunity)
	if not Signals.combat_ended.is_connected(_on_vocab_example_prefetch_opportunity):
		Signals.combat_ended.connect(_on_vocab_example_prefetch_opportunity)
	if not Signals.reward_grant_requested.is_connected(_on_reward_vocab_example_prefetch_opportunity):
		Signals.reward_grant_requested.connect(_on_reward_vocab_example_prefetch_opportunity)

func _on_combat_started_reset_first_draft(_event_id: String) -> void:
	_combat_first_draft_forgiveness_used = false


func _on_run_ended_vocab_example_prefetch() -> void:
	_example_prefetch_timer_pending = false
	_flush_profile_if_dirty()
	_example_prefetch_requested_this_run = 0


func _on_vocab_example_prefetch_opportunity(_arg = null) -> void:
	_flush_profile_if_dirty()
	_begin_background_example_prefetch()


func _on_reward_vocab_example_prefetch_opportunity(
	_reward_group: int,
	_money_amount: int,
	_card_drafts: Array[Array],
	_artifact_ids: Array[String],
	_custom_action_data: Array[Array]
) -> void:
	_begin_background_example_prefetch()


func _player_has_first_draft_artifact() -> bool:
	if not Global.is_run:
		return false
	return not Global.player_data.get_player_artifacts_with_artifact_id(ARTIFACT_ARCHIVIST_FIRST_DRAFT_ID).is_empty()

func _try_first_draft_forgive_wrong_answer() -> bool:
	if _combat_first_draft_forgiveness_used:
		return false
	if not _player_has_first_draft_artifact():
		return false
	_combat_first_draft_forgiveness_used = true
	return true

func register_word_overlay(overlay: WordReviewOverlay) -> void:
	_overlay = overlay

func reload_from_settings() -> void:
	_migrate_vocab_settings_arrays()
	_invalidate_example_cache()
	_rebuild_book_index()
	_load_word_list()
	_ensure_daily_new_plan()


func _migrate_vocab_settings_arrays() -> void:
	var migrated := false
	var learn_raw: Variant = Global.user_settings_data.settings_vocab_learn_steps_enabled
	if typeof(learn_raw) != TYPE_ARRAY or (learn_raw as Array).is_empty():
		Global.user_settings_data.settings_vocab_learn_steps_enabled = ["en2zh", "zh2en", "spell", "dictation"]
		migrated = true
	var rev_raw: Variant = Global.user_settings_data.settings_vocab_review_modes_enabled
	if typeof(rev_raw) != TYPE_ARRAY or (rev_raw as Array).is_empty():
		Global.user_settings_data.settings_vocab_review_modes_enabled = _review_modes_from_legacy_string(
			str(Global.user_settings_data.settings_vocab_combat_review_mode)
		)
		migrated = true
	if migrated:
		FileLoader.save_user_settings()


func _review_modes_from_legacy_string(legacy: String) -> Array[String]:
	var s := legacy.strip_edges()
	if s == VOCAB_REVIEW_MODE_SPELL or s == VOCAB_REVIEW_MODE_MEANING or s == VOCAB_REVIEW_MODE_MC4 or s == VOCAB_REVIEW_MODE_RECALL:
		return [s]
	return [VOCAB_REVIEW_MODE_SPELL, VOCAB_REVIEW_MODE_MEANING, VOCAB_REVIEW_MODE_MC4, VOCAB_REVIEW_MODE_RECALL]


## 按固定顺序返回本次学习流水线要跑的环节 id（至少一项）。
func learn_pipeline_enabled_step_ids_ordered() -> Array[String]:
	var raw: Variant = Global.user_settings_data.settings_vocab_learn_steps_enabled
	var picked: Dictionary = {}
	if typeof(raw) == TYPE_ARRAY:
		for item: Variant in raw as Array:
			var id: String = str(item).strip_edges()
			if id != "":
				picked[id] = true
	var out: Array[String] = []
	for id2: String in VOCAB_LEARN_STEP_ORDER:
		if picked.has(id2):
			out.append(id2)
	if out.is_empty():
		return VOCAB_LEARN_STEP_ORDER.duplicate()
	return out


func _normalized_review_modes_enabled() -> Array[String]:
	var raw: Variant = Global.user_settings_data.settings_vocab_review_modes_enabled
	var out: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for item: Variant in raw as Array:
			var m: String = str(item).strip_edges()
			if (
				m == VOCAB_REVIEW_MODE_SPELL
				or m == VOCAB_REVIEW_MODE_MEANING
				or m == VOCAB_REVIEW_MODE_MC4
				or m == VOCAB_REVIEW_MODE_RECALL
			):
				if not out.has(m):
					out.append(m)
	if out.is_empty():
		return _review_modes_from_legacy_string(str(Global.user_settings_data.settings_vocab_combat_review_mode))
	return out


func _invalidate_example_cache() -> void:
	_example_cache_loaded = false
	_example_cache_entries.clear()


func _ensure_example_cache_loaded() -> void:
	if _example_cache_loaded:
		return
	_example_cache_loaded = true
	_example_cache_entries.clear()
	if not FileAccess.file_exists(VOCAB_EXAMPLE_CACHE_PATH):
		return
	var text := FileAccess.get_file_as_string(VOCAB_EXAMPLE_CACHE_PATH)
	var v: Variant = JSON.parse_string(text)
	if typeof(v) != TYPE_DICTIONARY:
		return
	var root: Dictionary = v as Dictionary
	var cache_domain_prefs := str(root.get("domain_prefs", "")).strip_edges()
	var current_domain_prefs := _vocab_domain_prefs_signature()
	if cache_domain_prefs != current_domain_prefs:
		return
	var ent: Variant = root.get("entries", null)
	if typeof(ent) == TYPE_DICTIONARY:
		_example_cache_entries = (ent as Dictionary).duplicate(true)


func _vocab_domain_prefs_signature() -> String:
	var pieces := _collect_openai_domain_pieces()
	return "|".join(pieces)


func notify_example_preferences_changed() -> void:
	_vocab_example_zh_gave_up_ids.clear()
	_invalidate_example_cache()
	Global.profile_data.profile_vocab_seq_example_last_day = 0
	FileLoader.save_profile()
	reload_from_settings()


func _apply_vocab_example_file_cache(w: Dictionary) -> void:
	_ensure_example_cache_loaded()
	var wid := str(w.get("id", ""))
	if wid.is_empty() or not _example_cache_entries.has(wid):
		return
	var coerced: Array = _coerce_api_examples(_example_cache_entries[wid])
	if coerced.is_empty():
		return
	w["study_examples"] = coerced


func _persist_examples_to_example_cache_file(wid: String, examples: Array) -> void:
	if wid.is_empty():
		return
	_ensure_example_cache_loaded()
	_example_cache_entries[wid] = examples.duplicate(true)
	var root := {
		"version": 1,
		"entries": _example_cache_entries.duplicate(true),
		"domain_prefs": _vocab_domain_prefs_signature(),
	}
	var f := FileAccess.open(VOCAB_EXAMPLE_CACHE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("VocabStudy: could not write example cache: ", FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(root, "\t"))
	f.close()


func _try_merge_examples_from_file_cache_into_word(word: Dictionary, wid: String) -> bool:
	_ensure_example_cache_loaded()
	if wid.is_empty() or not _example_cache_entries.has(wid):
		return false
	var coerced: Array = _coerce_api_examples(_example_cache_entries[wid])
	if coerced.is_empty():
		return false
	word["study_examples"] = coerced.duplicate(true)
	_patch_word_examples_in_pool(wid, coerced)
	return true


func _reset_per_turn_state() -> void:
	_per_turn_current_word_id = ""
	_per_turn_current_step_index = 0

func _on_run_started_vocab_example_batch() -> void:
	_vocab_example_zh_gave_up_ids.clear()
	_example_prefetch_requested_this_run = 0
	_reset_per_turn_state()
	_begin_background_example_prefetch("", BACKGROUND_EXAMPLE_PREFETCH_START_DELAY_SECONDS)
	if _sequential_batch_busy:
		return
	get_tree().create_timer(0.25).timeout.connect(_on_sequential_example_batch_timer, CONNECT_ONE_SHOT)


func _on_sequential_example_batch_timer() -> void:
	await _run_daily_sequential_example_batch_async()
	_begin_background_example_prefetch("", BACKGROUND_EXAMPLE_PREFETCH_DELAY_SECONDS)


func _run_daily_sequential_example_batch_async() -> void:
	var n: int = Global.user_settings_data.settings_vocab_daily_ordered_example_words
	if n <= 0 or _words.is_empty():
		return
	if not has_openai_configured():
		return
	var day: int = _vocab_calendar_day_id()
	if int(Global.profile_data.profile_vocab_seq_example_last_day) == day:
		return
	_sequential_batch_busy = true
	_ensure_example_cache_loaded()
	var start: int = int(Global.profile_data.profile_vocab_seq_example_cursor)
	if _words.size() > 0:
		start = posmod(start, _words.size())
	var total: int = mini(n, _words.size())

	var words_to_process: Array[Dictionary] = []
	for k in range(total):
		var idx: int = posmod(start + k, _words.size())
		var w: Dictionary = _words[idx]
		if _word_dict_has_nonempty_examples(w) and not _word_study_examples_need_zh_refresh(w):
			continue
		var wid: String = str(w.get("id", ""))
		if wid.is_empty():
			continue
		if _example_fetch_in_progress.get(wid, false):
			continue
		words_to_process.append(w)

	var api_done: int = 0
	var process_total: int = words_to_process.size()

	for i in range(0, words_to_process.size(), EXAMPLE_API_BATCH_SIZE):
		var batch: Array[Dictionary] = words_to_process.slice(i, i + EXAMPLE_API_BATCH_SIZE)
		for w in batch:
			_example_fetch_in_progress[str(w.get("id", ""))] = true

		var system := _build_openai_system_prompt(true)
		var user_pl := _build_openai_user_payload_batch(batch)
		var resp := await _http_openai_chat_completion(_example_http_batch, system, user_pl)

		if not bool(resp.get("ok", false)):
			push_warning("VocabStudy daily batch: batch API error %s" % str(resp.get("err", "?")))
			for w in batch:
				_example_fetch_in_progress.erase(str(w.get("id", "")))
			continue

		var batch_results: Dictionary = _parse_batch_examples_content(str(resp.get("content", "")))
		if batch_results.is_empty():
			var clip := str(resp.get("content", "")).strip_edges()
			clip = clip.substr(0, mini(280, clip.length()))
			push_warning("VocabStudy daily batch: 批量解析失败,跳过本批 %d 条。片段: %s" % [batch.size(), clip])
			for w in batch:
				_example_fetch_in_progress.erase(str(w.get("id", "")))
			continue

		for w in batch:
			var wid: String = str(w.get("id", ""))
			var examples: Array = batch_results.get(wid, []) as Array
			if examples.is_empty():
				push_warning("VocabStudy daily batch: 本批返回中缺少 id=%s 的例句,跳过。" % wid)
				_example_fetch_in_progress.erase(wid)
				continue

			w["study_examples"] = examples.duplicate(true)
			if not _word_study_examples_need_zh_refresh(w):
				_vocab_example_zh_gave_up_ids.erase(wid)
			else:
				push_warning(
					"VocabStudy daily batch: 例句仍缺 sentence_zh（本条本局不再自动重拉），id=%s" % wid
				)
				_vocab_example_zh_gave_up_ids[wid] = true

			_persist_examples_to_example_cache_file(wid, examples)
			_patch_word_examples_in_pool(wid, examples)
			_example_fetch_in_progress.erase(wid)
			api_done += 1
			Signals.vocab_example_api_progress.emit(api_done, process_total, wid)

	Global.profile_data.profile_vocab_seq_example_cursor = posmod(start + n, _words.size())
	Global.profile_data.profile_vocab_seq_example_last_day = day
	FileLoader.save_profile()
	_sequential_batch_busy = false
	Signals.vocab_example_api_progress.emit(process_total, process_total, "done")

## 供设置界面或调试：替换启用词书列表并持久化、重建词池。
func set_enabled_vocab_books(book_ids: Array[String]) -> void:
	Global.user_settings_data.settings_vocab_enabled_book_ids = book_ids.duplicate()
	FileLoader.save_user_settings()
	reload_from_settings()

func _ensure_user_vocab_dir() -> void:
	var abs_dir: String = ProjectSettings.globalize_path(USER_BOOKS_DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		return
	var err: Error = DirAccess.make_dir_recursive_absolute(abs_dir)
	if err != OK:
		push_warning("VocabStudy: could not mkdir user vocab dir: ", abs_dir, " err=", err)

func _rebuild_book_index() -> void:
	_book_id_to_path.clear()
	_book_id_to_path[BUILTIN_DEFAULT_ID] = LEGACY_VOCAB_PATH
	_scan_book_dir(PACKAGED_BOOKS_DIR)
	_scan_book_dir(JSON_BOOKS_DIR)
	_ensure_user_vocab_dir()
	_scan_book_dir(USER_BOOKS_DIR)

func _scan_book_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json") and not fname.begins_with("_"):
			var full: String = dir_path.path_join(fname)
			var bid: String = _read_book_id_from_file(full)
			if bid == "":
				bid = _derive_book_id_from_filename(fname)
			if bid != "" and bid != BUILTIN_DEFAULT_ID:
				if _book_id_to_path.has(bid):
					push_warning("VocabStudy: duplicate book_id ", bid, " — using ", full)
				_book_id_to_path[bid] = full
		fname = dir.get_next()
	dir.list_dir_end()

func _derive_book_id_from_filename(fname: String) -> String:
	var base := fname.get_basename()
	var dash := base.find("-")
	if dash != -1:
		var prefix := base.substr(0, dash)
		if prefix.is_valid_int():
			return base.substr(dash + 1)
	return base


func _derive_book_name_from_filename(fname: String) -> String:
	return _derive_book_id_from_filename(fname)


func _read_book_id_from_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	return str((data as Dictionary).get("book_id", "")).strip_edges()

## 将整份 JSON 文本写入 user:// 并登记词书；成功返回 book_id，失败返回空字符串。
func import_book_from_json_text(json_text: String, overwrite: bool = true) -> String:
	_ensure_user_vocab_dir()
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("VocabStudy import: JSON 根不是对象")
		return ""
	var parsed: Dictionary = _parse_book_entries(data as Dictionary)
	var book_id: String = str(parsed.get("book_id", "")).strip_edges()
	if book_id == "" or book_id == BUILTIN_DEFAULT_ID:
		push_error("VocabStudy import: 缺少合法 book_id")
		return ""
	var entries: Array = parsed.get("entries", []) as Array
	if entries.is_empty():
		push_error("VocabStudy import: words 为空或无效")
		return ""
	var out_path: String = USER_BOOKS_DIR.path_join("book_%s.json" % book_id)
	if FileAccess.file_exists(out_path) and not overwrite:
		push_error("VocabStudy import: 文件已存在 ", out_path)
		return ""
	var save_err: Error = _write_user_book_file(out_path, data as Dictionary)
	if save_err != OK:
		push_error("VocabStudy import: 写入失败 ", save_err)
		return ""
	reload_from_settings()
	_append_enabled_book_if_missing(book_id)
	FileLoader.save_user_settings()
	return book_id

func _write_user_book_file(path: String, root: Dictionary) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(root, "\t"))
	f.close()
	return OK

func _append_enabled_book_if_missing(book_id: String) -> void:
	var arr: Array[String] = Global.user_settings_data.settings_vocab_enabled_book_ids
	if not arr.has(book_id):
		arr.append(book_id)
		Global.user_settings_data.settings_vocab_enabled_book_ids = arr

## 桌面等环境：从本机绝对路径读取 UTF-8 JSON 并导入到 user://（与 import_book_from_json_text 相同校验）。
func import_book_from_user_absolute_path(abs_path: String, overwrite: bool = true) -> String:
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if f == null:
		push_error("VocabStudy import: 无法打开 ", abs_path)
		return ""
	var text := f.get_as_text()
	f.close()
	return import_book_from_json_text(text, overwrite)

func delete_user_book(book_id: String) -> bool:
	if book_id == BUILTIN_DEFAULT_ID:
		return false
	var path: String = str(_book_id_to_path.get(book_id, ""))
	if path.is_empty() or not path.begins_with(USER_BOOKS_DIR):
		return false
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if err != OK:
			push_warning("VocabStudy: failed to delete book file: ", path, " err=", err)
			return false
	var enabled: Array[String] = Global.user_settings_data.settings_vocab_enabled_book_ids.duplicate()
	if enabled.has(book_id):
		enabled.erase(book_id)
		if enabled.is_empty():
			enabled.append(BUILTIN_DEFAULT_ID)
		Global.user_settings_data.settings_vocab_enabled_book_ids = enabled
		FileLoader.save_user_settings()
	reload_from_settings()
	return true

func list_known_books() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({
		"book_id": BUILTIN_DEFAULT_ID,
		"path": LEGACY_VOCAB_PATH,
		"source": "builtin",
	})
	for bid: String in _book_id_to_path.keys():
		if bid == BUILTIN_DEFAULT_ID:
			continue
		var p: String = _book_id_to_path[bid]
		var meta: Dictionary = {"book_id": bid, "path": p, "source": "user" if p.begins_with("user://") else "packaged"}
		var title: String = _read_book_name(_book_id_to_path[bid])
		if title != "":
			meta["book_name"] = title
		out.append(meta)
	return out


func get_vocab_dashboard_stats() -> Dictionary:
	var now: int = int(Time.get_unix_time_from_system())
	var due_ids: Array[String] = []
	var new_count: int = 0
	var introduced_count: int = 0
	var learned_count: int = 0
	var example_ready_count: int = 0
	var book_counts: Dictionary = {}
	for w: Dictionary in _words:
		var wid: String = str(w.get("id", ""))
		var bid := _book_id_from_word_id(wid)
		book_counts[bid] = int(book_counts.get(bid, 0)) + 1
		var st: Dictionary = _get_state(wid)
		var introduced := bool(st.get("introduced", false))
		if introduced:
			introduced_count += 1
		else:
			new_count += 1
		if bool(st.get("learned", false)):
			learned_count += 1
		if introduced and int(st.get("d", 0)) <= now:
			due_ids.append(wid)
		if _word_dict_has_nonempty_examples(w):
			example_ready_count += 1
	var enabled := _enabled_book_ids()
	return {
		"total_words": _words.size(),
		"enabled_book_count": enabled.size(),
		"known_book_count": list_known_books().size(),
		"new_words": new_count,
		"introduced_words": introduced_count,
		"learned_words": learned_count,
		"due_review_words": due_ids.size(),
		"due_review_available_today": _slice_due_ids_for_daily_budget(due_ids).size(),
		"example_ready_words": example_ready_count,
		"example_missing_words": maxi(0, _words.size() - example_ready_count),
		"book_counts": book_counts,
		"has_openai": has_openai_configured(),
		"domain_summary": example_domain_summary(),
		"daily_example_batch_size": int(Global.user_settings_data.settings_vocab_daily_ordered_example_words),
		"daily_example_batch_done_today": int(Global.profile_data.profile_vocab_seq_example_last_day) == _vocab_calendar_day_id(),
		"daily_example_cursor": int(Global.profile_data.profile_vocab_seq_example_cursor),
		"daily_new_words_setting": int(Global.user_settings_data.settings_vocab_daily_new_words),
		"daily_new_pending": _count_daily_new_pending(),
	}


func _ensure_daily_new_plan() -> void:
	var day: int = _vocab_calendar_day_id()
	var lim: int = int(Global.user_settings_data.settings_vocab_daily_new_words)
	if lim <= 0:
		if int(Global.profile_data.profile_vocab_daily_new_plan_day) != day:
			Global.profile_data.profile_vocab_daily_new_plan_day = day
			Global.profile_data.profile_vocab_daily_new_word_ids.clear()
			FileLoader.save_profile()
		return
	if int(Global.profile_data.profile_vocab_daily_new_plan_day) == day:
		return
	Global.profile_data.profile_vocab_daily_new_plan_day = day
	Global.profile_data.profile_vocab_daily_new_word_ids.clear()
	var picked: Array = []
	for w: Dictionary in _words:
		if picked.size() >= lim:
			break
		var wid: String = str(w.get("id", ""))
		if wid.is_empty():
			continue
		var st: Dictionary = _get_state(wid)
		if bool(st.get("learned", false)):
			continue
		picked.append(wid)
	Global.profile_data.profile_vocab_daily_new_word_ids = picked
	FileLoader.save_profile()


func _pending_daily_new_word_id() -> String:
	var lim: int = int(Global.user_settings_data.settings_vocab_daily_new_words)
	if lim <= 0:
		return ""
	_ensure_daily_new_plan()
	for item: Variant in Global.profile_data.profile_vocab_daily_new_word_ids:
		var wid: String = str(item)
		if wid.is_empty():
			continue
		var st: Dictionary = _get_state(wid)
		if not bool(st.get("learned", false)):
			return wid
	return ""


func _count_daily_new_pending() -> int:
	var lim: int = int(Global.user_settings_data.settings_vocab_daily_new_words)
	if lim <= 0:
		return 0
	_ensure_daily_new_plan()
	var n: int = 0
	for item: Variant in Global.profile_data.profile_vocab_daily_new_word_ids:
		var wid: String = str(item)
		if wid.is_empty():
			continue
		var st: Dictionary = _get_state(wid)
		if not bool(st.get("learned", false)):
			n += 1
	return n


func is_word_marked_learned(word_id: String) -> bool:
	var st: Dictionary = _get_state(word_id)
	return bool(st.get("learned", false))


func _book_id_from_word_id(wid: String) -> String:
	var colon := wid.find(":")
	if colon == -1:
		return BUILTIN_DEFAULT_ID
	return wid.substr(0, colon)

func _read_book_name(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	# 先读第一行判断格式,避免把 json 目录下几 MB 的数组文件全读进内存
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var first_line := str(f.get_line()).strip_edges()
	f.close()
	if first_line.begins_with("["):
		if path.begins_with(JSON_BOOKS_DIR):
			return _derive_book_name_from_filename(path.get_file())
		return ""
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	return str((data as Dictionary).get("book_name", ""))

func _enabled_book_ids() -> Array[String]:
	var arr: Array[String] = Global.user_settings_data.settings_vocab_enabled_book_ids.duplicate()
	if arr.is_empty():
		arr.append(BUILTIN_DEFAULT_ID)
	return arr

# ── Export / Stats / Merge / Split ───────────────

## Export a book's JSON content.  Returns the JSON string (also copies to
## clipboard on all platforms).  Returns "" if the book is not found.

## Call the OpenAI API (or on-device model) to generate a complete vocab
## book JSON matching the user's topic description.  The result is
## automatically imported and enabled.
## Returns {"ok": true, "book_id": "..."} on success,
##         {"ok": false, "err": "..."} on failure.
func generate_book_via_ai(topic: String, word_count: int = 20) -> Dictionary:
	if topic.strip_edges().is_empty():
		return {"ok": false, "err": "empty topic"}
	if not has_openai_configured():
		return {"ok": false, "err": "no api key"}
	var user_payload := JSON.stringify({
		"topic": topic,
		"count": word_count,
		"language": I18N.current_locale
	})
	var result: Dictionary = await _http_openai_chat_completion(
		_example_http_ondemand,
		OPENAI_GENERATE_BOOK_SYSTEM,
		user_payload
	)
	if not result.get("ok", false):
		return {"ok": false, "err": str(result.get("err", "api error"))}
	var content: String = str(result.get("content", ""))
	if content.is_empty():
		return {"ok": false, "err": "empty response"}
	# Clean any stray markdown fences
	content = _strip_json_fence_gd(content)
	var json_text: String = content.strip_edges()
	var book_id: String = import_book_from_json_text(json_text, true)
	if book_id.is_empty():
		return {"ok": false, "err": "import failed – check JSON shape"}
	return {"ok": true, "book_id": book_id}

func export_book_json(book_id: String) -> String:
	var entries: Array[Dictionary] = _load_words_for_book(book_id)
	if entries.is_empty() and book_id != BUILTIN_DEFAULT_ID:
		return ""
	# Build the book JSON
	var book_name: String = ""
	var path: String = str(_book_id_to_path.get(book_id, ""))
	if not path.is_empty():
		book_name = _read_book_name(path)
	var root: Dictionary = {"book_id": book_id, "words": entries}
	if not book_name.is_empty():
		root["book_name"] = book_name
	var json_text: String = JSON.stringify(root, "\t")
	# Try to write to user-accessible downloads folder (best-effort)
	var down_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS, true)
	if not down_dir.is_empty():
		var dir_access := DirAccess.open(down_dir)
		if dir_access != null:
			var fname: String = "book_" + book_id + ".json"
			var fa := FileAccess.open(down_dir.path_join(fname), FileAccess.WRITE)
			if fa != null:
				fa.store_string(json_text)
				fa.close()
	# Always copy to clipboard as primary share method (works on mobile)
	DisplayServer.clipboard_set(json_text)
	return json_text


## Compute study statistics for one book.  Returns a Dictionary with keys:
## total, new_count, learning_count, mastered_count, due_count, avg_interval_h.
func get_book_stats(book_id: String) -> Dictionary:
	var entries: Array[Dictionary] = _load_words_for_book(book_id)
	var stats := {
		"total": entries.size(),
		"new_count": 0,
		"learning_count": 0,
		"mastered_count": 0,
		"due_count": 0,
		"avg_interval_h": 0.0,
	}
	if entries.is_empty():
		return stats
	var now: int = int(Time.get_unix_time_from_system())
	var interval_sum: float = 0.0
	var stated_count: int = 0
	for w: Dictionary in entries:
		var wid: String = str(w.get("id", ""))
		if wid == "":
			continue
		var st: Dictionary = _get_state(wid)
		var r: int = int(st.get("r", 0))
		var i: float = float(st.get("i", 0.0))
		var d: int = int(st.get("d", 0))
		var learned: bool = bool(st.get("learned", false))
		if r == 0 and i == 0.0 and not learned:
			stats["new_count"] += 1
		elif learned or i >= 720.0:
			stats["mastered_count"] += 1
		else:
			stats["learning_count"] += 1
		if d > 0 and d <= now:
			stats["due_count"] += 1
		if r > 0 and i > 0.0:
			interval_sum += i
			stated_count += 1
	if stated_count > 0:
		stats["avg_interval_h"] = interval_sum / float(stated_count)
	return stats


## Merge multiple books into one new user book.
## Returns the new book_id on success, empty string on failure.
func merge_books(book_ids: Array[String], new_book_id: String, new_book_name: String) -> String:
	if book_ids.size() < 2:
		return ""
	if new_book_id.is_empty() or new_book_id == BUILTIN_DEFAULT_ID:
		return ""
	# Collect all words from source books (later books override earlier by id)
	var merged_words: Array[Dictionary] = []
	var seen: Dictionary = {}
	for bid: String in book_ids:
		var entries: Array[Dictionary] = _load_words_for_book(bid)
		for w: Dictionary in entries:
			_enrich_study_fields(w)
			_apply_vocab_example_file_cache(w)
			_apply_vocab_example_override(w)
			var wid: String = str(w.get("id", ""))
			if wid == "":
				continue
			if seen.has(wid):
				var idx: int = seen[wid]
				merged_words[idx] = w
			else:
				seen[wid] = merged_words.size()
				merged_words.append(w)
	# Build and write the new book
	var root := {"book_id": new_book_id, "book_name": new_book_name, "words": merged_words}
	var json_text: String = JSON.stringify(root, "\t")
	var dest_path: String = USER_BOOKS_DIR.path_join("book_" + new_book_id + ".json")
	var fa := FileAccess.open(dest_path, FileAccess.WRITE)
	if fa == null:
		return ""
	fa.store_string(json_text)
	fa.close()
	# Reload and auto-enable
	reload_from_settings()
	_append_enabled_book_if_missing(new_book_id)
	FileLoader.save_user_settings()
	return new_book_id


## Split a book into two new user books.
## Returns an Array of two new book_ids (may be empty strings on failure).
func split_book(book_id: String, split_method: String) -> Array[String]:
	var entries: Array[Dictionary] = _load_words_for_book(book_id)
	if entries.size() < 2:
		return ["", ""]
	var original_name: String = ""
	var path: String = str(_book_id_to_path.get(book_id, ""))
	if not path.is_empty():
		original_name = _read_book_name(path)
	if original_name.is_empty():
		original_name = book_id

	var part_a: Array[Dictionary] = []
	var part_b: Array[Dictionary] = []

	match split_method:
		"halves":
			var mid: int = entries.size() / 2
			for i: int in entries.size():
				if i < mid:
					part_a.append(entries[i])
				else:
					part_b.append(entries[i])
		"alpha":
			for w: Dictionary in entries:
				var prompt: String = str(w.get("prompt", "")).to_lower().strip_edges()
				if prompt.is_empty():
					part_b.append(w)
				elif prompt[0] >= "a" and prompt[0] <= "m":
					part_a.append(w)
				else:
					part_b.append(w)
		_:
			return ["", ""]

	if part_a.is_empty() or part_b.is_empty():
		return ["", ""]

	# Write part A
	var id_a: String = book_id + "_a"
	var name_a: String = original_name + " (A)"
	var root_a := {"book_id": id_a, "book_name": name_a, "words": part_a}
	var dest_a: String = USER_BOOKS_DIR.path_join("book_" + id_a + ".json")
	var fa := FileAccess.open(dest_a, FileAccess.WRITE)
	if fa == null:
		return ["", ""]
	fa.store_string(JSON.stringify(root_a, "\t"))
	fa.close()

	# Write part B
	var id_b: String = book_id + "_b"
	var name_b: String = original_name + " (B)"
	var root_b := {"book_id": id_b, "book_name": name_b, "words": part_b}
	var dest_b: String = USER_BOOKS_DIR.path_join("book_" + id_b + ".json")
	fa = FileAccess.open(dest_b, FileAccess.WRITE)
	if fa == null:
		return [id_a, ""]
	fa.store_string(JSON.stringify(root_b, "\t"))
	fa.close()

	# Reload and auto-enable the new books
	reload_from_settings()
	_append_enabled_book_if_missing(id_a)
	_append_enabled_book_if_missing(id_b)
	FileLoader.save_user_settings()
	return [id_a, id_b]

func _load_word_list() -> void:
	_words.clear()
	var seen_ids: Dictionary[String, bool] = {}
	var duplicate_count: int = 0
	var duplicate_samples: PackedStringArray = []
	var enabled: Array[String] = _enabled_book_ids()
	for book_id: String in enabled:
		var entries: Array[Dictionary] = _load_words_for_book(book_id)
		for w: Dictionary in entries:
			var wid: String = str(w.get("id", ""))
			if wid == "":
				continue
			if seen_ids.has(wid):
				duplicate_count += 1
				if duplicate_samples.size() < 5:
					duplicate_samples.append(wid)
				continue
			seen_ids[wid] = true
			_enrich_study_fields(w)
			_apply_vocab_example_file_cache(w)
			_apply_vocab_example_override(w)
			_words.append(w)
	if not _words.is_empty():
		var cc: int = int(Global.profile_data.profile_vocab_seq_example_cursor)
		Global.profile_data.profile_vocab_seq_example_cursor = posmod(cc, _words.size())
	if duplicate_count > 0:
		push_warning(
			"VocabStudy: skipped %d duplicate word ids after loading books. Samples: %s"
			% [duplicate_count, ", ".join(duplicate_samples)]
	)
	# Build O(1) lookup index
	_id_to_word.clear()
	for w: Dictionary in _words:
		var wid: String = str(w.get("id", ""))
		if wid != "":
			_id_to_word[wid] = w

func _load_words_for_book(book_id: String) -> Array[Dictionary]:
	if book_id == BUILTIN_DEFAULT_ID:
		return _load_legacy_vocab_file(LEGACY_VOCAB_PATH, BUILTIN_DEFAULT_ID)
	var path: String = str(_book_id_to_path.get(book_id, ""))
	if path == "" or not FileAccess.file_exists(path):
		push_warning("VocabStudy: unknown or missing book: ", book_id)
		return []
	if path.begins_with(JSON_BOOKS_DIR):
		return _load_json_folder_book(path, book_id)
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return []
	var root: Dictionary = data as Dictionary
	var file_book_id: String = str(root.get("book_id", "")).strip_edges()
	if file_book_id != book_id:
		push_warning("VocabStudy: 文件内 book_id 与启用 id 不一致: ", file_book_id, " != ", book_id)
		return []
	return _entries_array_from_parse(_parse_book_entries(root))

# Normalize raw type strings from json/ vocab files into standard POS abbreviations.
# Handles inconsistent separators (&, /, space variants), Chinese garbage,
# full-word types (conjunction, interjection), and subcategory codes (vi, vt).
# Results are added to the pos_set Dictionary (keys become the set of normalized types).
func _normalize_pos_type_into(raw: String, pos_set: Dictionary) -> void:
	if raw.is_empty():
		return
	# Strip and lowercase; reject entries with CJK characters or garbage markers
	var cleaned := raw.strip_edges().to_lower()
	for ch: String in cleaned:
		var u := ch.unicode_at(0)
		if u >= 0x4E00 and u <= 0x9FFF:
			return
		if u >= 0x3000 and u <= 0x303F:
			return
		if u >= 0xFF00:
			return
	# Split compound types: "n & v", "n&v", "n / v", etc.
	var parts: PackedStringArray = cleaned.split("&", false)
	var all_parts: Array[String] = []
	for part: String in parts:
		for sub: String in part.split("/", false):
			var s := sub.strip_edges()
			if s != "":
				all_parts.append(s)
	for raw_part: String in all_parts:
		var norm := _map_pos_abbrev(raw_part)
		if norm != "" and not pos_set.has(norm):
			pos_set[norm] = true

# Map a single type token to its standard abbreviation.
# Returns empty string for unrecognized/garbage tokens.
func _map_pos_abbrev(token: String) -> String:
	token = token.strip_edges()
	match token:
		"a", "adj":
			return "adj"
		"ad", "adv":
			return "adv"
		"n":
			return "n"
		"v", "vi", "vt":
			return "v"
		"prep":
			return "prep"
		"conj", "conjunction":
			return "conj"
		"pron":
			return "pron"
		"int", "interjection":
			return "int"
		"art", "article", "indefinite article":
			return "art"
		"aux", "modal verb":
			return "aux"
		"num":
			return "num"
		"abbr":
			return "abbr"
		"determiner":
			return "det"
		"neg":
			return ""
	return ""

func _load_json_folder_book(path: String, book_id: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		return []
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_ARRAY:
		return []
	var out: Array[Dictionary] = []
	var by_id: Dictionary = {}
	for item: Variant in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item
		var word: String = str(d.get("word", "")).strip_edges()
		if word.is_empty():
			continue
		var translations: Array = []
		var trans_raw: Variant = d.get("translations", [])
		if typeof(trans_raw) == TYPE_ARRAY:
			translations = trans_raw as Array
		var meanings: Array[String] = []
		var pos_set: Dictionary = {}
		var phonetic: String = str(d.get("phonetic", "")).strip_edges()
		for t: Variant in translations:
			if typeof(t) == TYPE_DICTIONARY:
				var td: Dictionary = t
				var tr: String = str(td.get("translation", "")).strip_edges()
				if not tr.is_empty():
					meanings.append(tr)
				var tp_raw: String = str(td.get("type", "")).strip_edges()
				_normalize_pos_type_into(tp_raw, pos_set)
				var ph: String = str(td.get("phonetic", "")).strip_edges()
				if ph != "" and phonetic.is_empty():
					phonetic = ph
		var meaning_str := "；".join(meanings) if not meanings.is_empty() else ""
		var pos_str := ".".join(pos_set.keys()) if not pos_set.is_empty() else ""
		if pos_str != "":
			pos_str += "."
		var full_id: String = "%s:%s" % [book_id, word]
		if by_id.has(full_id):
			var existing: Dictionary = by_id[full_id]
			var existing_meaning := str(existing.get("study_meaning", ""))
			for mn: String in meanings:
				if mn.is_empty():
					continue
				if existing_meaning.is_empty():
					existing_meaning = mn
				elif not existing_meaning.split("；").has(mn):
					existing_meaning += "；" + mn
			existing["study_meaning"] = existing_meaning
			var existing_pos: String = str(existing.get("study_pos", ""))
			if pos_str != "" and existing_pos.is_empty():
				existing["study_pos"] = pos_str
			var existing_ph: String = str(existing.get("study_phonetic", ""))
			if phonetic != "" and existing_ph.is_empty():
				existing["study_phonetic"] = phonetic
			existing["prompt"] = "释义：%s\n请写出对应英文单词" % existing_meaning
			continue
		var prompt := "释义：%s\n请写出对应英文单词" % meaning_str
		var entry: Dictionary = {
			"id": full_id,
			"prompt": prompt,
			"answers": [word.to_lower()],
			"study_headword": word,
			"study_meaning": meaning_str,
			"study_phonetic": phonetic,
			"study_pos": pos_str,
		}
		by_id[full_id] = entry
		out.append(entry)
	return out

func _load_legacy_vocab_file(path: String, book_id: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		return []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return []
	var root: Dictionary = data as Dictionary
	if str(root.get("book_id", "")).strip_edges() != "":
		return _entries_array_from_parse(_parse_book_entries(root))
	return _parse_legacy_words_array(root.get("words", []), book_id)

func _parse_legacy_words_array(arr: Variant, book_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(arr) != TYPE_ARRAY:
		return out
	for item: Variant in arr:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item
		var wid: String = str(d.get("id", ""))
		if wid == "":
			continue
		var full_id: String = wid if book_id == BUILTIN_DEFAULT_ID else "%s:%s" % [book_id, wid]
		var answers: Array[String] = _parse_answers(d)
		if answers.is_empty():
			continue
		var entry: Dictionary = {
			"id": full_id,
			"prompt": str(d.get("prompt", full_id)),
			"answers": answers,
		}
		if d.has("study_headword"):
			entry["study_headword"] = str(d["study_headword"])
		if d.has("study_meaning"):
			entry["study_meaning"] = str(d["study_meaning"])
		if d.has("study_phonetic"):
			entry["study_phonetic"] = str(d["study_phonetic"])
		if d.has("study_pos"):
			entry["study_pos"] = str(d["study_pos"])
		_attach_study_examples(entry, d)
		out.append(entry)
	return out

## 词书可选字段 study_examples：多条例句，学习页展示不同用法。
## 支持 ["句子1", "句子2"] 或 [{"sentence":"…","gloss":"义：…"}, …]；单条也可用 study_example 字符串。
func _attach_study_examples(entry: Dictionary, d: Dictionary) -> void:
	var raw: Variant = d.get("study_examples", null)
	if raw == null and d.has("study_example"):
		raw = [d["study_example"]]
	if raw == null:
		return
	var norm: Array = _normalize_study_examples(raw)
	if not norm.is_empty():
		entry["study_examples"] = norm

func _normalize_study_examples(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item: Variant in raw:
		if typeof(item) == TYPE_STRING:
			var s: String = str(item).strip_edges()
			if s != "":
				out.append({"sentence": s, "gloss": ""})
		elif typeof(item) == TYPE_DICTIONARY:
			var d2: Dictionary = item as Dictionary
			var sent: String = str(d2.get("sentence", d2.get("en", d2.get("text", "")))).strip_edges()
			if sent == "":
				continue
			var gloss: String = str(d2.get("gloss", d2.get("meaning", d2.get("sense", "")))).strip_edges()
			out.append({"sentence": sent, "gloss": gloss})
	return out

func _enrich_study_fields(w: Dictionary) -> void:
	var hw: String = str(w.get("study_headword", "")).strip_edges()
	var mn: String = str(w.get("study_meaning", "")).strip_edges()
	if hw != "" and mn != "":
		if not w.has("study_phonetic"):
			w["study_phonetic"] = ""
		if not w.has("study_pos"):
			w["study_pos"] = ""
		return
	var answers: Array = w.get("answers", [])
	if hw == "" and answers.size() > 0:
		hw = str(answers[0])
	if mn == "":
		mn = _extract_meaning_from_prompt(str(w.get("prompt", "")))
	if hw == "":
		hw = "?"
	if mn == "":
		mn = "（请看题干）"
	w["study_headword"] = hw
	w["study_meaning"] = mn
	if not w.has("study_phonetic"):
		w["study_phonetic"] = ""
	if not w.has("study_pos"):
		w["study_pos"] = ""

func _extract_meaning_from_prompt(prompt: String) -> String:
	var t: String = prompt.replace("[center]", "").replace("[/center]", "")
	var key: String = "释义："
	var idx: int = t.find(key)
	if idx == -1:
		var lines: PackedStringArray = t.strip_edges().split("\n")
		if lines.size() > 0:
			return str(lines[0]).strip_edges()
		return ""
	idx += key.length()
	var end: int = t.find("\n", idx)
	if end == -1:
		return t.substr(idx).strip_edges()
	return t.substr(idx, end - idx).strip_edges()

## 是否还需要「先学」一步。introduced 是新版学习介绍页标记；旧存档没有该字段时，即使 learned=true 也补看一次。
func word_needs_learn_phase(word_id: String) -> bool:
	var st: Dictionary = _get_state(word_id)
	if st.is_empty():
		return true
	return not bool(st.get("introduced", false))

## 学完一面后调用，写入 profile（与间隔复习状态同表合并）。
func mark_word_learned(word_id: String) -> void:
	if word_id.is_empty():
		return
	var st: Dictionary = _get_state(word_id)
	st["learned"] = true
	st["introduced"] = true
	Global.profile_data.profile_vocab_word_states[word_id] = st
	FileLoader.save_profile()


func mark_word_introduced(word_id: String) -> void:
	if word_id.is_empty():
		return
	var st: Dictionary = _get_state(word_id)
	st["introduced"] = true
	Global.profile_data.profile_vocab_word_states[word_id] = st
	FileLoader.save_profile()


## 自评「不记得」或需要重学：清空已学/已介绍与 SRS，回到未学状态。
func mark_word_unlearned(word_id: String) -> void:
	if word_id.is_empty():
		return
	var st: Dictionary = _get_state(word_id)
	st.erase("learned")
	st.erase("introduced")
	st["r"] = 0
	st["i"] = 0.0
	st["e"] = 2.5
	st["d"] = 0
	Global.profile_data.profile_vocab_word_states[word_id] = st
	FileLoader.save_profile()


func preview_next_review_hours(word_id: String, correct: bool) -> float:
	var st: Dictionary = _get_state(word_id)
	var r: int = int(st.get("r", 0))
	var i: float = float(st.get("i", 0.0))
	var e: float = float(st.get("e", 2.5))
	if correct:
		r += 1
		if r <= 1:
			i = 1.0
		elif r == 2:
			i = 6.0
		else:
			i = max(1.0, i * e)
	else:
		i = 1.0
	return i

func _parse_book_entries(root: Dictionary) -> Dictionary:
	var book_id: String = str(root.get("book_id", "")).strip_edges()
	var words_raw: Variant = root.get("words", [])
	var entries: Array[Dictionary] = []
	if typeof(words_raw) != TYPE_ARRAY:
		return {"book_id": book_id, "entries": entries}
	if book_id == "":
		return {"book_id": "", "entries": entries}
	for item: Variant in words_raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item
		var local_id: String = str(d.get("id", "")).strip_edges()
		if local_id == "":
			continue
		var full_id: String = "%s:%s" % [book_id, local_id]
		var answers: Array[String] = _parse_answers(d)
		if answers.is_empty():
			continue
		var entry: Dictionary = {
			"id": full_id,
			"prompt": str(d.get("prompt", local_id)),
			"answers": answers,
		}
		if d.has("study_headword"):
			entry["study_headword"] = str(d["study_headword"])
		if d.has("study_meaning"):
			entry["study_meaning"] = str(d["study_meaning"])
		if d.has("study_phonetic"):
			entry["study_phonetic"] = str(d["study_phonetic"])
		if d.has("study_pos"):
			entry["study_pos"] = str(d["study_pos"])
		_attach_study_examples(entry, d)
		entries.append(entry)
	return {"book_id": book_id, "entries": entries}

func _entries_array_from_parse(parsed: Dictionary) -> Array[Dictionary]:
	var raw: Variant = parsed.get("entries", [])
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for e: Variant in raw:
		if typeof(e) == TYPE_DICTIONARY:
			out.append(e as Dictionary)
	return out

func _parse_answers(d: Dictionary) -> Array[String]:
	var answers: Array[String] = []
	var ans_raw: Variant = d.get("answers", [])
	if typeof(ans_raw) == TYPE_ARRAY:
		for a: Variant in ans_raw:
			answers.append(str(a).strip_edges().to_lower())
	elif d.has("answer"):
		answers.append(str(d["answer"]).strip_edges().to_lower())
	return answers


func _resolve_openai_api_key() -> String:
	_ensure_project_dotenv_loaded()
	var k := OS.get_environment("OPENAI_API_KEY").strip_edges()
	if not k.is_empty():
		return k
	k = str(_dotenv_values.get("OPENAI_API_KEY", "")).strip_edges()
	if not k.is_empty():
		return k
	return Global.user_settings_data.settings_openai_api_key.strip_edges()


func _resolve_openai_base_url() -> String:
	_ensure_project_dotenv_loaded()
	var b := OS.get_environment("OPENAI_BASE_URL").strip_edges()
	if b.is_empty():
		b = OS.get_environment("OPENAI_API_BASE").strip_edges()
	if b.is_empty():
		b = str(_dotenv_values.get("OPENAI_BASE_URL", "")).strip_edges()
	if b.is_empty():
		b = str(_dotenv_values.get("OPENAI_API_BASE", "")).strip_edges()
	if b.is_empty():
		b = Global.user_settings_data.settings_openai_base_url.strip_edges()
	if b.is_empty():
		b = "https://api.openai.com/v1"
	return b.rstrip("/")


func _resolve_openai_model() -> String:
	_ensure_project_dotenv_loaded()
	var m := OS.get_environment("OPENAI_MODEL").strip_edges()
	if m.is_empty():
		m = str(_dotenv_values.get("OPENAI_MODEL", "")).strip_edges()
	if m.is_empty():
		m = Global.user_settings_data.settings_openai_model.strip_edges()
	if m.is_empty():
		m = "gpt-4o-mini"
	return m


func _openai_chat_completions_url() -> String:
	_ensure_project_dotenv_loaded()
	var full := OS.get_environment("OPENAI_CHAT_COMPLETIONS_URL").strip_edges()
	if full.is_empty():
		full = str(_dotenv_values.get("OPENAI_CHAT_COMPLETIONS_URL", "")).strip_edges()
	if not full.is_empty():
		return full.rstrip("/")
	var base := _resolve_openai_base_url()
	if base.ends_with("/chat/completions"):
		return base
	return base + "/chat/completions"

# -- 端侧模型适配（vivo 蓝心大模型 / 竞赛复赛） --

## 返回端侧模型 Chat Completions 端点；空字符串表示未配置。
func _resolve_ondevice_endpoint() -> String:
	_ensure_project_dotenv_loaded()
	var ep := OS.get_environment("ONDEVICE_MODEL_ENDPOINT").strip_edges()
	if ep.is_empty():
		ep = str(_dotenv_values.get("ONDEVICE_MODEL_ENDPOINT", "")).strip_edges()
	return ep.rstrip("/")

## 返回端侧模型名称；空字符串表示未配置。
func _resolve_ondevice_model() -> String:
	_ensure_project_dotenv_loaded()
	var m := OS.get_environment("ONDEVICE_MODEL_NAME").strip_edges()
	if m.is_empty():
		m = str(_dotenv_values.get("ONDEVICE_MODEL_NAME", "")).strip_edges()
	return m

## 是否优先使用端侧模型（否则仅作 fallback）。
func _prefer_ondevice() -> bool:
	var v := OS.get_environment("ONDEVICE_EXAMPLE_PREFER").strip_edges().to_lower()
	if v == "1" or v == "true" or v == "yes":
		return true
	return false

## 端侧是否可用（已配置端点 + 模型名）。
func _ondevice_available() -> bool:
	return not _resolve_ondevice_endpoint().is_empty() and not _resolve_ondevice_model().is_empty()

## 获取当前应使用的模型名称（端侧优先策略）。
func _resolve_effective_model() -> String:
	if _prefer_ondevice() and _ondevice_available():
		return _resolve_ondevice_model()
	return _resolve_openai_model()

## 获取当前应使用的 API URL（端侧优先策略）。
func _resolve_effective_chat_completions_url() -> String:
	if _prefer_ondevice() and _ondevice_available():
		var ep := _resolve_ondevice_endpoint()
		if ep.ends_with("/chat/completions"):
			return ep
		return ep + "/chat/completions"
	return _openai_chat_completions_url()

## 端侧调用是否需要鉴权。
func _ondevice_requires_auth() -> bool:
	var v := OS.get_environment("ONDEVICE_REQUIRES_AUTH").strip_edges().to_lower()
	if v == "1" or v == "true" or v == "yes":
		return true
	return false

## 端侧 API Key（可选，fallback 到 OPENAI_API_KEY）。
func _resolve_ondevice_api_key() -> String:
	_ensure_project_dotenv_loaded()
	var k := OS.get_environment("ONDEVICE_API_KEY").strip_edges()
	if k.is_empty():
		k = str(_dotenv_values.get("ONDEVICE_API_KEY", "")).strip_edges()
	if k.is_empty():
		k = _resolve_openai_api_key()
	return k

## 返回 [url, model, prefer_ondevice] 三元组。
func _resolve_effective_http_params() -> Array:
	var prefer_ondevice := _prefer_ondevice() and _ondevice_available()
	var url := _resolve_effective_chat_completions_url()
	var model := _resolve_effective_model()
	return [url, model, prefer_ondevice]


func _split_domain_csv_gd(s: String) -> Array[String]:
	var out: Array[String] = []
	for chunk in s.split(",", false):
		for chunk2 in chunk.split("，", false):
			var x := chunk2.strip_edges()
			if not x.is_empty() and not out.has(x):
				out.append(x)
	return out


func _collect_openai_domain_pieces() -> Array[String]:
	var pieces: Array[String] = []
	for tid: String in Global.user_settings_data.settings_vocab_example_domain_tags:
		var zh: String = str(PRESET_DOMAIN_ZH.get(tid, tid))
		if not zh.is_empty() and not pieces.has(zh):
			pieces.append(zh)
	var custom := Global.user_settings_data.settings_vocab_example_domain_custom.strip_edges()
	for p in _split_domain_csv_gd(custom):
		if not pieces.has(p):
			pieces.append(p)
	_ensure_project_dotenv_loaded()
	var env_dom := OS.get_environment("VOCAB_EXAMPLE_DOMAINS").strip_edges()
	if env_dom.is_empty():
		env_dom = str(_dotenv_values.get("VOCAB_EXAMPLE_DOMAINS", "")).strip_edges()
	for p in _split_domain_csv_gd(env_dom):
		var z := str(PRESET_DOMAIN_ZH.get(p, p))
		if not z.is_empty() and not pieces.has(z):
			pieces.append(z)
	if pieces.is_empty():
		for tid: String in DEFAULT_EXAMPLE_DOMAIN_PRESETS:
			var fallback := str(PRESET_DOMAIN_ZH.get(tid, tid))
			if not fallback.is_empty() and not pieces.has(fallback):
				pieces.append(fallback)
	return pieces


func example_domain_summary() -> String:
	return "、".join(_collect_openai_domain_pieces())


func _build_openai_domain_line() -> String:
	var pieces := _collect_openai_domain_pieces()
	if pieces.is_empty():
		return ""
	return (
		"用户个人兴趣/例句语境偏好优先贴近："
		+ "、".join(pieces)
		+ "。（在自然地道前提下尽量体现；无法兼顾时以词语准确用法为准）"
	)


func _build_openai_system_prompt(batch_mode: bool = false) -> String:
	var base := OPENAI_EXAMPLE_SYSTEM_BATCH if batch_mode else OPENAI_EXAMPLE_SYSTEM_BASE
	var dom := _build_openai_domain_line()
	if dom.is_empty():
		return base
	return base + "\n\n【例句语境偏好】" + dom


func _strip_json_fence_gd(s: String) -> String:
	var t := s.strip_edges()
	if not t.begins_with("```"):
		return t
	var lines: Array = Array(t.split("\n"))
	if lines.size() > 0 and str(lines[0]).begins_with("```"):
		lines.remove_at(0)
	if lines.size() > 0 and str(lines[lines.size() - 1]).strip_edges() == "```":
		lines.remove_at(lines.size() - 1)
	var acc := ""
	for i in range(lines.size()):
		if i > 0:
			acc += "\n"
		acc += str(lines[i])
	return acc.strip_edges()


## 模型偶发把 BBCode 写进例句 JSON，会破坏 RichTextLabel；只做保守剥离。
func _sanitize_vocab_example_model_text(s: String) -> String:
	var t: String = s.strip_edges()
	var leaks: PackedStringArray = [
		"[/center]", "[center]", "[/left]", "[left]", "[/right]", "[right]",
		"[/color]", "[/url]", "[/b]", "[/i]", "[/u]", "[/s]",
		"[/font_size]", "[/font]",
	]
	for lk: String in leaks:
		t = t.replace(lk, "")
	while t.find("  ") != -1:
		t = t.replace("  ", " ")
	return t.strip_edges()


func _coerce_api_examples(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item: Variant in raw:
		if typeof(item) == TYPE_STRING:
			var st := _sanitize_vocab_example_model_text(str(item))
			if not st.is_empty():
				out.append({"sentence": st, "gloss": "", "sentence_zh": ""})
		elif typeof(item) == TYPE_DICTIONARY:
			var d: Dictionary = item as Dictionary
			var sent := _sanitize_vocab_example_model_text(
				str(d.get("sentence", d.get("en", d.get("text", ""))))
			)
			if sent.is_empty():
				continue
			var gloss := _sanitize_vocab_example_model_text(
				str(d.get("gloss", d.get("meaning", d.get("sense", ""))))
			)
			var zh := _sanitize_vocab_example_model_text(
				str(
					d.get(
						"sentence_zh",
						d.get("zh", d.get("translation", d.get("cn", d.get("chinese", ""))))
					)
				)
			)
			out.append({"sentence": sent, "gloss": gloss, "sentence_zh": zh})
	return out


func _parse_examples_content(content: String) -> Array:
	var stripped := _strip_json_fence_gd(content)
	var parsed: Variant = JSON.parse_string(stripped)
	if typeof(parsed) == TYPE_ARRAY:
		return _coerce_api_examples(parsed)
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var d: Dictionary = parsed as Dictionary
	for alt_key: String in ["examples", "data", "items", "sentences", "study_examples"]:
		var ex: Variant = d.get(alt_key)
		if typeof(ex) == TYPE_ARRAY:
			var coerced: Array = _coerce_api_examples(ex)
			if not coerced.is_empty():
				return coerced
	return []


func _parse_batch_examples_content(content: String) -> Dictionary:
	var stripped := _strip_json_fence_gd(content)
	var parsed: Variant = JSON.parse_string(stripped)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed as Dictionary
	var batch: Variant = d.get("batch")
	if typeof(batch) != TYPE_ARRAY:
		return {}
	var out: Dictionary = {}
	for item: Variant in batch:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var item_d: Dictionary = item as Dictionary
		var wid: String = str(item_d.get("word_id", ""))
		if wid.is_empty():
			continue
		var ex: Array = _coerce_api_examples(item_d.get("examples", []))
		if not ex.is_empty():
			out[wid] = ex
	return out


func _word_dict_has_nonempty_examples(wd: Dictionary) -> bool:
	if not wd.has("study_examples"):
		return false
	var ex: Variant = wd["study_examples"]
	if typeof(ex) != TYPE_ARRAY:
		return false
	var arr: Array = ex as Array
	for item: Variant in arr:
		if typeof(item) == TYPE_STRING:
			if str(item).strip_edges() != "":
				return true
		elif typeof(item) == TYPE_DICTIONARY:
			var d: Dictionary = item as Dictionary
			var sent := str(d.get("sentence", d.get("en", d.get("text", "")))).strip_edges()
			if sent != "":
				return true
	return false


func word_has_nonempty_examples(word: Dictionary) -> bool:
	return _word_dict_has_nonempty_examples(word)


## 有条目但缺整句中文译文（旧缓存 / 模型漏字段）：需要重新拉 API 写回缓存。
func _word_study_examples_need_zh_refresh(wd: Dictionary) -> bool:
	if not wd.has("study_examples"):
		return false
	var ex: Variant = wd["study_examples"]
	if typeof(ex) != TYPE_ARRAY:
		return false
	var arr: Array = ex as Array
	if arr.is_empty():
		return false
	for item: Variant in arr:
		if typeof(item) == TYPE_STRING:
			return true
		elif typeof(item) == TYPE_DICTIONARY:
			if str((item as Dictionary).get("sentence_zh", "")).strip_edges().is_empty():
				return true
	return false


func word_study_examples_need_zh_refresh(word: Dictionary) -> bool:
	var wid := str(word.get("id", ""))
	if not wid.is_empty() and bool(_vocab_example_zh_gave_up_ids.get(wid, false)):
		return false
	return _word_study_examples_need_zh_refresh(word)


func has_openai_configured() -> bool:
	return not _resolve_openai_api_key().is_empty()


func _apply_vocab_example_override(w: Dictionary) -> void:
	var wid := str(w.get("id", ""))
	if wid.is_empty():
		return
	_ensure_example_cache_loaded()
	if _example_cache_entries.has(wid):
		return
	if not Global.profile_data.profile_vocab_example_overrides.has(wid):
		return
	var ov: Variant = Global.profile_data.profile_vocab_example_overrides[wid]
	var coerced: Array = _coerce_api_examples(ov)
	if coerced.is_empty():
		return
	w["study_examples"] = coerced


func _patch_word_examples_in_pool(wid: String, examples: Array) -> void:
	for w in _words:
		if str(w.get("id", "")) == wid:
			w["study_examples"] = examples.duplicate(true)
			break


func _merge_examples_from_pool_into(word: Dictionary, wid: String) -> void:
	for w in _words:
		if str(w.get("id", "")) == wid:
			if _word_dict_has_nonempty_examples(w):
				word["study_examples"] = (w["study_examples"] as Array).duplicate(true)
			break


## 出牌复习前调用：从 user:// 例句缓存与当前词池合并进本 dict（_pick_word 返回的是副本，否则学习面板读不到已生成例句）。不访问网络。
func merge_disk_and_pool_examples_into_word(word: Dictionary) -> void:
	var wid := str(word.get("id", ""))
	if wid.is_empty():
		return
	# 先尝试文件（可覆盖词条里无效的 study_examples 占位）
	_try_merge_examples_from_file_cache_into_word(word, wid)
	if _word_dict_has_nonempty_examples(word):
		return
	_merge_examples_from_pool_into(word, wid)


## 当场为缺例句的词条：先读 user://vocab_example_cache.json，没有再调 API 写入缓存并同步词池；同一 word_id 并发只跑一条请求。（有 Key 即会请求，不再依赖旧版「出牌时自动请求」开关。）
func ensure_examples_for_word_on_demand_async(word: Dictionary) -> void:
	var wid := str(word.get("id", ""))
	if wid.is_empty():
		return
	merge_disk_and_pool_examples_into_word(word)
	if _word_dict_has_nonempty_examples(word) and not _word_study_examples_need_zh_refresh(word):
		return
	if _resolve_openai_api_key().is_empty():
		return
	if _example_fetch_in_progress.get(wid, false):
		while _example_fetch_in_progress.get(wid, false):
			await get_tree().process_frame
		merge_disk_and_pool_examples_into_word(word)
		if _word_dict_has_nonempty_examples(word) and not _word_study_examples_need_zh_refresh(word):
			return
	_example_fetch_in_progress[wid] = true
	var system := _build_openai_system_prompt()
	var user_pl := _build_openai_user_payload_from_word_entry(word)
	var resp := await _http_openai_chat_completion(_example_http_ondemand, system, user_pl)
	if not bool(resp.get("ok", false)):
		push_warning("VocabStudy on-demand examples: %s" % str(resp.get("err", "?")))
		_example_fetch_in_progress.erase(wid)
		return
	var raw_content := str(resp.get("content", ""))
	var examples: Array = _parse_examples_content(raw_content)
	if examples.is_empty():
		var clip := raw_content.strip_edges()
		clip = clip.substr(0, mini(320, clip.length()))
		push_warning(
			"VocabStudy on-demand examples: 已收到 200 但解析不到例句数组（id=%s）。请核对模型是否按 JSON 返回 examples[]，或兼容端是否改字段名。正文片段：%s"
			% [wid, clip]
		)
		_example_fetch_in_progress.erase(wid)
		return
	word["study_examples"] = examples.duplicate(true)
	if not _word_study_examples_need_zh_refresh(word):
		_vocab_example_zh_gave_up_ids.erase(wid)
	else:
		push_warning(
			"VocabStudy on-demand: 例句仍缺 sentence_zh（本条本局不再自动重拉），id=%s" % wid
		)
		_vocab_example_zh_gave_up_ids[wid] = true
	_persist_examples_to_example_cache_file(wid, examples)
	_patch_word_examples_in_pool(wid, examples)
	_example_fetch_in_progress.erase(wid)


func _background_example_prefetch_budget_left() -> int:
	var daily_budget: int = int(Global.user_settings_data.settings_vocab_daily_ordered_example_words)
	if daily_budget <= 0:
		return 0
	var run_budget: int = clampi(daily_budget, EXAMPLE_API_BATCH_SIZE, 200)
	return maxi(0, run_budget - _example_prefetch_requested_this_run)


func _begin_background_example_prefetch(
	exclude_word_id: String = "",
	delay_seconds: float = BACKGROUND_EXAMPLE_PREFETCH_DELAY_SECONDS
) -> void:
	if _example_prefetch_busy or _example_prefetch_timer_pending:
		return
	if not Global.is_run or _words.is_empty() or not has_openai_configured():
		return
	if _background_example_prefetch_budget_left() <= 0:
		return
	var delay := delay_seconds
	if delay < 0.05:
		delay = 0.05
	_example_prefetch_timer_pending = true
	get_tree().create_timer(delay).timeout.connect(
		_on_background_example_prefetch_timer.bind(exclude_word_id),
		CONNECT_ONE_SHOT
	)


func _on_background_example_prefetch_timer(exclude_word_id: String = "") -> void:
	_example_prefetch_timer_pending = false
	await _run_background_example_prefetch_async(exclude_word_id)


func _finish_background_example_prefetch(
	should_continue: bool,
	exclude_word_id: String = ""
) -> void:
	_example_prefetch_busy = false
	if should_continue:
		_begin_background_example_prefetch(exclude_word_id, BACKGROUND_EXAMPLE_PREFETCH_DELAY_SECONDS)


func _run_background_example_prefetch_async(exclude_word_id: String = "") -> void:
	if _example_prefetch_busy:
		return
	if not Global.is_run or _words.is_empty() or not has_openai_configured():
		return
	if _sequential_batch_busy:
		_begin_background_example_prefetch(exclude_word_id, BACKGROUND_EXAMPLE_PREFETCH_DELAY_SECONDS)
		return
	var budget_left := _background_example_prefetch_budget_left()
	if budget_left <= 0:
		return
	_example_prefetch_busy = true
	var words_to_process := _collect_background_example_prefetch_words(
		mini(BACKGROUND_EXAMPLE_PREFETCH_WORDS, budget_left),
		exclude_word_id
	)
	if words_to_process.is_empty():
		_finish_background_example_prefetch(false, exclude_word_id)
		return
	var batch: Array[Dictionary] = words_to_process.slice(
		0,
		mini(EXAMPLE_API_BATCH_SIZE, mini(words_to_process.size(), budget_left))
	)
	for w in batch:
		_example_fetch_in_progress[str(w.get("id", ""))] = true
	_example_prefetch_requested_this_run += batch.size()

	var system := _build_openai_system_prompt(true)
	var user_pl := _build_openai_user_payload_batch(batch)
	var resp := await _http_openai_chat_completion(_example_http_batch, system, user_pl)

	if not bool(resp.get("ok", false)):
		push_warning("VocabStudy background prefetch: %s" % str(resp.get("err", "?")))
		for w in batch:
			_example_fetch_in_progress.erase(str(w.get("id", "")))
		_finish_background_example_prefetch(false, exclude_word_id)
		return

	var batch_results: Dictionary = _parse_batch_examples_content(str(resp.get("content", "")))
	if batch_results.is_empty():
		for w in batch:
			_example_fetch_in_progress.erase(str(w.get("id", "")))
		_finish_background_example_prefetch(false, exclude_word_id)
		return

	for w in batch:
		var wid: String = str(w.get("id", ""))
		var examples: Array = batch_results.get(wid, []) as Array
		if examples.is_empty():
			_example_fetch_in_progress.erase(wid)
			continue
		w["study_examples"] = examples.duplicate(true)
		if not _word_study_examples_need_zh_refresh(w):
			_vocab_example_zh_gave_up_ids.erase(wid)
		else:
			_vocab_example_zh_gave_up_ids[wid] = true
		_persist_examples_to_example_cache_file(wid, examples)
		_patch_word_examples_in_pool(wid, examples)
		_example_fetch_in_progress.erase(wid)
	_finish_background_example_prefetch(
		_background_example_prefetch_budget_left() > 0,
		exclude_word_id
	)


func _collect_background_example_prefetch_words(limit: int, exclude_word_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if limit <= 0:
		return out
	var seen: Dictionary[String, bool] = {}
	var now: int = int(Time.get_unix_time_from_system())
	var due_review_ids: Array[String] = []
	var new_ids: Array[String] = []
	for w: Dictionary in _words:
		var wid: String = str(w.get("id", ""))
		if wid.is_empty():
			continue
		var st: Dictionary = _get_state(wid)
		var due: int = int(st.get("d", 0))
		if st.is_empty():
			new_ids.append(wid)
		elif not bool(st.get("introduced", false)):
			if due <= now:
				new_ids.append(wid)
		elif due <= now:
			due_review_ids.append(wid)

	new_ids.shuffle()
	for wid: String in new_ids:
		_append_example_prefetch_word_by_id(out, seen, wid, limit, exclude_word_id)
		if out.size() >= limit:
			return out

	var due_pool: Array[String] = _slice_due_ids_for_daily_budget(due_review_ids)
	if due_pool.is_empty():
		due_pool = due_review_ids
	due_pool.shuffle()
	for wid: String in due_pool:
		_append_example_prefetch_word_by_id(out, seen, wid, limit, exclude_word_id)
		if out.size() >= limit:
			return out

	var start: int = int(Global.profile_data.profile_vocab_seq_example_cursor)
	if _words.size() > 0:
		start = posmod(start, _words.size())
	for k in range(_words.size()):
		var idx: int = posmod(start + k, _words.size())
		_append_example_prefetch_word(out, seen, _words[idx], limit, exclude_word_id)
		if out.size() >= limit:
			return out
	return out


func _append_example_prefetch_word_by_id(
	out: Array[Dictionary],
	seen: Dictionary[String, bool],
	wid: String,
	limit: int,
	exclude_word_id: String
) -> void:
	var w := _word_by_id(wid)
	if w.is_empty():
		return
	_append_example_prefetch_word(out, seen, w, limit, exclude_word_id)


func _append_example_prefetch_word(
	out: Array[Dictionary],
	seen: Dictionary[String, bool],
	w: Dictionary,
	limit: int,
	exclude_word_id: String
) -> void:
	if out.size() >= limit:
		return
	var wid := str(w.get("id", ""))
	if wid.is_empty() or wid == exclude_word_id:
		return
	if bool(seen.get(wid, false)):
		return
	seen[wid] = true
	if _example_fetch_in_progress.get(wid, false):
		return
	var probe: Dictionary = w.duplicate(true)
	merge_disk_and_pool_examples_into_word(probe)
	if _word_dict_has_nonempty_examples(probe) and not word_study_examples_need_zh_refresh(probe):
		return
	out.append(probe)


func _load_vocab_book_root_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var v: Variant = JSON.parse_string(text)
	if typeof(v) != TYPE_DICTIONARY:
		return {}
	return v as Dictionary


func _save_vocab_book_root_to_user_dir(book_id: String, root: Dictionary) -> Error:
	_ensure_user_vocab_dir()
	var path: String = USER_BOOKS_DIR.path_join("book_%s.json" % book_id)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(root, "\t"))
	f.close()
	return OK


func _build_openai_user_payload_from_word_entry(wd: Dictionary) -> String:
	var prompt_plain := str(wd.get("prompt", ""))
	prompt_plain = prompt_plain.replace("[center]", "").replace("[/center]", "").strip_edges()
	var payload := {
		"id": wd.get("id"),
		"study_headword": wd.get("study_headword", ""),
		"study_meaning": wd.get("study_meaning", ""),
		"study_pos": wd.get("study_pos", ""),
		"book_name": _word_book_name(wd),
		"answers": wd.get("answers", []),
		"prompt_plain": prompt_plain,
	}
	return JSON.stringify(payload)


func _build_openai_user_payload_batch(words: Array[Dictionary]) -> String:
	var items: Array[Dictionary] = []
	for w: Dictionary in words:
		var prompt_plain := str(w.get("prompt", ""))
		prompt_plain = prompt_plain.replace("[center]", "").replace("[/center]", "").strip_edges()
		items.append({
			"word_id": w.get("id"),
			"study_headword": w.get("study_headword", ""),
			"study_meaning": w.get("study_meaning", ""),
			"study_pos": w.get("study_pos", ""),
			"book_name": _word_book_name(w),
			"answers": w.get("answers", []),
			"prompt_plain": prompt_plain,
		})
	var payload := {
		"words": items,
	}
	return JSON.stringify(payload)


func _extract_chat_completion_content_from_response_body(txt: String) -> Dictionary:
	var outer: Variant = JSON.parse_string(txt)
	if typeof(outer) != TYPE_DICTIONARY:
		return {"ok": false, "err": "bad_response_json"}
	var root: Dictionary = outer as Dictionary
	var choices: Variant = root.get("choices")
	if typeof(choices) != TYPE_ARRAY or (choices as Array).is_empty():
		var out_wrap: Variant = root.get("output")
		if typeof(out_wrap) == TYPE_DICTIONARY:
			choices = (out_wrap as Dictionary).get("choices")
	if typeof(choices) != TYPE_ARRAY or (choices as Array).is_empty():
		return {"ok": false, "err": "no_choices"}
	var msg0: Variant = (choices as Array)[0]
	if typeof(msg0) != TYPE_DICTIONARY:
		return {"ok": false, "err": "bad_choice"}
	var msg_d: Dictionary = msg0 as Dictionary
	var inner: Variant = msg_d.get("message")
	if typeof(inner) != TYPE_DICTIONARY:
		return {"ok": false, "err": "bad_message"}
	var content := str((inner as Dictionary).get("content", ""))
	return {"ok": true, "content": content}


func _http_openai_chat_completion(client: HTTPRequest, system: String, user_json: String) -> Dictionary:
	var effective_params: Array = _resolve_effective_http_params()
	var url: String = effective_params[0]
	var model: String = effective_params[1]
	var prefer_ondevice: bool = effective_params[2]

	# 端侧未配置 + 无 API Key 则快速失败
	if not prefer_ondevice:
		if _resolve_openai_api_key().is_empty():
			return {"ok": false, "err": "no_key"}

	var key := _resolve_openai_api_key()
	if prefer_ondevice and _ondevice_requires_auth():
		key = _resolve_ondevice_api_key()

	var headers := PackedStringArray(["Content-Type: application/json"])
	if not key.is_empty():
		headers.append("Authorization: Bearer %s" % key)

	for use_json_object_mode: int in range(2):
		var payload := {
			"model": model,
			"messages": [
				{"role": "system", "content": system},
				{"role": "user", "content": user_json},
			],
			"temperature": 0.65,
		}
		if use_json_object_mode == 0:
			payload["response_format"] = {"type": "json_object"}
		var err: Error = client.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
		if err != OK:
			if err == ERR_BUSY:
				push_warning(
					"VocabStudy: HTTPRequest 正忙（ERR_BUSY），例句请求被跳过。若已拆 batch/ondemand 仍出现，说明同一 client 上并发调用了 API。"
				)
			return {"ok": false, "err": "request_%d" % err}
		var http_ret = await client.request_completed
		if typeof(http_ret) != TYPE_ARRAY:
			return {"ok": false, "err": "http_signal"}
		var http_arr: Array = http_ret as Array
		var response_code: int = int(http_arr[1])
		var body: PackedByteArray = http_arr[3]
		var txt := body.get_string_from_utf8()
		if response_code == 200:
			var parsed: Dictionary = _extract_chat_completion_content_from_response_body(txt)
			if bool(parsed.get("ok", false)):
				return parsed
			return {"ok": false, "err": str(parsed.get("err", "parse_err"))}
		if use_json_object_mode == 0 and (response_code == 400 or response_code == 422):
			var clip0 := txt.substr(0, mini(220, txt.length()))
			push_warning(
				"VocabStudy: Chat Completions 返回 HTTP %d（可能不支持 response_format），将去掉 json_object 模式重试。片段：%s"
				% [response_code, clip0]
			)
			continue
			var clip := txt.substr(0, mini(280, txt.length()))
			if response_code == 0:
				return {"ok": false, "err": "无法连接 API 服务器，请检查网络或 API 地址配置"}
			return {"ok": false, "err": "HTTP %d %s" % [response_code, clip]}
	return {"ok": false, "err": "json_mode_retry_exhausted"}



## 调用 OpenAI 兼容 Chat Completions，为启用词书中「尚无 study_examples」的词条批量生成例句，写入 user://vocab_books/book_<id>.json 并 reload。
func fill_missing_examples_via_api(max_words: int = 35) -> Dictionary:
	if _resolve_openai_api_key().is_empty():
		return {"ok": false, "message": I18N.tr_key("vocab.api.need_key")}
	var system := _build_openai_system_prompt()
	var budget: int = maxi(1, max_words)
	var generated := 0
	for book_id: String in Global.user_settings_data.settings_vocab_enabled_book_ids:
		if generated >= budget:
			break
		if book_id == BUILTIN_DEFAULT_ID:
			push_warning("VocabStudy: " + I18N.tr_key("vocab.api.builtin_skip"))
			continue
		var src_path: String = str(_book_id_to_path.get(book_id, ""))
		if src_path.is_empty() or not FileAccess.file_exists(src_path):
			continue
		var root := _load_vocab_book_root_dict(src_path)
		if root.is_empty():
			continue
		var words_raw: Variant = root.get("words", [])
		if typeof(words_raw) != TYPE_ARRAY:
			continue
		var arr: Array = words_raw as Array
		var modified := false
		# 大词书缺例句的词条若按数组顺序处理，永远只会填前几千条；打乱后每轮随机覆盖全书。
		var missing_indices: Array = []
		for wi in range(arr.size()):
			var item: Variant = arr[wi]
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var wd_check: Dictionary = item as Dictionary
			if _word_dict_has_nonempty_examples(wd_check):
				continue
			missing_indices.append(wi)
		missing_indices.shuffle()
		for wi_variant in missing_indices:
			if generated >= budget:
				break
			var wi: int = wi_variant as int
			var item2: Variant = arr[wi]
			if typeof(item2) != TYPE_DICTIONARY:
				continue
			var wd: Dictionary = item2 as Dictionary
			var wid := str(wd.get("id", "?"))
			Signals.vocab_example_api_progress.emit(generated, budget, wid)
			var user_pl := _build_openai_user_payload_from_word_entry(wd)
			var resp := await _http_openai_chat_completion(_example_http_ondemand, system, user_pl)
			if not bool(resp.get("ok", false)):
				return {"ok": false, "message": I18N.tr_key("vocab.api.http_err") % str(resp.get("err", "?"))}
			var examples: Array = _parse_examples_content(str(resp.get("content", "")))
			if examples.is_empty():
				continue
			wd["study_examples"] = examples
			modified = true
			generated += 1
			await get_tree().create_timer(0.35).timeout
		if modified:
			var err_save: Error = _save_vocab_book_root_to_user_dir(book_id, root)
			if err_save != OK:
				return {"ok": false, "message": "save err %s" % str(err_save)}
	reload_from_settings()
	Signals.vocab_example_api_progress.emit(generated, budget, "done")
	if generated == 0:
		return {"ok": true, "message": I18N.tr_key("vocab.api.none_needed")}
	return {"ok": true, "message": I18N.tr_key("vocab.api.saved") % generated}


func combat_vocab_review_mode() -> String:
	var modes := _normalized_review_modes_enabled()
	var rng: RandomNumberGenerator
	if Global.player_data != null:
		rng = Global.player_data.get_player_rng("rng_vocab_review_mode_pick")
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return modes[rng.randi_range(0, modes.size() - 1)]


## 四选一复习：从词池取若干「其他词」的 headword 作干扰项（不含本题任一可接受拼写）。
func sample_distractor_headwords_for_mc(
	exclude_word_id: String, accepted_answers: Array, desired: int, rng: RandomNumberGenerator
) -> Array[String]:
	var blocked: Dictionary = {}
	for a: Variant in accepted_answers:
		var low := str(a).strip_edges().to_lower()
		if not low.is_empty():
			blocked[low] = true
	var candidates: Array[String] = []
	for w: Dictionary in _words:
		if str(w.get("id", "")) == exclude_word_id:
			continue
		var hw := str(w.get("study_headword", "")).strip_edges()
		if hw.is_empty():
			continue
		if hw.length() > 40 or hw.find("\n") != -1:
			continue
		var low2 := hw.to_lower()
		if blocked.has(low2):
			continue
		candidates.append(hw)
	if candidates.is_empty():
		return []
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var out: Array[String] = []
	for hw3: String in candidates:
		if out.size() >= desired:
			break
		var l3 := hw3.to_lower()
		if blocked.has(l3):
			continue
		blocked[l3] = true
		out.append(hw3)
	return out


## 四选一（中文释义）：从词池其它词条取干扰释义。
func sample_distractor_meanings_for_mc(
	exclude_word_id: String, correct_meaning: String, desired: int, rng: RandomNumberGenerator
) -> Array[String]:
	var blocked: Dictionary = {}
	var cm := correct_meaning.strip_edges()
	if not cm.is_empty():
		blocked[cm] = true
	var candidates: Array[String] = []
	for w: Dictionary in _words:
		if str(w.get("id", "")) == exclude_word_id:
			continue
		var mn := str(w.get("study_meaning", "")).strip_edges()
		if mn.is_empty():
			continue
		if mn.length() > 80 or mn.find("\n") != -1:
			continue
		if blocked.has(mn):
			continue
		candidates.append(mn)
	if candidates.is_empty():
		return []
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var out: Array[String] = []
	for mn2: String in candidates:
		if out.size() >= desired:
			break
		if blocked.has(mn2):
			continue
		blocked[mn2] = true
		out.append(mn2)
	return out


func gate_before_play() -> bool:
	# 纯卡牌模式：跳过单词复习
	var current_mode: String = Global.user_settings_data.settings_vocab_mode
	if current_mode == "none":
		return false

	if _overlay == null:
		print("VocabStudy.gate: _overlay is null")
		return false
	if _words.is_empty():
		print("VocabStudy.gate: _words is empty")
		return false
	if not Global.is_player_in_combat():
		return false

	if current_mode == VOCAB_MODE_PER_TURN:
		return await _gate_before_play_per_turn()
	else:
		return await _gate_before_play_per_card()

func _gate_before_play_per_card() -> bool:
	var word: Dictionary = _pick_word_for_prompt()
	if word.is_empty():
		print("VocabStudy.gate: _pick_word_for_prompt returned empty")
		return false
	_begin_background_example_prefetch(str(word.get("id", "")))
	var outcome: int = await _overlay.run_review(word)
	var wid: String = str(word["id"])
	match outcome:
		WordReviewOverlay.REVIEW_OUTCOME_OK:
			_record_result(wid, true)
			return false
		WordReviewOverlay.REVIEW_OUTCOME_SKIPPED:
			_record_result(wid, false)
			return true
		WordReviewOverlay.REVIEW_OUTCOME_WRONG:
			if _try_first_draft_forgive_wrong_answer():
				return false
			_record_result(wid, false)
			return true
		_:
			_record_result(wid, false)
			return true

## per_turn 模式：返回当前步骤对应的复习方式 id
func per_turn_sequential_review_step() -> String:
	var steps := learn_pipeline_enabled_step_ids_ordered()
	if steps.is_empty():
		return VOCAB_REVIEW_MODE_SPELL
	return steps[_per_turn_current_step_index % steps.size()]


func _gate_before_play_per_turn() -> bool:
	var word: Dictionary = _pick_word_for_per_turn_mode()
	if word.is_empty():
		return false

	var wid: String = str(word.get("id", ""))
	_begin_background_example_prefetch(wid)

	var step := per_turn_sequential_review_step()
	var outcome: int = await _overlay.run_review_single_step(word, step)

	match outcome:
		WordReviewOverlay.REVIEW_OUTCOME_OK:
			_record_result(wid, true)
			_per_turn_current_step_index += 1
			var steps := learn_pipeline_enabled_step_ids_ordered()
			if steps.is_empty():
				steps = VOCAB_LEARN_STEP_ORDER
			if _per_turn_current_step_index >= steps.size():
				_per_turn_current_step_index = 0
				_advance_per_turn_word()
			return false
		WordReviewOverlay.REVIEW_OUTCOME_SKIPPED:
			_record_result(wid, false)
			return true
		WordReviewOverlay.REVIEW_OUTCOME_WRONG:
			if _try_first_draft_forgive_wrong_answer():
				return false
			_record_result(wid, false)
			return true
		_:
			_record_result(wid, false)
			return true

func _pick_word_for_per_turn_mode() -> Dictionary:
	# 如果已有当前单词且仍在词池中，继续使用
	if not _per_turn_current_word_id.is_empty():
		for w: Dictionary in _words:
			if str(w.get("id", "")) == _per_turn_current_word_id:
				return w.duplicate(true)
		_per_turn_current_word_id = ""

	if _words.is_empty():
		return {}

	# SRS 调度：到期复习词 > 新词 > 随机
	var now: int = int(Time.get_unix_time_from_system())
	var due_review_ids: Array[String] = []
	var new_ids: Array[String] = []
	for w: Dictionary in _words:
		var id: String = str(w["id"])
		var st: Dictionary = _get_state(id)
		var due: int = int(st.get("d", 0))
		if st.is_empty():
			new_ids.append(id)
		elif not bool(st.get("introduced", false)):
			if due <= now:
				new_ids.append(id)
		elif due <= now:
			due_review_ids.append(id)

	if not due_review_ids.is_empty():
		var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_vocab_pick")
		var pick_id: String = due_review_ids[rng.randi_range(0, len(due_review_ids) - 1)]
		_per_turn_current_word_id = pick_id
		return _word_by_id(pick_id)

	if not new_ids.is_empty():
		var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_vocab_new")
		var pick_id: String = new_ids[rng.randi_range(0, len(new_ids) - 1)]
		_per_turn_current_word_id = pick_id
		return _word_by_id(pick_id)

	# 兜底：随机
	var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_vocab_cold")
	var pick_idx: int = rng.randi_range(0, len(_words) - 1)
	_per_turn_current_word_id = str(_words[pick_idx].get("id", ""))
	return _words[pick_idx].duplicate(true)

func _advance_per_turn_word() -> void:
	_per_turn_current_word_id = ""

func _vocab_calendar_day_id() -> int:
	var d: Dictionary = Time.get_datetime_dict_from_system(false)
	return int(d.year) * 10000 + int(d.month) * 100 + int(d.day)


func _slice_due_ids_for_daily_budget(ids: Array[String]) -> Array[String]:
	var cap: int = Global.user_settings_data.settings_vocab_daily_due_cap
	if cap <= 0 or ids.size() <= cap:
		return ids
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_vocab_calendar_day_id()) * 1000003 + int(ids.size()) * 17 + 982451653
	var pool: Array[String] = ids.duplicate()
	var out: Array[String] = []
	while out.size() < cap and not pool.is_empty():
		var j: int = rng.randi_range(0, pool.size() - 1)
		out.append(pool[j])
		pool.remove_at(j)
	return out


func _pick_word_for_prompt() -> Dictionary:
	_ensure_daily_new_plan()
	var pend_id: String = _pending_daily_new_word_id()
	if pend_id != "":
		var w: Dictionary = _word_by_id(pend_id)
		if not w.is_empty():
			return w
	var now: int = int(Time.get_unix_time_from_system())
	var due_review_ids: Array[String] = []
	var new_ids: Array[String] = []
	for w: Dictionary in _words:
		var id: String = str(w["id"])
		var st: Dictionary = _get_state(id)
		var due: int = int(st.get("d", 0))
		if st.is_empty():
			new_ids.append(id)
		elif not bool(st.get("introduced", false)):
			if due <= now:
				new_ids.append(id)
		elif due <= now:
			due_review_ids.append(id)
	if not due_review_ids.is_empty():
		var pool: Array[String] = _slice_due_ids_for_daily_budget(due_review_ids)
		if pool.is_empty():
			pool = due_review_ids
		var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_vocab_pick")
		return _word_by_id(pool[rng.randi_range(0, len(pool) - 1)])
	if not new_ids.is_empty():
		var rng_new: RandomNumberGenerator = Global.player_data.get_player_rng("rng_vocab_new")
		return _word_by_id(new_ids[rng_new.randi_range(0, len(new_ids) - 1)])
	## 无到期、无「新词」队列时：仍从全词池随机一题（不再高概率直接跳过，避免出牌背词形同关闭）。
	var rng_cold: RandomNumberGenerator = Global.player_data.get_player_rng("rng_vocab_cold")
	return _words[rng_cold.randi_range(0, len(_words) - 1)].duplicate(true)

func _word_by_id(id: String) -> Dictionary:
	# Fast path: O(1) index lookup
	var w: Dictionary = _id_to_word.get(id, {})
	if not w.is_empty():
		return w.duplicate(true)
	# Fallback: linear scan (safety net if index was not built)
	for w2: Dictionary in _words:
		if str(w2.get("id", "")) == id:
			return w2.duplicate(true)
	return {}

func _word_book_name(wd: Dictionary) -> String:
	var wid := str(wd.get("id", ""))
	var colon := wid.find(":")
	var bid: String
	if colon != -1:
		bid = wid.substr(0, colon)
	else:
		bid = BUILTIN_DEFAULT_ID
	if bid == BUILTIN_DEFAULT_ID:
		return "内置词书"
	for meta: Dictionary in list_known_books():
		if str(meta.get("book_id", "")) == bid:
			var nm: String = str(meta.get("book_name", "")).strip_edges()
			if not nm.is_empty():
				return nm
			return bid
	return bid

func _get_state(id: String) -> Dictionary:
	var raw: Variant = Global.profile_data.profile_vocab_word_states.get(id, null)
	if typeof(raw) == TYPE_DICTIONARY:
		return raw as Dictionary
	return {}
func _flush_profile_if_dirty() -> void:
	if _profile_dirty:
		FileLoader.save_profile()
		_profile_dirty = false


func _record_result(id: String, correct: bool) -> void:
	var st: Dictionary = _get_state(id)
	var r: int = int(st.get("r", 0))
	var i: float = float(st.get("i", 0.0))
	var e: float = float(st.get("e", 2.5))
	var now: int = int(Time.get_unix_time_from_system())
	if correct:
		r += 1
		if r <= 1:
			i = 1.0
		elif r == 2:
			i = 6.0
		else:
			i = max(1.0, i * e)
		e = min(2.5, e + 0.1)
	else:
		r = 0
		i = 1.0
		e = max(1.3, e - 0.2)
	var next_due: int = now + int(i * 3600.0)
	st["r"] = r
	st["i"] = i
	st["e"] = e
	st["d"] = next_due
	Global.profile_data.profile_vocab_word_states[id] = st
	_profile_dirty = true
