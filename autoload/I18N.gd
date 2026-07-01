extends Node

const DEFAULT_LOCALE: String = "zh_CN"
const LOCALE_DIR: String = "external/locale/"

var current_locale: String = DEFAULT_LOCALE
var _translations: Dictionary = {}

signal locale_changed(locale: String)

func _ready() -> void:
	load_locale(DEFAULT_LOCALE, false)

func load_locale(locale: String, persist_setting: bool = true) -> void:
	current_locale = _normalize_locale(locale)
	_translations = {}
	# NOTE: Do NOT clear FileLoader._cached_json here — it would wipe all
	# game data (cards, enemies, etc.) that has already been loaded.
	var main = FileLoader.load_json(LOCALE_DIR, current_locale + ".json")
	var data = FileLoader.load_json(LOCALE_DIR, current_locale + "_data.json")
	# Fallback: load directly from res:// if FileLoader returned empty
	if main.is_empty():
		main = _load_json_from_res(LOCALE_DIR + current_locale + ".json")
	if data.is_empty():
		data = _load_json_from_res(LOCALE_DIR + current_locale + "_data.json")
	_merge_translations(main)
	_merge_translations(data)
	# Always merge survival translations as a safety net
	_merge_translations(_get_survival_translations())
	if persist_setting:
		Global.user_settings_data.settings_language = current_locale
		FileLoader.save_user_settings()
	locale_changed.emit(current_locale)

func _load_json_from_res(path: String) -> Dictionary:
	# On Android APK, FileAccess.file_exists() may return false for
	# res:// files even though they are readable. Just try to open.
	var full := "res://" + path
	var f := FileAccess.open(full, FileAccess.READ)
	if f != null:
		var text := f.get_as_text()
		var parsed = JSON.parse_string(text)
		if parsed != null:
			return parsed
	return {}

func toggle_locale() -> void:
	if current_locale == "zh_CN":
		load_locale("en_US")
	else:
		load_locale("zh_CN")

func tr_key(key: String, params: Array = []) -> String:
	var template: String = str(_translations.get(key, key))
	if len(params) > 0:
		return template.format(params)
	return template

func tr_enum(prefix: String, enum_key: String) -> String:
	return tr_key(prefix + "." + enum_key.to_lower())

func tr_data(object_id: String, field: String, fallback: String, params: Array = []) -> String:
	var key: String = "data.{0}.{1}".format([object_id, field])
	var template: String = str(_translations.get(key, fallback))
	if len(params) > 0:
		return template.format(params)
	return template

func _normalize_locale(locale: String) -> String:
	match locale:
		"zh", "zh_CN":
			return "zh_CN"
		"en", "en_US":
			return "en_US"
		_:
			return DEFAULT_LOCALE

func _merge_translations(source: Dictionary) -> void:
	for key: String in source.keys():
		_translations[key] = source[key]
## Returns a hardcoded minimal set of critical UI translations (zh_CN).
## Used as a last-resort safety net when locale JSON files cannot be
## loaded (e.g. missing from a corrupted/misconfigured export PCK).
## Without this, all tr_key() calls would return raw keys like
## "menu.continue" instead of readable text.
static func _get_survival_translations() -> Dictionary:
	return {
		"app.title": "弑塔",
		"menu.continue": "继续",
		"menu.forfeit_run": "放弃本局",
		"menu.new_game": "新游戏",
		"menu.codex": "图鉴",
		"menu.setting": "设置",
		"menu.exit": "退出",
		"menu.new_run": "开启新冒险",
		"menu.back": "返回",
		"menu.vocab_prefs_button": "学习设置",
		"menu.vocab_prefs_title": "学习控制台",
		"menu.cards": "卡牌",
		"menu.enemies": "敌人",
		"menu.artifacts": "遗物",
		"menu.consumables": "消耗品",
		"menu.character_name": "角色名称",
		"menu.character_description": "角色描述",
		"menu.artifact_name": "遗物名称",
		"menu.artifact_description": "遗物描述",
		"menu.hp_label": "生命：",
		"menu.money_label": "金币：",
		"menu.seed": "种子",
		"menu.custom_modifiers": "自定义修正",
		"menu.start_run": "开始冒险",
		"combat.use": "使用",
		"combat.discard": "丢弃",
		"combat.chest": "宝箱",
		"combat.shop": "商店",
		"combat.energy": "能量",
		"combat.draw_pile": "抽牌堆",
		"combat.discard_pile": "弃牌堆",
		"combat.exhaust_pile": "消耗堆",
		"combat.pick_cards": "选择卡牌",
		"combat.pick_x_cards": "选择指定数量的卡牌",
		"combat.confirm": "确认",
		"combat.end_turn": "结束回合",
		"combat.select_target": "请选择目标",
		"combat.turn": "第 {0} 回合",
		"overlay.continue": "继续",
		"overlay.skip": "跳过",
		"overlay.resume": "返回游戏",
		"overlay.return_to_title": "返回标题界面",
		"overlay.back_to_main_menu": "返回主菜单",
		"overlay.victory": "胜利",
		"overlay.defeat": "失败",
	}

## 统一翻译入口：所有游戏数据（卡牌/敌人/遗物/消耗品）必须通过这些方法获取翻译

func get_card_name(card_data: CardData) -> String:
	return tr_data(card_data.object_id, "card_name", card_data.card_name)

func get_card_description(card_data: CardData) -> String:
	return tr_data(card_data.object_id, "card_description", card_data.card_description)

func get_enemy_name(enemy_data: EnemyData) -> String:
	return tr_data(enemy_data.object_id, "enemy_name", enemy_data.enemy_name)

func get_artifact_name(artifact_data: ArtifactData) -> String:
	return tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)

func get_artifact_description(artifact_data: ArtifactData) -> String:
	return tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)

func get_consumable_name(consumable_data: ConsumableData) -> String:
	return tr_data(consumable_data.object_id, "consumable_name", consumable_data.consumable_name)

func get_consumable_description(consumable_data: ConsumableData) -> String:
	return tr_data(consumable_data.object_id, "consumable_description", consumable_data.consumable_description)
