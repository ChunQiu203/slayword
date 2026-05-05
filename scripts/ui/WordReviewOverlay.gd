extends Control
class_name WordReviewOverlay
## 战斗中：未学词条先「学习」再默写；已学则直接默写。

## run_review 返回值：供 VocabStudy 区分「答错」与「跳过」（如初稿遗物只对答错免责）。
const REVIEW_OUTCOME_OK := 0
const REVIEW_OUTCOME_WRONG := 1
const REVIEW_OUTCOME_SKIPPED := 2

signal review_completed(success: bool)
## 学习阶段结束：跳过 / 继续默写 / 看答案（按答错处理且不标记已学）
signal _learn_resolved(exit_code: int)

const LEARN_EXIT_SKIP := 0
const LEARN_EXIT_PROCEED := 1
const LEARN_EXIT_PEEK_WRONG := 2

const TOUCH_MIN_BUTTON_H := 52
const TOUCH_LINE_EDIT_H := 50
const FONT_PROMPT := 18
## 学习页：单词标题 / 释义（例句另用更小字号，避免整屏被英文占满）
const FONT_LEARN_HEAD := 26
const FONT_LEARN_MEANING := 17
## 例句区块（明显小于标题）
const FONT_EX_SECTION := 15
const FONT_EX_NUM := 13
const FONT_EX_GLOSS := 13
const FONT_EX_SENT := 14
const FONT_EX_ZH := 13
const FONT_INPUT := 20
const FONT_BUTTON := 20
const FONT_FEEDBACK := 17
const MC_TWO_COLUMN_MIN_W := 560.0
## 默写阶段允许连续提交错误答案的次数（不含「跳过」）；避免无限试错直到蒙对。
const MAX_WRONG_ATTEMPTS_IN_QUIZ := 5

var _panel: PanelContainer
var _outer: VBoxContainer
var _learn_panel: VBoxContainer
var _learn_text: RichTextLabel
var _learn_action_row: HBoxContainer
var _learn_button: Button
var _learn_show_answer_button: Button
var _prompt: RichTextLabel
var _input: LineEdit
var _feedback: Label
var _submit: Button
var _peek_answer_quiz_button: Button
var _skip: Button
var _relearn_button: Button
var _return_after_peek_button: Button
## 默写阶段已点「看答案」，等待用户点「返回」再结束（便于阅读答案）。
var _quiz_peek_answer_shown: bool = false
var _relearn_return_to_quiz: bool = false
var _finished: bool = false
var _result_ok: bool = false
var _review_outcome: int = REVIEW_OUTCOME_OK
var _quiz_wrong_submits: int = 0
var _answers: Array[String] = []
var _word_id: String = ""
var _active_word: Dictionary = {}
var _last_answer_text: String = ""
var _in_learn_wait: bool = false
var _learn_show_answer_busy: bool = false
## 默写阶段题型（与 VocabStudy.combat_vocab_review_mode 一致）
var _quiz_review_mode: String = VocabStudy.VOCAB_REVIEW_MODE_SPELL
var _mc_container: GridContainer
var _mc_option_buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	z_index = 80
	visible = false
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.07, 0.09, 0.12, 0.96)
	panel_sb.border_color = Color(0.58, 0.49, 0.28, 0.95)
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(12)
	panel_sb.content_margin_left = 20
	panel_sb.content_margin_top = 18
	panel_sb.content_margin_right = 20
	panel_sb.content_margin_bottom = 18
	panel_sb.shadow_color = Color(0, 0, 0, 0.45)
	panel_sb.shadow_size = 6
	panel_sb.shadow_offset = Vector2(0, 3)
	_panel.add_theme_stylebox_override("panel", panel_sb)
	add_child(_panel)

	_outer = VBoxContainer.new()
	_outer.add_theme_constant_override("separation", 14)
	_panel.add_child(_outer)

	_learn_panel = VBoxContainer.new()
	_learn_panel.add_theme_constant_override("separation", 16)
	_learn_panel.visible = false
	_outer.add_child(_learn_panel)

	_learn_text = RichTextLabel.new()
	_learn_text.bbcode_enabled = true
	_learn_text.fit_content = true
	_learn_text.scroll_active = false
	_learn_text.add_theme_font_size_override("normal_font_size", FONT_LEARN_MEANING)
	_learn_panel.add_child(_learn_text)

	_learn_action_row = HBoxContainer.new()
	_learn_action_row.add_theme_constant_override("separation", 12)
	_learn_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_learn_panel.add_child(_learn_action_row)

	_learn_button = Button.new()
	_learn_button.text = I18N.tr_key("vocab.review.learn_next_spell")
	_learn_button.custom_minimum_size = Vector2(200, TOUCH_MIN_BUTTON_H)
	_learn_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_learn_button.pressed.connect(_on_learn_ack_pressed)
	_learn_action_row.add_child(_learn_button)

	_learn_show_answer_button = Button.new()
	_learn_show_answer_button.text = "看答案"
	_learn_show_answer_button.tooltip_text = "显示正确拼写；本次按默写未通过处理，不标记「已学」，并影响复习间隔。"
	_learn_show_answer_button.visible = false
	_learn_show_answer_button.custom_minimum_size = Vector2(140, TOUCH_MIN_BUTTON_H)
	_learn_show_answer_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_learn_show_answer_button.pressed.connect(_on_learn_show_answer_pressed)
	_learn_action_row.add_child(_learn_show_answer_button)

	_prompt = RichTextLabel.new()
	_prompt.bbcode_enabled = true
	_prompt.fit_content = true
	_prompt.scroll_active = false
	_prompt.add_theme_font_size_override("normal_font_size", FONT_PROMPT)
	_outer.add_child(_prompt)

	_mc_container = GridContainer.new()
	_mc_container.visible = false
	_mc_container.columns = 2
	_mc_container.add_theme_constant_override("h_separation", 10)
	_mc_container.add_theme_constant_override("v_separation", 10)
	_mc_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outer.add_child(_mc_container)
	for _i in range(4):
		var mb := Button.new()
		mb.visible = false
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.custom_minimum_size = Vector2(200, TOUCH_MIN_BUTTON_H - 4)
		mb.add_theme_font_size_override("font_size", FONT_BUTTON - 1)
		mb.pressed.connect(_on_mc_button_pressed.bind(mb))
		_mc_container.add_child(mb)
		_mc_option_buttons.append(mb)

	_input = LineEdit.new()
	_input.placeholder_text = "输入英文…"
	_input.clear_button_enabled = true
	_input.custom_minimum_size = Vector2(0, TOUCH_LINE_EDIT_H)
	_input.add_theme_font_size_override("font_size", FONT_INPUT)
	_input.virtual_keyboard_enabled = true
	_input.focus_entered.connect(_on_input_focus)
	_input.text_submitted.connect(_on_lineedit_text_submitted)
	_outer.add_child(_input)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	_outer.add_child(hb)

	_submit = Button.new()
	_submit.text = I18N.tr_key("vocab.review.submit")
	_submit.custom_minimum_size = Vector2(140, TOUCH_MIN_BUTTON_H)
	_submit.add_theme_font_size_override("font_size", FONT_BUTTON)
	_submit.pressed.connect(_on_submit)
	hb.add_child(_submit)

	_peek_answer_quiz_button = Button.new()
	_peek_answer_quiz_button.name = "PeekAnswerQuizButton"
	_peek_answer_quiz_button.text = I18N.tr_key("vocab.review.peek_answer")
	_peek_answer_quiz_button.tooltip_text = "显示正确拼写；本次按默写未通过处理，并影响复习间隔。"
	_peek_answer_quiz_button.custom_minimum_size = Vector2(120, TOUCH_MIN_BUTTON_H)
	_peek_answer_quiz_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_peek_answer_quiz_button.pressed.connect(_on_show_answer_quiz_pressed)
	hb.add_child(_peek_answer_quiz_button)

	_skip = Button.new()
	_skip.text = I18N.tr_key("vocab.review.skip")
	_skip.tooltip_text = "跳过学习或默写，本次不出牌"
	_skip.custom_minimum_size = Vector2(140, TOUCH_MIN_BUTTON_H)
	_skip.add_theme_font_size_override("font_size", FONT_BUTTON)
	_skip.pressed.connect(_on_skip_pressed)
	hb.add_child(_skip)

	_relearn_button = Button.new()
	_relearn_button.text = I18N.tr_key("vocab.review.relearn")
	_relearn_button.tooltip_text = I18N.tr_key("vocab.review.relearn_tip")
	_relearn_button.visible = false
	_relearn_button.custom_minimum_size = Vector2(150, TOUCH_MIN_BUTTON_H)
	_relearn_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_relearn_button.pressed.connect(_on_relearn_pressed)
	hb.add_child(_relearn_button)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", FONT_FEEDBACK)
	_outer.add_child(_feedback)

	_return_after_peek_button = Button.new()
	_return_after_peek_button.text = I18N.tr_key("vocab.review.continue")
	_return_after_peek_button.tooltip_text = "确认结果后继续。"
	_return_after_peek_button.visible = false
	_return_after_peek_button.custom_minimum_size = Vector2(200, TOUCH_MIN_BUTTON_H)
	_return_after_peek_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_return_after_peek_button.pressed.connect(_on_return_after_peek_pressed)
	_outer.add_child(_return_after_peek_button)

	if not I18N.locale_changed.is_connected(_on_locale_changed):
		I18N.locale_changed.connect(_on_locale_changed)
	_refresh_i18n()
	_apply_panel_layout()

func _on_locale_changed(_locale: String) -> void:
	_refresh_i18n()

func _refresh_i18n() -> void:
	var rm0: String = VocabStudy.combat_vocab_review_mode()
	_learn_button.text = (
		I18N.tr_key("vocab.review.learn_next_spell")
		if rm0 == VocabStudy.VOCAB_REVIEW_MODE_SPELL
		else I18N.tr_key("vocab.review.learn_next_quiz")
	)
	_learn_show_answer_button.text = I18N.tr_key("vocab.review.peek_answer")
	_submit.text = I18N.tr_key("vocab.review.submit")
	_peek_answer_quiz_button.text = I18N.tr_key("vocab.review.peek_answer")
	_skip.text = I18N.tr_key("vocab.review.learn_skip") if _in_learn_wait else I18N.tr_key("vocab.review.skip")
	_relearn_button.text = I18N.tr_key("vocab.review.relearn")
	_relearn_button.tooltip_text = I18N.tr_key("vocab.review.relearn_tip")
	_return_after_peek_button.text = I18N.tr_key("vocab.review.continue")
	if _input.visible:
		if _quiz_review_mode == VocabStudy.VOCAB_REVIEW_MODE_MEANING:
			_input.placeholder_text = I18N.tr_key("vocab.review.placeholder_meaning")
		else:
			_input.placeholder_text = I18N.tr_key("vocab.review.placeholder_spell")

func _on_viewport_size_changed() -> void:
	if visible:
		_apply_panel_layout()

func _apply_panel_layout() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var side: float = maxf(20.0, vs.x * 0.06)
	var top: float = maxf(24.0, vs.y * 0.04)
	var bottom: float = maxf(24.0, vs.y * 0.04)

	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = side
	_panel.offset_top = top
	_panel.offset_right = -side
	_panel.offset_bottom = -bottom

	var inner_w: float = maxf(280.0, vs.x - side * 2.0 - 32.0)
	_prompt.custom_minimum_size = Vector2(inner_w, 0.0)
	_learn_text.custom_minimum_size = Vector2(inner_w, 0.0)
	_feedback.custom_minimum_size = Vector2(inner_w, 0.0)
	_return_after_peek_button.custom_minimum_size = Vector2(maxf(200.0, inner_w * 0.5), TOUCH_MIN_BUTTON_H)
	var mc_columns := 2 if inner_w >= MC_TWO_COLUMN_MIN_W else 1
	_mc_container.columns = mc_columns
	var mc_w: float = inner_w
	if mc_columns == 2:
		mc_w = (inner_w - 10.0) * 0.5
	for mb: Button in _mc_option_buttons:
		mb.custom_minimum_size = Vector2(maxf(160.0, mc_w), TOUCH_MIN_BUTTON_H - 2)

func _reset_quiz_peek_state() -> void:
	_quiz_peek_answer_shown = false
	_relearn_return_to_quiz = false
	_return_after_peek_button.text = I18N.tr_key("vocab.review.continue")
	_return_after_peek_button.disabled = false
	_return_after_peek_button.visible = false
	_relearn_button.disabled = false
	_relearn_button.visible = false
	_submit.disabled = false
	_peek_answer_quiz_button.disabled = false
	_skip.disabled = false
	_input.editable = true
	for mb: Button in _mc_option_buttons:
		mb.disabled = false

func _on_lineedit_text_submitted(_new_text: String) -> void:
	_on_submit()

func _on_input_focus() -> void:
	_input.select_all()

func _escape_bbcode_user_text(s: String) -> String:
	return s.replace("[", "〔").replace("]", "〕")

func _status_tag_bbcode(label_key: String, color: String = "#d8c27a") -> String:
	return "[color=%s][font_size=%d]%s[/font_size][/color]" % [
		color,
		FONT_EX_SECTION,
		_escape_bbcode_user_text(I18N.tr_key(label_key)),
	]

func _build_learn_panel_bbcode(word: Dictionary) -> String:
	var hw: String = str(word.get("study_headword", ""))
	var mn: String = str(word.get("study_meaning", ""))
	var body: String = (
		"[center]%s\n\n"
		% _status_tag_bbcode("vocab.review.tag_new", "#d8c27a")
		+ "[color=#f2ebe0][font_size=%d]%s[/font_size][/color]\n\n"
		% [FONT_LEARN_HEAD, _escape_bbcode_user_text(hw)]
		+ "[color=#91c59d][font_size=%d]%s[/font_size][/color]\n"
		% [FONT_EX_GLOSS, _escape_bbcode_user_text(I18N.tr_key("vocab.review.learn_meaning_label"))]
		+ "[color=#d4ecd4][font_size=%d]%s[/font_size][/color]"
		% [FONT_LEARN_MEANING, _escape_bbcode_user_text(mn)]
	)
	var ex: String = _format_study_examples_bbcode(word.get("study_examples", null))
	if ex != "":
		body += "\n\n" + ex
	else:
		body += (
			"\n\n[color=#7a8290][font_size=%d]%s[/font_size][/color]"
			% [maxi(11, FONT_EX_ZH), _escape_bbcode_user_text(I18N.tr_key("vocab.no_examples_hint"))]
		)
	body += "[/center]"
	return body

func _format_study_examples_bbcode(raw: Variant) -> String:
	if typeof(raw) != TYPE_ARRAY:
		return ""
	var arr: Array = raw as Array
	if arr.is_empty():
		return ""
	var blocks: PackedStringArray = []
	var idx: int = 1
	for item: Variant in arr:
		if typeof(item) == TYPE_DICTIONARY:
			var d: Dictionary = item as Dictionary
			var sent: String = str(d.get("sentence", "")).strip_edges()
			if sent == "":
				continue
			var gloss: String = str(d.get("gloss", "")).strip_edges()
			var zh: String = str(d.get("sentence_zh", "")).strip_edges()
			var head: String = (
				"[color=#8fa6bc][font_size=%d]%s %d[/font_size][/color] "
				% [FONT_EX_NUM, _escape_bbcode_user_text(I18N.tr_key("vocab.review.example_usage")), idx]
			)
			if gloss != "":
				head += (
					"[color=#8fbc8f][font_size=%d]%s[/font_size][/color]\n"
					% [FONT_EX_GLOSS, _escape_bbcode_user_text(gloss)]
				)
			else:
				head += "\n"
			var blk: String = (
				head
				+ "[color=#d0dce8][font_size=%d]%s[/font_size][/color]"
				% [FONT_EX_SENT, _escape_bbcode_user_text(sent)]
			)
			if zh != "":
				blk += (
					"\n[color=#8a9e92][font_size=%d]译文：%s[/font_size][/color]"
					% [FONT_EX_ZH, _escape_bbcode_user_text(zh)]
				)
			blocks.append(blk)
			idx += 1
		elif typeof(item) == TYPE_STRING:
			var s: String = str(item).strip_edges()
			if s == "":
				continue
			blocks.append(
				(
					"[color=#8fa6bc][font_size=%d]%s %d[/font_size][/color] "
					+ "[color=#d0dce8][font_size=%d]%s[/font_size][/color]"
				)
				% [FONT_EX_NUM, _escape_bbcode_user_text(I18N.tr_key("vocab.review.example_usage")), idx, FONT_EX_SENT, _escape_bbcode_user_text(s)]
			)
			idx += 1
	if blocks.is_empty():
		return ""
	return (
		"[color=#9aa8b6][font_size=%d]%s[/font_size][/color]\n\n%s"
		% [FONT_EX_SECTION, _escape_bbcode_user_text(I18N.tr_key("vocab.review.examples_title")), "\n\n".join(blocks)]
	)


func _plain_prompt_without_answer_leaks(word: Dictionary) -> String:
	var raw := str(word.get("prompt", "")).strip_edges()
	if raw.is_empty():
		return ""
	raw = raw.replace("[center]", "").replace("[/center]", "")
	var blocked: Array[String] = []
	var hw := str(word.get("study_headword", "")).strip_edges().to_lower()
	if hw.length() >= 2:
		blocked.append(hw)
	for a: String in _answers:
		var al := a.strip_edges().to_lower()
		if al.length() >= 2 and not blocked.has(al):
			blocked.append(al)
	var kept: PackedStringArray = []
	for line_raw: String in raw.split("\n"):
		var line := line_raw.strip_edges()
		if line.is_empty():
			continue
		var low := line.to_lower()
		var leaks := false
		for b: String in blocked:
			if low.contains(b):
				leaks = true
				break
		if not leaks:
			kept.append(line)
	return "\n".join(kept)


func _build_meaning_only_quiz_bbcode(word: Dictionary, title_key: String, instruction_key: String = "") -> String:
	var mn: String = str(word.get("study_meaning", "")).strip_edges()
	var bb := "[center]%s\n\n[color=#c8d8e8][font_size=%d]%s[/font_size][/color]" % [
		_status_tag_bbcode("vocab.review.tag_review", "#c7a957"),
		FONT_PROMPT,
		_escape_bbcode_user_text(I18N.tr_key(title_key)),
	]
	if mn != "":
		bb += (
			"\n\n[color=#91c59d][font_size=%d]%s[/font_size][/color]\n"
			% [FONT_EX_GLOSS, _escape_bbcode_user_text(I18N.tr_key("vocab.review.meaning_label"))]
			+ "[color=#dde8f0][font_size=%d]%s[/font_size][/color]"
			% [FONT_LEARN_MEANING + 1, _escape_bbcode_user_text(mn)]
		)
	else:
		var safe_prompt := _plain_prompt_without_answer_leaks(word)
		if safe_prompt != "":
			bb += (
				"\n\n[color=#dde8f0][font_size=%d]%s[/font_size][/color]"
				% [FONT_LEARN_MEANING + 1, _escape_bbcode_user_text(safe_prompt)]
			)
		else:
			bb += (
				"\n\n[color=#aab6c2][font_size=%d]%s[/font_size][/color]"
				% [FONT_EX_ZH, _escape_bbcode_user_text(I18N.tr_key("vocab.review.no_safe_prompt"))]
			)
	if instruction_key != "":
		bb += "\n\n[color=#9aa8b6]%s[/color]" % _escape_bbcode_user_text(I18N.tr_key(instruction_key))
	bb += "\n\n[color=#6f7f90][font_size=%d]%s[/font_size][/color]" % [
		FONT_EX_ZH,
		_escape_bbcode_user_text(I18N.tr_key("vocab.review.quiz_hidden_note")),
	]
	bb += "[/center]"
	return bb


func _format_review_delay(hours: float) -> String:
	if hours < 1.5:
		return I18N.tr_key("vocab.review.time_hour", [1])
	if hours < 36.0:
		return I18N.tr_key("vocab.review.time_hours", [int(round(hours))])
	return I18N.tr_key("vocab.review.time_days", [maxi(1, int(round(hours / 24.0)))])


func _next_review_line(correct: bool) -> String:
	var h := VocabStudy.preview_next_review_hours(_word_id, correct)
	return I18N.tr_key("vocab.review.next_review", [_format_review_delay(h)])


func _mc_choice_matches_answer(choice_lower: String) -> bool:
	for a: String in _answers:
		if choice_lower == a:
			return true
	return false


func _on_mc_button_pressed(b: Button) -> void:
	if _finished or _quiz_peek_answer_shown or not b.visible:
		return
	var typed: String = _normalize(b.text)
	_last_answer_text = b.text
	if _mc_choice_matches_answer(typed):
		_finish(true)
		return
	_quiz_wrong_submits += 1
	if _quiz_wrong_submits >= MAX_WRONG_ATTEMPTS_IN_QUIZ:
		_finish(false, REVIEW_OUTCOME_WRONG)
		return
	var left: int = MAX_WRONG_ATTEMPTS_IN_QUIZ - _quiz_wrong_submits
	_feedback.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55, 1.0))
	_feedback.text = I18N.tr_key("vocab.review.mc_try_again", [left])


func _setup_spelling_quiz_prompt(word: Dictionary) -> void:
	_prompt.text = _build_meaning_only_quiz_bbcode(
		word,
		"vocab.review.spell_label",
		"vocab.review.spell_instruction"
	)


func _setup_meaning_quiz_prompt(word: Dictionary) -> void:
	_prompt.text = _build_meaning_only_quiz_bbcode(
		word,
		"vocab.review.meaning_hide_hint",
		"vocab.review.meaning_instruction"
	)


func _setup_mc_quiz_prompt(word: Dictionary) -> void:
	_prompt.text = _build_meaning_only_quiz_bbcode(word, "vocab.review.mc_pick_label")


func _build_mc_options(word: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var acc: Array = []
	for a: String in _answers:
		acc.append(a)
	var distr: Array[String] = VocabStudy.sample_distractor_headwords_for_mc(_word_id, acc, 3, rng)
	var correct_label := str(word.get("study_headword", "")).strip_edges()
	if correct_label.is_empty() and not _answers.is_empty():
		correct_label = _answers[0]
	var labels: Array[String] = []
	for s: String in distr:
		labels.append(s)
	labels.append(correct_label)
	for i in range(labels.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = labels[i]
		labels[i] = labels[j]
		labels[j] = tmp
	for k in range(_mc_option_buttons.size()):
		var btn: Button = _mc_option_buttons[k]
		if k < labels.size():
			btn.text = labels[k]
			btn.visible = true
			btn.disabled = false
		else:
			btn.visible = false


func _apply_quiz_mode_layout(word: Dictionary) -> void:
	_quiz_review_mode = VocabStudy.combat_vocab_review_mode()
	match _quiz_review_mode:
		VocabStudy.VOCAB_REVIEW_MODE_MEANING:
			_mc_container.visible = false
			_input.visible = true
			_submit.visible = true
			_input.placeholder_text = I18N.tr_key("vocab.review.placeholder_meaning")
			_setup_meaning_quiz_prompt(word)
		VocabStudy.VOCAB_REVIEW_MODE_MC4:
			_mc_container.visible = true
			_input.visible = false
			_submit.visible = false
			_setup_mc_quiz_prompt(word)
			_build_mc_options(word)
		_:
			_quiz_review_mode = VocabStudy.VOCAB_REVIEW_MODE_SPELL
			_mc_container.visible = false
			_input.visible = true
			_submit.visible = true
			_input.placeholder_text = I18N.tr_key("vocab.review.placeholder_spell")
			_setup_spelling_quiz_prompt(word)


func run_review(word: Dictionary) -> int:
	_finished = false
	_result_ok = false
	_review_outcome = REVIEW_OUTCOME_OK
	_quiz_wrong_submits = 0
	_word_id = str(word.get("id", ""))
	_active_word = word
	_answers.clear()
	_last_answer_text = ""
	for a: Variant in word.get("answers", []):
		_answers.append(str(a).strip_edges().to_lower())
	_feedback.text = ""
	_feedback.add_theme_color_override("font_color", Color(0.84, 0.88, 0.92, 1.0))
	_input.text = ""
	_refresh_i18n()

	VocabStudy.merge_disk_and_pool_examples_into_word(word)
	_active_word = word

	var need_learn: bool = VocabStudy.word_needs_learn_phase(_word_id)
	_apply_panel_layout()
	visible = true

	var fetching_examples: bool = (
		need_learn
		and VocabStudy.has_openai_configured()
		and (
			not VocabStudy.word_has_nonempty_examples(word)
			or VocabStudy.word_study_examples_need_zh_refresh(word)
		)
	)
	if fetching_examples:
		_learn_panel.visible = false
		_prompt.visible = false
		_input.visible = false
		_submit.visible = false
		_peek_answer_quiz_button.visible = false
		_skip.visible = false
		_return_after_peek_button.visible = false
		_feedback.visible = true
		_feedback.text = I18N.tr_key("vocab.fetching_examples")
		await get_tree().process_frame
		await VocabStudy.ensure_examples_for_word_on_demand_async(word)
		_active_word = word
		_feedback.text = ""
		_feedback.visible = false
		_skip.visible = true

	if need_learn:
		_learn_show_answer_busy = false
		var rm0: String = VocabStudy.combat_vocab_review_mode()
		_learn_button.text = (
			I18N.tr_key("vocab.review.learn_next_spell")
			if rm0 == VocabStudy.VOCAB_REVIEW_MODE_SPELL
			else I18N.tr_key("vocab.review.learn_next_quiz")
		)
		_learn_text.text = _build_learn_panel_bbcode(word)
		_learn_panel.visible = true
		_learn_action_row.visible = true
		_learn_show_answer_button.visible = false
		_prompt.visible = false
		_input.visible = false
		_submit.visible = false
		_peek_answer_quiz_button.visible = false
		_return_after_peek_button.visible = false
		_relearn_button.visible = false
		_feedback.visible = false
		_skip.text = I18N.tr_key("vocab.review.learn_skip")
		_in_learn_wait = true
		var learn_exit: int = await _learn_resolved
		_in_learn_wait = false
		if learn_exit == LEARN_EXIT_SKIP:
			_cleanup_hide()
			return REVIEW_OUTCOME_SKIPPED
		if learn_exit == LEARN_EXIT_PEEK_WRONG:
			_cleanup_hide()
			return REVIEW_OUTCOME_WRONG
		if _finished:
			_cleanup_hide()
			return REVIEW_OUTCOME_OK if _result_ok else REVIEW_OUTCOME_SKIPPED
		VocabStudy.mark_word_introduced(_word_id)
		_learn_panel.visible = false
		_quiz_wrong_submits = 0

	_reset_quiz_peek_state()
	_skip.text = I18N.tr_key("vocab.review.skip")
	_relearn_button.disabled = false
	_relearn_button.visible = true
	_prompt.visible = true
	_peek_answer_quiz_button.visible = true
	_feedback.visible = true
	_apply_quiz_mode_layout(word)
	await get_tree().process_frame
	if _input.visible:
		_input.grab_focus()
	await review_completed
	if _review_outcome == REVIEW_OUTCOME_OK:
		VocabStudy.mark_word_learned(_word_id)
	_cleanup_hide()
	return _review_outcome

func _on_learn_ack_pressed() -> void:
	if not visible or not _learn_panel.visible:
		return
	_learn_resolved.emit(LEARN_EXIT_PROCEED)

func _on_learn_show_answer_pressed() -> void:
	if not visible or not _learn_panel.visible or not _in_learn_wait or _learn_show_answer_busy:
		return
	_learn_show_answer_busy = true
	var parts: PackedStringArray = []
	for a: String in _answers:
		parts.append(a)
	var joined: String = " / ".join(parts)
	_learn_text.text = _learn_text.text + "\n\n[center][color=#ffb0a0]正确答案：%s[/color][/center]" % joined
	await get_tree().process_frame
	_learn_resolved.emit(LEARN_EXIT_PEEK_WRONG)

func _on_show_answer_quiz_pressed() -> void:
	if _finished or _quiz_peek_answer_shown:
		return
	if _quiz_review_mode != VocabStudy.VOCAB_REVIEW_MODE_MC4 and not _input.visible:
		return
	_quiz_peek_answer_shown = true
	var parts: PackedStringArray = []
	for a: String in _answers:
		parts.append(a)
	var joined: String = " / ".join(parts)
	_last_answer_text = I18N.tr_key("vocab.review.answer_peek")
	_feedback.text = I18N.tr_key("vocab.review.peek_quiz_feedback", [joined, _next_review_line(false)])
	_submit.disabled = true
	_peek_answer_quiz_button.disabled = true
	_skip.disabled = true
	_relearn_button.disabled = true
	_input.editable = false
	for mb: Button in _mc_option_buttons:
		mb.disabled = true
	_return_after_peek_button.visible = true

func _on_return_after_peek_pressed() -> void:
	if _relearn_return_to_quiz:
		_relearn_return_to_quiz = false
		_learn_panel.visible = false
		_learn_action_row.visible = true
		_return_after_peek_button.disabled = false
		_return_after_peek_button.visible = false
		_prompt.visible = true
		_feedback.visible = true
		_peek_answer_quiz_button.visible = true
		_skip.visible = true
		_submit.disabled = false
		_peek_answer_quiz_button.disabled = false
		_skip.disabled = false
		_relearn_button.disabled = false
		_relearn_button.visible = true
		_input.editable = true
		for mb: Button in _mc_option_buttons:
			mb.disabled = false
		_apply_quiz_mode_layout(_active_word)
		await get_tree().process_frame
		if _input.visible:
			_input.grab_focus()
		return
	if _finished:
		_return_after_peek_button.disabled = true
		review_completed.emit(_result_ok)
		return
	if _quiz_peek_answer_shown:
		_return_after_peek_button.disabled = true
		_finish(false, REVIEW_OUTCOME_WRONG, false)


func _on_relearn_pressed() -> void:
	if not visible or _quiz_peek_answer_shown or _active_word.is_empty():
		return
	_relearn_return_to_quiz = not _finished
	_relearn_button.disabled = true
	if _relearn_return_to_quiz:
		_submit.disabled = true
		_peek_answer_quiz_button.disabled = true
		_skip.disabled = true
		_input.editable = false
		for mb: Button in _mc_option_buttons:
			mb.disabled = true
	_feedback.visible = true
	VocabStudy.merge_disk_and_pool_examples_into_word(_active_word)
	var needs_examples: bool = (
		not VocabStudy.word_has_nonempty_examples(_active_word)
		or VocabStudy.word_study_examples_need_zh_refresh(_active_word)
	)
	if needs_examples and VocabStudy.has_openai_configured():
		_feedback.text = I18N.tr_key("vocab.fetching_examples")
		await get_tree().process_frame
		await VocabStudy.ensure_examples_for_word_on_demand_async(_active_word)
		VocabStudy.merge_disk_and_pool_examples_into_word(_active_word)
	_feedback.text = ""
	_feedback.visible = false
	_learn_text.text = _build_learn_panel_bbcode(_active_word)
	_learn_panel.visible = true
	_learn_action_row.visible = false
	_prompt.visible = false
	_input.visible = false
	_submit.visible = false
	_peek_answer_quiz_button.visible = false
	_skip.visible = false
	_relearn_button.visible = false
	_mc_container.visible = false
	_return_after_peek_button.text = I18N.tr_key("vocab.review.continue")
	_return_after_peek_button.disabled = false
	_return_after_peek_button.visible = true

func _on_skip_pressed() -> void:
	if _in_learn_wait:
		_learn_resolved.emit(LEARN_EXIT_SKIP)
		return
	_finish(false, REVIEW_OUTCOME_SKIPPED, false)

func _cleanup_hide() -> void:
	_input.release_focus()
	visible = false
	_learn_panel.visible = false
	_learn_action_row.visible = true
	_active_word = {}
	_relearn_return_to_quiz = false
	_relearn_button.visible = false
	if _mc_container:
		_mc_container.visible = false
	_reset_quiz_peek_state()

func _normalize(s: String) -> String:
	return s.strip_edges().to_lower()

func _on_submit() -> void:
	if _finished:
		return
	if _quiz_peek_answer_shown:
		return
	if not _input.visible:
		return
	if _answers.is_empty():
		_finish(false, REVIEW_OUTCOME_WRONG)
		return
	var typed: String = _normalize(_input.text)
	_last_answer_text = typed
	for a: String in _answers:
		if typed == a:
			_finish(true)
			return
	_quiz_wrong_submits += 1
	if _quiz_wrong_submits >= MAX_WRONG_ATTEMPTS_IN_QUIZ:
		_finish(false, REVIEW_OUTCOME_WRONG)
		return
	var left: int = MAX_WRONG_ATTEMPTS_IN_QUIZ - _quiz_wrong_submits
	_feedback.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55, 1.0))
	_feedback.text = I18N.tr_key("vocab.review.try_again", [left])

func _finish(ok: bool, outcome_on_fail: int = REVIEW_OUTCOME_WRONG, wait_for_ack: bool = true) -> void:
	if _finished:
		return
	_finished = true
	_result_ok = ok
	_review_outcome = REVIEW_OUTCOME_OK if ok else outcome_on_fail

	# Record word review statistics
	Global.player_data.add_word_review(ok)

	if wait_for_ack:
		_show_final_feedback()
	else:
		review_completed.emit(ok)


func _show_final_feedback() -> void:
	var parts: PackedStringArray = []
	for a: String in _answers:
		parts.append(a)
	var joined: String = " / ".join(parts)
	var user_answer := _last_answer_text.strip_edges()
	if user_answer.is_empty():
		user_answer = I18N.tr_key("vocab.review.no_answer")
	var next_line := _next_review_line(_review_outcome == REVIEW_OUTCOME_OK)
	if _review_outcome == REVIEW_OUTCOME_OK:
		_feedback.add_theme_color_override("font_color", Color(0.77, 0.92, 0.72, 1.0))
		_feedback.text = I18N.tr_key("vocab.review.correct_feedback", [user_answer, joined, next_line])
	else:
		_feedback.add_theme_color_override("font_color", Color(1.0, 0.74, 0.58, 1.0))
		_feedback.text = I18N.tr_key("vocab.review.wrong_feedback", [user_answer, joined, next_line])
	_submit.disabled = true
	_peek_answer_quiz_button.disabled = true
	_skip.disabled = true
	_relearn_button.disabled = false
	_relearn_button.visible = true
	_input.editable = false
	for mb: Button in _mc_option_buttons:
		mb.disabled = true
	_return_after_peek_button.text = I18N.tr_key("vocab.review.continue")
	_return_after_peek_button.visible = true
