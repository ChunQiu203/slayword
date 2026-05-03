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
## 默写阶段允许连续提交错误答案的次数（不含「跳过」）；避免无限试错直到蒙对。
const MAX_WRONG_ATTEMPTS_IN_QUIZ := 5

var _panel: PanelContainer
var _outer: VBoxContainer
var _learn_panel: VBoxContainer
var _learn_text: RichTextLabel
var _learn_button: Button
var _learn_show_answer_button: Button
var _prompt: RichTextLabel
var _input: LineEdit
var _feedback: Label
var _submit: Button
var _peek_answer_quiz_button: Button
var _skip: Button
var _return_after_peek_button: Button
## 默写阶段已点「看答案」，等待用户点「返回」再结束（便于阅读答案）。
var _quiz_peek_answer_shown: bool = false
var _finished: bool = false
var _result_ok: bool = false
var _review_outcome: int = REVIEW_OUTCOME_OK
var _quiz_wrong_submits: int = 0
var _answers: Array[String] = []
var _word_id: String = ""
var _in_learn_wait: bool = false
var _learn_show_answer_busy: bool = false
## 默写阶段题型（与 VocabStudy.combat_vocab_review_mode 一致）
var _quiz_review_mode: String = VocabStudy.VOCAB_REVIEW_MODE_SPELL
var _mc_container: VBoxContainer
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
	panel_sb.border_color = Color(0.38, 0.48, 0.58, 0.85)
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

	var learn_row := HBoxContainer.new()
	learn_row.add_theme_constant_override("separation", 12)
	learn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_learn_panel.add_child(learn_row)

	_learn_button = Button.new()
	_learn_button.text = "记住了，开始默写"
	_learn_button.custom_minimum_size = Vector2(200, TOUCH_MIN_BUTTON_H)
	_learn_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_learn_button.pressed.connect(_on_learn_ack_pressed)
	learn_row.add_child(_learn_button)

	_learn_show_answer_button = Button.new()
	_learn_show_answer_button.text = "看答案"
	_learn_show_answer_button.tooltip_text = "显示正确拼写；本次按默写未通过处理，不标记「已学」，并影响复习间隔。"
	_learn_show_answer_button.custom_minimum_size = Vector2(140, TOUCH_MIN_BUTTON_H)
	_learn_show_answer_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_learn_show_answer_button.pressed.connect(_on_learn_show_answer_pressed)
	learn_row.add_child(_learn_show_answer_button)

	_prompt = RichTextLabel.new()
	_prompt.bbcode_enabled = true
	_prompt.fit_content = true
	_prompt.scroll_active = false
	_prompt.add_theme_font_size_override("normal_font_size", FONT_PROMPT)
	_outer.add_child(_prompt)

	_mc_container = VBoxContainer.new()
	_mc_container.visible = false
	_mc_container.add_theme_constant_override("separation", 10)
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
	_submit.text = "提交"
	_submit.custom_minimum_size = Vector2(140, TOUCH_MIN_BUTTON_H)
	_submit.add_theme_font_size_override("font_size", FONT_BUTTON)
	_submit.pressed.connect(_on_submit)
	hb.add_child(_submit)

	_peek_answer_quiz_button = Button.new()
	_peek_answer_quiz_button.name = "PeekAnswerQuizButton"
	_peek_answer_quiz_button.text = "看答案"
	_peek_answer_quiz_button.tooltip_text = "显示正确拼写；本次按默写未通过处理，并影响复习间隔。"
	_peek_answer_quiz_button.custom_minimum_size = Vector2(120, TOUCH_MIN_BUTTON_H)
	_peek_answer_quiz_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_peek_answer_quiz_button.pressed.connect(_on_show_answer_quiz_pressed)
	hb.add_child(_peek_answer_quiz_button)

	_skip = Button.new()
	_skip.text = "跳过"
	_skip.tooltip_text = "跳过学习或默写，本次不出牌"
	_skip.custom_minimum_size = Vector2(140, TOUCH_MIN_BUTTON_H)
	_skip.add_theme_font_size_override("font_size", FONT_BUTTON)
	_skip.pressed.connect(_on_skip_pressed)
	hb.add_child(_skip)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", FONT_FEEDBACK)
	_outer.add_child(_feedback)

	_return_after_peek_button = Button.new()
	_return_after_peek_button.text = "返回"
	_return_after_peek_button.tooltip_text = "确认后结束默写；本次按未通过处理。"
	_return_after_peek_button.visible = false
	_return_after_peek_button.custom_minimum_size = Vector2(200, TOUCH_MIN_BUTTON_H)
	_return_after_peek_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_return_after_peek_button.pressed.connect(_on_return_after_peek_pressed)
	_outer.add_child(_return_after_peek_button)

	_apply_panel_layout()

func _on_viewport_size_changed() -> void:
	if visible:
		_apply_panel_layout()

func _apply_panel_layout() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var side: float = maxf(20.0, vs.x * 0.06)
	var top: float = maxf(36.0, vs.y * 0.06)
	var reserve_bottom: float = clampf(vs.y * 0.38, 200.0, 420.0)

	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = side
	_panel.offset_top = top
	_panel.offset_right = -side
	_panel.offset_bottom = -reserve_bottom

	var inner_w: float = maxf(280.0, vs.x - side * 2.0 - 32.0)
	_prompt.custom_minimum_size = Vector2(inner_w, 0.0)
	_learn_text.custom_minimum_size = Vector2(inner_w, 0.0)
	_feedback.custom_minimum_size = Vector2(inner_w, 0.0)
	_return_after_peek_button.custom_minimum_size = Vector2(maxf(200.0, inner_w * 0.5), TOUCH_MIN_BUTTON_H)
	for mb: Button in _mc_option_buttons:
		mb.custom_minimum_size = Vector2(maxf(200.0, inner_w - 8.0), TOUCH_MIN_BUTTON_H - 2)

func _reset_quiz_peek_state() -> void:
	_quiz_peek_answer_shown = false
	_return_after_peek_button.visible = false
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

func _build_learn_panel_bbcode(word: Dictionary) -> String:
	var hw: String = str(word.get("study_headword", ""))
	var mn: String = str(word.get("study_meaning", ""))
	var body: String = (
		"[center][color=#f2ebe0][font_size=%d]%s[/font_size][/color]\n\n"
		% [FONT_LEARN_HEAD, _escape_bbcode_user_text(hw)]
		+ "[color=#b8c8b8][font_size=%d]中文释义：[/font_size][color=#d4ecd4][font_size=%d]%s[/font_size]"
		% [FONT_LEARN_MEANING, FONT_LEARN_MEANING, _escape_bbcode_user_text(mn)]
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
				"[color=#8fa6bc][font_size=%d]%d.[/font_size][/color] "
				% [FONT_EX_NUM, idx]
			)
			if gloss != "":
				head += (
					"[color=#8fbc8f][font_size=%d]%s[/font_size]\n"
					% [FONT_EX_GLOSS, _escape_bbcode_user_text(gloss)]
				)
			else:
				head += "\n"
			var blk: String = (
				head
				+ "[color=#d0dce8][font_size=%d]%s[/font_size]"
				% [FONT_EX_SENT, _escape_bbcode_user_text(sent)]
			)
			if zh != "":
				blk += (
					"\n[color=#8a9e92][font_size=%d]译文：%s[/font_size]"
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
					"[color=#8fa6bc][font_size=%d]%d.[/font_size][/color] "
					+ "[color=#d0dce8][font_size=%d]%s[/font_size]"
				)
				% [FONT_EX_NUM, idx, FONT_EX_SENT, _escape_bbcode_user_text(s)]
			)
			idx += 1
	if blocks.is_empty():
		return ""
	return (
		"[color=#9aa8b6][font_size=%d]例句[/font_size][/color]\n\n%s"
		% [FONT_EX_SECTION, "\n\n".join(blocks)]
	)


func _mc_choice_matches_answer(choice_lower: String) -> bool:
	for a: String in _answers:
		if choice_lower == a:
			return true
	return false


func _on_mc_button_pressed(b: Button) -> void:
	if _finished or _quiz_peek_answer_shown or not b.visible:
		return
	var typed: String = _normalize(b.text)
	if _mc_choice_matches_answer(typed):
		_finish(true)
		return
	_quiz_wrong_submits += 1
	if _quiz_wrong_submits >= MAX_WRONG_ATTEMPTS_IN_QUIZ:
		_feedback.text = I18N.tr_key("vocab.review.mc_wrong_cap")
		_finish(false, REVIEW_OUTCOME_WRONG)
		return
	var left: int = MAX_WRONG_ATTEMPTS_IN_QUIZ - _quiz_wrong_submits
	_feedback.text = I18N.tr_key("vocab.review.mc_try_again", [left])


func _setup_spelling_quiz_prompt(word: Dictionary) -> void:
	var ex_quiz: String = _format_study_examples_bbcode(word.get("study_examples", null))
	var quiz_prompt_bb: String = "[center]" + str(word.get("prompt", ""))
	if ex_quiz != "":
		quiz_prompt_bb += "\n\n" + ex_quiz
	else:
		quiz_prompt_bb += (
			"\n\n[color=#7a8290][font_size=%d]%s[/font_size]"
			% [maxi(11, FONT_EX_ZH), _escape_bbcode_user_text(I18N.tr_key("vocab.no_examples_hint"))]
		)
	quiz_prompt_bb += "[/center]"
	_prompt.text = quiz_prompt_bb


func _setup_meaning_quiz_prompt(word: Dictionary) -> void:
	var mn: String = str(word.get("study_meaning", "")).strip_edges()
	var ex_quiz: String = _format_study_examples_bbcode(word.get("study_examples", null))
	var hint := "[color=#8a9aaf]%s[/color]" % _escape_bbcode_user_text(I18N.tr_key("vocab.review.meaning_hide_hint"))
	var bb := "[center]" + hint
	if mn != "":
		bb += (
			"\n\n[color=#dde8f0][font_size=%d]%s[/font_size]"
			% [FONT_LEARN_MEANING + 1, _escape_bbcode_user_text(mn)]
		)
	if ex_quiz != "":
		bb += "\n\n" + ex_quiz
	else:
		bb += (
			"\n\n[color=#7a8290][font_size=%d]%s[/font_size]"
			% [maxi(11, FONT_EX_ZH), _escape_bbcode_user_text(I18N.tr_key("vocab.no_examples_hint"))]
		)
	bb += "\n\n[color=#9aa8b6]%s[/color][/center]" % _escape_bbcode_user_text(I18N.tr_key("vocab.review.meaning_instruction"))
	_prompt.text = bb


func _setup_mc_quiz_prompt(word: Dictionary) -> void:
	var mn: String = str(word.get("study_meaning", "")).strip_edges()
	var ex_quiz: String = _format_study_examples_bbcode(word.get("study_examples", null))
	var bb := "[center][color=#c8d8e8]%s[/color]" % _escape_bbcode_user_text(I18N.tr_key("vocab.review.mc_pick_label"))
	if mn != "":
		bb += (
			"\n\n[color=#dde8f0][font_size=%d]%s[/font_size]"
			% [FONT_LEARN_MEANING + 1, _escape_bbcode_user_text(mn)]
		)
	if ex_quiz != "":
		bb += "\n\n" + ex_quiz
	else:
		bb += (
			"\n\n[color=#7a8290][font_size=%d]%s[/font_size]"
			% [maxi(11, FONT_EX_ZH), _escape_bbcode_user_text(I18N.tr_key("vocab.no_examples_hint"))]
		)
	bb += "[/center]"
	_prompt.text = bb


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
	_answers.clear()
	for a: Variant in word.get("answers", []):
		_answers.append(str(a).strip_edges().to_lower())
	_feedback.text = ""
	_input.text = ""

	VocabStudy.merge_disk_and_pool_examples_into_word(word)

	var need_learn: bool = VocabStudy.word_needs_learn_phase(_word_id)
	_apply_panel_layout()
	visible = true

	var fetching_examples: bool = (
		VocabStudy.has_openai_configured()
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
		_prompt.visible = false
		_input.visible = false
		_submit.visible = false
		_peek_answer_quiz_button.visible = false
		_return_after_peek_button.visible = false
		_feedback.visible = false
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
		VocabStudy.mark_word_learned(_word_id)
		_learn_panel.visible = false
		_quiz_wrong_submits = 0

	_reset_quiz_peek_state()
	_prompt.visible = true
	_peek_answer_quiz_button.visible = true
	_feedback.visible = true
	_apply_quiz_mode_layout(word)
	await get_tree().process_frame
	if _input.visible:
		_input.grab_focus()
	await review_completed
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
	_feedback.text = I18N.tr_key("vocab.review.peek_quiz_feedback", [joined])
	_submit.disabled = true
	_peek_answer_quiz_button.disabled = true
	_skip.disabled = true
	_input.editable = false
	for mb: Button in _mc_option_buttons:
		mb.disabled = true
	_return_after_peek_button.visible = true

func _on_return_after_peek_pressed() -> void:
	if not _quiz_peek_answer_shown or _finished:
		return
	_finish(false, REVIEW_OUTCOME_WRONG)

func _on_skip_pressed() -> void:
	if _in_learn_wait:
		_learn_resolved.emit(LEARN_EXIT_SKIP)
		return
	_finish(false, REVIEW_OUTCOME_SKIPPED)

func _cleanup_hide() -> void:
	_input.release_focus()
	visible = false
	_learn_panel.visible = false
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
	for a: String in _answers:
		if typed == a:
			_finish(true)
			return
	_quiz_wrong_submits += 1
	if _quiz_wrong_submits >= MAX_WRONG_ATTEMPTS_IN_QUIZ:
		_feedback.text = "已达本题错误次数上限，将按答错处理（可点跳过放弃本张牌）。"
		_finish(false, REVIEW_OUTCOME_WRONG)
		return
	var left: int = MAX_WRONG_ATTEMPTS_IN_QUIZ - _quiz_wrong_submits
	_feedback.text = "不对，再试一次或点跳过。（还可试 %d 次）" % left

func _finish(ok: bool, outcome_on_fail: int = REVIEW_OUTCOME_WRONG) -> void:
	if _finished:
		return
	_finished = true
	_result_ok = ok
	_review_outcome = REVIEW_OUTCOME_OK if ok else outcome_on_fail
	review_completed.emit(ok)
