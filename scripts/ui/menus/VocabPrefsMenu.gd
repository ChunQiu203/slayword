# Standalone "Study & word lists" preferences menu.
# Sibling of MainMenu / NewRunMenu / CodexMenu under TitleScreen.
extends Control

@onready var title_screen: Control = $%TitleScreen
@onready var title_label: Label = $Label
@onready var back_button: Button = $BackButton

const _DOMAIN_PRESET_IDS: Array[String] = [
	"film_tv",
	"anime",
	"exam_style",
	"daily",
	"news",
	"game_scifi",
]

const _PANEL_BG := Color(0.06, 0.07, 0.09, 0.95)
const _PANEL_BG_LIGHT := Color(0.10, 0.11, 0.13, 0.96)
const _PANEL_BG_PRESSED := Color(0.04, 0.05, 0.07, 0.95)
const _BORDER_DIM := Color(0.45, 0.39, 0.27, 1.0)
const _BORDER_BRIGHT := Color(0.765, 0.663, 0.376, 1.0)
const _TXT_PRIMARY := Color(0.96, 0.93, 0.82, 1.0)
const _TXT_HOVER := Color(1.0, 0.95, 0.78, 1.0)
const _TXT_SUBTITLE := Color(0.92, 0.82, 0.55, 1.0)
const _TXT_HINT := Color(0.78, 0.78, 0.72, 0.85)
const _TXT_OUTLINE := Color(0.0, 0.0, 0.0, 0.6)
const _STATUS_OK := Color(0.78, 0.92, 0.8, 1.0)
const _SECTION_TODAY := "today"
const _SECTION_BOOKS := "books"
const _SECTION_QUIZ := "quiz"
const _SECTION_EXAMPLES := "examples"

const _VOCAB_LEARN_STEP_IDS: Array[String] = ["en2zh", "zh2en", "spell", "dictation"]
const _VOCAB_REVIEW_MODE_IDS: Array[String] = ["spell", "meaning", "mc4", "recall"]

var _dashboard_grid: GridContainer
var _console_summary: Label
var _section_id_to_button: Dictionary[String, Button] = {}
var _section_id_to_panel: Dictionary[String, PanelContainer] = {}
var _active_section_id: String = _SECTION_TODAY
var _today_title: Label
var _today_status: Label
var _books_title: Label
var _books_status: Label
var _quiz_title: Label
var _quiz_status: Label
var _examples_title: Label
var _examples_status: Label
var _vocab_daily_label: Label
var _vocab_daily_hint: Label
var _vocab_daily_spin: SpinBox
var _vocab_daily_new_label: Label
var _vocab_daily_new_hint: Label
var _vocab_daily_new_spin: SpinBox
var _vocab_ord_label: Label
var _vocab_ord_hint: Label
var _vocab_ord_spin: SpinBox
var _vocab_learn_steps_label: Label
var _vocab_learn_steps_hint: Label
var _vocab_learn_steps_flow: FlowContainer
var _learn_step_id_to_checkbox: Dictionary[String, CheckBox] = {}
var _vocab_review_modes_label: Label
var _vocab_review_modes_flow: FlowContainer
var _review_mode_id_to_checkbox: Dictionary[String, CheckBox] = {}
var _vocab_review_modes_hint: Label
var _vocab_mode_label: Label
var _vocab_mode_option: OptionButton
var _vocab_mode_hint: Label
var _vocab_style_sub: Label
var _vocab_custom_label: Label
var _preset_id_to_checkbox: Dictionary[String, CheckBox] = {}
var _vocab_custom_domain: LineEdit
var _vocab_books_sub: Label
var _vocab_books_box: VBoxContainer
var _book_id_to_checkbox: Dictionary[String, CheckBox] = {}
var _vocab_import_btn: Button
var _vocab_import_status: Label
var _file_dialog: FileDialog
var _delete_confirm_dialog: AcceptDialog
var _pending_delete_book_id: String = ""


func _ready() -> void:
	for legacy in back_button.get_children():
		if legacy.name == "LocalizedTextLabel":
			legacy.queue_free()
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_button.add_theme_font_size_override("font_size", 20)
	back_button.add_theme_color_override("font_color", _TXT_PRIMARY)
	back_button.add_theme_color_override("font_outline_color", _TXT_OUTLINE)
	back_button.add_theme_constant_override("outline_size", 1)

	back_button.pressed.connect(_on_back_button_up)
	I18N.locale_changed.connect(_on_locale_changed)

	_delete_confirm_dialog = AcceptDialog.new()
	_delete_confirm_dialog.title = ""
	_delete_confirm_dialog.dialog_text = ""
	_delete_confirm_dialog.confirmed.connect(_on_delete_confirmed)
	add_child(_delete_confirm_dialog)

	_build_vocab_study_prefs()
	_apply_localized_text()


func populate_vocab_prefs_menu() -> void:
	if _vocab_import_status:
		_vocab_import_status.text = ""
	_sync_vocab_study_prefs_from_settings()
	_rebuild_vocab_book_rows()
	_apply_localized_text()
	_refresh_dashboard_stats()


func _on_back_button_up() -> void:
	title_screen.show_main_menu()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()


func _apply_localized_text() -> void:
	title_label.text = I18N.tr_key("menu.vocab_prefs_title")
	back_button.text = I18N.tr_key("menu.back")
	_refresh_vocab_study_prefs_i18n()


# ---------- Style helpers ----------

func _make_panel_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _PANEL_BG
	sb.border_color = _BORDER_DIM
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 6)
	return sb


func _make_input_stylebox(focus: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _PANEL_BG_LIGHT
	sb.border_color = _BORDER_BRIGHT if focus else _BORDER_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _make_pressed_stylebox() -> StyleBoxFlat:
	var sb := _make_input_stylebox(true)
	sb.bg_color = _PANEL_BG_PRESSED
	return sb


func _make_tab_selected_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.14, 0.16, 0.98)
	sb.border_color = _BORDER_BRIGHT
	sb.border_width_top = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 0
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _make_tab_unselected_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.10, 0.92)
	sb.border_color = _BORDER_DIM
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 0
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _style_tab_container(tabs: TabContainer) -> void:
	tabs.add_theme_stylebox_override("panel", _make_panel_stylebox())
	tabs.add_theme_stylebox_override("tab_selected", _make_tab_selected_stylebox())
	tabs.add_theme_stylebox_override("tab_unselected", _make_tab_unselected_stylebox())
	tabs.add_theme_stylebox_override("tab_disabled", _make_tab_unselected_stylebox())
	tabs.add_theme_stylebox_override("tab_focus", _make_tab_selected_stylebox())
	tabs.add_theme_color_override("font_selected_color", _TXT_PRIMARY)
	tabs.add_theme_color_override("font_unselected_color", _TXT_HINT)
	tabs.add_theme_color_override("font_outline_color", _TXT_OUTLINE)
	tabs.add_theme_constant_override("outline_size", 1)
	tabs.add_theme_font_size_override("font_size", 18)
	tabs.tab_alignment = TabBar.ALIGNMENT_CENTER


func _style_button_warm(btn: BaseButton) -> void:
	btn.add_theme_color_override("font_color", _TXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", _TXT_HOVER)
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.80, 0.65, 1.0))
	btn.add_theme_color_override("font_focus_color", _TXT_HOVER)
	btn.add_theme_color_override("font_outline_color", _TXT_OUTLINE)
	btn.add_theme_constant_override("outline_size", 1)
	btn.add_theme_stylebox_override("normal", _make_input_stylebox(false))
	btn.add_theme_stylebox_override("hover", _make_input_stylebox(true))
	btn.add_theme_stylebox_override("pressed", _make_pressed_stylebox())
	btn.add_theme_stylebox_override("focus", _make_input_stylebox(true))
	btn.add_theme_stylebox_override("disabled", _make_input_stylebox(false))


func _style_check_box(cb: CheckBox) -> void:
	cb.add_theme_color_override("font_color", _TXT_PRIMARY)
	cb.add_theme_color_override("font_hover_color", _TXT_HOVER)
	cb.add_theme_color_override("font_pressed_color", _TXT_PRIMARY)
	cb.add_theme_color_override("font_focus_color", _TXT_PRIMARY)
	cb.add_theme_color_override("font_outline_color", _TXT_OUTLINE)
	cb.add_theme_constant_override("outline_size", 1)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.15, 0.19, 0.55)
	sb.border_color = _BORDER_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	cb.add_theme_stylebox_override("normal", sb)
	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(0.20, 0.21, 0.26, 0.65)
	sb_h.border_color = _BORDER_BRIGHT
	sb_h.set_border_width_all(1)
	sb_h.set_corner_radius_all(3)
	sb_h.content_margin_left = 4
	sb_h.content_margin_right = 4
	sb_h.content_margin_top = 2
	sb_h.content_margin_bottom = 2
	cb.add_theme_stylebox_override("hover", sb_h)
	var sb_p := StyleBoxFlat.new()
	sb_p.bg_color = Color(0.25, 0.26, 0.31, 0.75)
	sb_p.border_color = _BORDER_BRIGHT
	sb_p.set_border_width_all(1)
	sb_p.set_corner_radius_all(3)
	sb_p.content_margin_left = 4
	sb_p.content_margin_right = 4
	sb_p.content_margin_top = 2
	sb_p.content_margin_bottom = 2
	cb.add_theme_stylebox_override("pressed", sb_p)



func _style_line_edit(le: LineEdit) -> void:
	le.add_theme_color_override("font_color", _TXT_PRIMARY)
	le.add_theme_color_override("font_placeholder_color", _TXT_HINT)
	le.add_theme_color_override("caret_color", _TXT_PRIMARY)
	le.add_theme_color_override("selection_color", Color(0.55, 0.45, 0.25, 0.6))
	le.add_theme_stylebox_override("normal", _make_input_stylebox(false))
	le.add_theme_stylebox_override("focus", _make_input_stylebox(true))


func _style_spin_box(sp: SpinBox) -> void:
	var le := sp.get_line_edit()
	if le:
		_style_line_edit(le)
		le.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _style_option_button(opt: OptionButton) -> void:
	_style_button_warm(opt)
	var popup := opt.get_popup()
	if popup:
		var pm_panel := StyleBoxFlat.new()
		pm_panel.bg_color = Color(0.10, 0.11, 0.13, 0.98)
		pm_panel.border_color = _BORDER_BRIGHT
		pm_panel.set_border_width_all(2)
		pm_panel.set_corner_radius_all(6)
		pm_panel.content_margin_left = 6
		pm_panel.content_margin_right = 6
		pm_panel.content_margin_top = 4
		pm_panel.content_margin_bottom = 4
		popup.add_theme_stylebox_override("panel", pm_panel)
		popup.add_theme_color_override("font_color", _TXT_PRIMARY)
		popup.add_theme_color_override("font_hover_color", _TXT_HOVER)
		popup.add_theme_color_override("font_separator_color", _BORDER_DIM)
		var hover_sb := StyleBoxFlat.new()
		hover_sb.bg_color = Color(0.20, 0.18, 0.10, 0.95)
		hover_sb.set_corner_radius_all(3)
		popup.add_theme_stylebox_override("hover", hover_sb)


# ---------- Layout builders ----------

func _add_section_subtitle(parent: Node, font_size: int = 16) -> Label:
	var lab := Label.new()
	lab.add_theme_font_size_override("font_size", font_size)
	lab.add_theme_color_override("font_color", _TXT_SUBTITLE)
	lab.add_theme_color_override("font_outline_color", _TXT_OUTLINE)
	lab.add_theme_constant_override("outline_size", 1)
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lab)
	return lab


func _add_hint(parent: Node) -> Label:
	var lab := Label.new()
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.add_theme_font_size_override("font_size", 12)
	lab.add_theme_color_override("font_color", _TXT_HINT)
	parent.add_child(lab)
	return lab


func _add_separator(parent: Node) -> HSeparator:
	var sep := HSeparator.new()
	var sb := StyleBoxLine.new()
	sb.color = _BORDER_DIM
	sb.thickness = 1
	sep.add_theme_stylebox_override("separator", sb)
	sep.add_theme_constant_override("separation", 14)
	parent.add_child(sep)
	return sep


func _add_status_text(parent: Node, font_size: int = 13) -> Label:
	var lab := Label.new()
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.add_theme_font_size_override("font_size", font_size)
	lab.add_theme_color_override("font_color", Color(0.82, 0.88, 0.90, 0.95))
	lab.add_theme_color_override("font_outline_color", _TXT_OUTLINE)
	lab.add_theme_constant_override("outline_size", 1)
	parent.add_child(lab)
	return lab


func _style_section_button(btn: Button, selected: bool) -> void:
	_style_button_warm(btn)
	if selected:
		var sb := _make_input_stylebox(true)
		sb.bg_color = Color(0.22, 0.19, 0.10, 0.96)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_color_override("font_color", _TXT_HOVER)


func _make_dashboard_card(parent: Node, min_height: float = 230.0, section_id: String = "") -> VBoxContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, min_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sb := _make_panel_stylebox()
	sb.bg_color = Color(0.055, 0.065, 0.085, 0.95)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)
	parent.add_child(card)
	if not section_id.is_empty():
		_section_id_to_panel[section_id] = card

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	return box


# ---------- Main build ----------

func _build_vocab_study_prefs() -> void:
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.offset_left = 64.0
	root_margin.offset_top = 122.0
	root_margin.offset_right = -64.0
	root_margin.offset_bottom = -82.0
	add_child(root_margin)

	var scroll := ScrollContainer.new()
	scroll.name = "VocabConsoleScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root_margin.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "VocabConsoleContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	_console_summary = _add_status_text(content, 14)

	_dashboard_grid = GridContainer.new()
	_dashboard_grid.columns = 4
	_dashboard_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dashboard_grid.add_theme_constant_override("h_separation", 8)
	_dashboard_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(_dashboard_grid)
	_add_section_button(_SECTION_TODAY, "menu.vocab_console_today_title")
	_add_section_button(_SECTION_BOOKS, "menu.vocab_console_books_title")
	_add_section_button(_SECTION_QUIZ, "menu.vocab_console_quiz_title")
	_add_section_button(_SECTION_EXAMPLES, "menu.vocab_console_examples_title")

	_build_today_plan_card(content)
	_build_books_status_card(content)
	_build_quiz_card(content)
	_build_examples_status_card(content)
	_show_console_section(_SECTION_TODAY)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.add_filter("*.json", "JSON")
	_file_dialog.file_selected.connect(_on_vocab_import_file_selected)
	add_child(_file_dialog)

	_sync_vocab_study_prefs_from_settings()
	_rebuild_vocab_book_rows()
	_refresh_dashboard_stats()


func _add_section_button(section_id: String, label_key: String) -> void:
	var btn := Button.new()
	btn.name = "Section_" + section_id
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 15)
	btn.text = I18N.tr_key(label_key)
	btn.pressed.connect(_show_console_section.bind(section_id))
	_style_section_button(btn, section_id == _active_section_id)
	_dashboard_grid.add_child(btn)
	_section_id_to_button[section_id] = btn


func _show_console_section(section_id: String) -> void:
	if not _section_id_to_panel.has(section_id):
		return
	_active_section_id = section_id
	for sid: String in _section_id_to_panel.keys():
		var panel: PanelContainer = _section_id_to_panel[sid]
		panel.visible = sid == section_id
	for sid: String in _section_id_to_button.keys():
		var btn: Button = _section_id_to_button[sid]
		btn.set_pressed_no_signal(sid == section_id)
		_style_section_button(btn, sid == section_id)


func _build_today_plan_card(parent: Node) -> void:
	var box := _make_dashboard_card(parent, 230, _SECTION_TODAY)
	_today_title = _add_section_subtitle(box, 18)
	_today_status = _add_status_text(box)
	_add_separator(box)

	var two_col := HBoxContainer.new()
	two_col.add_theme_constant_override("separation", 18)
	two_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(two_col)

	var col_a := VBoxContainer.new()
	col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a.add_theme_constant_override("separation", 6)
	two_col.add_child(col_a)
	_vocab_daily_label = _add_section_subtitle(col_a, 15)
	_vocab_daily_spin = SpinBox.new()
	_vocab_daily_spin.min_value = 0.0
	_vocab_daily_spin.max_value = 300.0
	_vocab_daily_spin.step = 1.0
	_vocab_daily_spin.custom_minimum_size = Vector2(0, 36)
	_vocab_daily_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vocab_daily_spin.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_daily_spin.value_changed.connect(_on_vocab_daily_cap_changed)
	_style_spin_box(_vocab_daily_spin)
	col_a.add_child(_vocab_daily_spin)
	_vocab_daily_hint = _add_hint(col_a)

	var col_b := VBoxContainer.new()
	col_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_b.add_theme_constant_override("separation", 6)
	two_col.add_child(col_b)
	_vocab_ord_label = _add_section_subtitle(col_b, 15)
	_vocab_ord_spin = SpinBox.new()
	_vocab_ord_spin.min_value = 0.0
	_vocab_ord_spin.max_value = 200.0
	_vocab_ord_spin.step = 1.0
	_vocab_ord_spin.custom_minimum_size = Vector2(0, 36)
	_vocab_ord_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vocab_ord_spin.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_ord_spin.value_changed.connect(_on_vocab_ordered_example_words_changed)
	_style_spin_box(_vocab_ord_spin)
	col_b.add_child(_vocab_ord_spin)
	_vocab_ord_hint = _add_hint(col_b)

	var col_c := VBoxContainer.new()
	col_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_c.add_theme_constant_override("separation", 6)
	two_col.add_child(col_c)
	_vocab_daily_new_label = _add_section_subtitle(col_c, 15)
	_vocab_daily_new_spin = SpinBox.new()
	_vocab_daily_new_spin.min_value = 0.0
	_vocab_daily_new_spin.max_value = 300.0
	_vocab_daily_new_spin.step = 1.0
	_vocab_daily_new_spin.custom_minimum_size = Vector2(0, 36)
	_vocab_daily_new_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vocab_daily_new_spin.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_daily_new_spin.value_changed.connect(_on_vocab_daily_new_words_changed)
	_style_spin_box(_vocab_daily_new_spin)
	col_c.add_child(_vocab_daily_new_spin)
	_vocab_daily_new_hint = _add_hint(col_c)


func _build_books_status_card(parent: Node) -> void:
	var box := _make_dashboard_card(parent, 330, _SECTION_BOOKS)
	_books_title = _add_section_subtitle(box, 18)
	_books_status = _add_status_text(box)
	_add_separator(box)

	_vocab_books_box = VBoxContainer.new()
	_vocab_books_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vocab_books_box.add_theme_constant_override("separation", 6)
	box.add_child(_vocab_books_box)

	var import_row := HBoxContainer.new()
	import_row.alignment = BoxContainer.ALIGNMENT_CENTER
	import_row.add_theme_constant_override("separation", 12)
	box.add_child(import_row)
	_vocab_import_btn = Button.new()
	_vocab_import_btn.add_theme_font_size_override("font_size", 14)
	_vocab_import_btn.custom_minimum_size = Vector2(220, 40)
	_vocab_import_btn.pressed.connect(_on_vocab_import_pressed)
	_style_button_warm(_vocab_import_btn)
	import_row.add_child(_vocab_import_btn)

	_vocab_import_status = Label.new()
	_vocab_import_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_import_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_import_status.add_theme_font_size_override("font_size", 12)
	_vocab_import_status.add_theme_color_override("font_color", _STATUS_OK)
	box.add_child(_vocab_import_status)


func _build_quiz_card(parent: Node) -> void:
	var box := _make_dashboard_card(parent, 440, _SECTION_QUIZ)
	_quiz_title = _add_section_subtitle(box, 18)
	_quiz_status = _add_status_text(box)
	_add_separator(box)
	
	# 背单词模式选择
	_vocab_mode_label = _add_section_subtitle(box, 15)
	_vocab_mode_option = OptionButton.new()
	_vocab_mode_option.add_theme_font_size_override("font_size", 14)
	_vocab_mode_option.custom_minimum_size = Vector2(200, 36)
	_vocab_mode_option.add_item("每张牌复习（现有模式）", 0)
	_vocab_mode_option.add_item("每回合一个单词（顺序学习）", 1)
	_vocab_mode_option.item_selected.connect(_on_vocab_mode_selected)
	_style_option_button(_vocab_mode_option)
	box.add_child(_vocab_mode_option)
	_vocab_mode_hint = _add_hint(box)
	
	_add_separator(box)
	_vocab_learn_steps_label = _add_section_subtitle(box, 15)
	_vocab_learn_steps_flow = FlowContainer.new()
	_vocab_learn_steps_flow.add_theme_constant_override("h_separation", 14)
	_vocab_learn_steps_flow.add_theme_constant_override("v_separation", 8)
	_vocab_learn_steps_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_vocab_learn_steps_flow)
	_learn_step_id_to_checkbox.clear()
	for sid: String in _VOCAB_LEARN_STEP_IDS:
		var cb_ls := CheckBox.new()
		cb_ls.name = "LearnStep_" + sid
		cb_ls.add_theme_font_size_override("font_size", 14)
		cb_ls.toggled.connect(_on_learn_step_toggled.bind(sid))
		_style_check_box(cb_ls)
		_vocab_learn_steps_flow.add_child(cb_ls)
		_learn_step_id_to_checkbox[sid] = cb_ls
	_vocab_learn_steps_hint = _add_hint(box)
	_add_separator(box)
	_vocab_review_modes_label = _add_section_subtitle(box, 15)
	_vocab_review_modes_flow = FlowContainer.new()
	_vocab_review_modes_flow.add_theme_constant_override("h_separation", 14)
	_vocab_review_modes_flow.add_theme_constant_override("v_separation", 8)
	_vocab_review_modes_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_vocab_review_modes_flow)
	_review_mode_id_to_checkbox.clear()
	for mid: String in _VOCAB_REVIEW_MODE_IDS:
		var cb_rm := CheckBox.new()
		cb_rm.name = "ReviewMode_" + mid
		cb_rm.add_theme_font_size_override("font_size", 14)
		cb_rm.toggled.connect(_on_review_mode_toggled.bind(mid))
		_style_check_box(cb_rm)
		_vocab_review_modes_flow.add_child(cb_rm)
		_review_mode_id_to_checkbox[mid] = cb_rm
	_vocab_review_modes_hint = _add_hint(box)


func _build_examples_status_card(parent: Node) -> void:
	var box := _make_dashboard_card(parent, 330, _SECTION_EXAMPLES)
	_examples_title = _add_section_subtitle(box, 18)
	_examples_status = _add_status_text(box)
	_add_separator(box)
	_vocab_style_sub = _add_section_subtitle(box, 15)

	var flow := FlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 8)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(flow)

	_preset_id_to_checkbox.clear()
	for pid: String in _DOMAIN_PRESET_IDS:
		var cb := CheckBox.new()
		cb.name = "VocabDomain_" + pid
		cb.add_theme_font_size_override("font_size", 14)
		cb.button_pressed = Global.user_settings_data.settings_vocab_example_domain_tags.has(pid)
		cb.toggled.connect(_on_domain_preset_toggled.bind(pid))
		_style_check_box(cb)
		flow.add_child(cb)
		_preset_id_to_checkbox[pid] = cb

	_add_separator(box)

	_vocab_custom_label = _add_section_subtitle(box, 14)
	_vocab_custom_domain = LineEdit.new()
	_vocab_custom_domain.add_theme_font_size_override("font_size", 14)
	_vocab_custom_domain.custom_minimum_size = Vector2(0, 36)
	_vocab_custom_domain.text = Global.user_settings_data.settings_vocab_example_domain_custom
	_vocab_custom_domain.focus_exited.connect(_persist_vocab_custom_domain)
	_vocab_custom_domain.text_submitted.connect(_on_vocab_custom_domain_submitted)
	_style_line_edit(_vocab_custom_domain)
	box.add_child(_vocab_custom_domain)


# ---------- I18n ----------

func _refresh_vocab_study_prefs_i18n() -> void:
	if _today_title:
		_today_title.text = I18N.tr_key("menu.vocab_console_today_title")
	if _books_title:
		_books_title.text = I18N.tr_key("menu.vocab_console_books_title")
	if _quiz_title:
		_quiz_title.text = I18N.tr_key("menu.vocab_console_quiz_title")
	if _examples_title:
		_examples_title.text = I18N.tr_key("menu.vocab_console_examples_title")
	if _section_id_to_button.has(_SECTION_TODAY):
		_section_id_to_button[_SECTION_TODAY].text = I18N.tr_key("menu.vocab_console_today_title")
	if _section_id_to_button.has(_SECTION_BOOKS):
		_section_id_to_button[_SECTION_BOOKS].text = I18N.tr_key("menu.vocab_console_books_title")
	if _section_id_to_button.has(_SECTION_QUIZ):
		_section_id_to_button[_SECTION_QUIZ].text = I18N.tr_key("menu.vocab_console_quiz_title")
	if _section_id_to_button.has(_SECTION_EXAMPLES):
		_section_id_to_button[_SECTION_EXAMPLES].text = I18N.tr_key("menu.vocab_console_examples_title")
	if _vocab_daily_label:
		_vocab_daily_label.text = I18N.tr_key("menu.vocab_daily_cap_label")
	if _vocab_daily_hint:
		_vocab_daily_hint.text = I18N.tr_key("menu.vocab_daily_cap_hint")
	if _vocab_daily_new_label:
		_vocab_daily_new_label.text = I18N.tr_key("menu.vocab_daily_new_label")
	if _vocab_daily_new_hint:
		_vocab_daily_new_hint.text = I18N.tr_key("menu.vocab_daily_new_hint")
	if _vocab_ord_label:
		_vocab_ord_label.text = I18N.tr_key("menu.vocab_ordered_batch_label")
	if _vocab_ord_hint:
		_vocab_ord_hint.text = I18N.tr_key("menu.vocab_ordered_batch_hint")
	if _vocab_learn_steps_label:
		_vocab_learn_steps_label.text = I18N.tr_key("menu.vocab_learn_steps_label")
	if _vocab_learn_steps_hint:
		_vocab_learn_steps_hint.text = I18N.tr_key("menu.vocab_learn_steps_hint")
	if _vocab_review_modes_label:
		_vocab_review_modes_label.text = I18N.tr_key("menu.vocab_review_modes_label")
	if _vocab_review_modes_hint:
		_vocab_review_modes_hint.text = I18N.tr_key("menu.vocab_review_modes_hint")
	if _vocab_mode_label:
		_vocab_mode_label.text = I18N.tr_key("menu.vocab_mode_label")
	if _vocab_mode_hint:
		_vocab_mode_hint.text = I18N.tr_key("menu.vocab_mode_hint")
	_vocab_mode_option.set_item_text(0, I18N.tr_key("menu.vocab_mode_per_card"))
	_vocab_mode_option.set_item_text(1, I18N.tr_key("menu.vocab_mode_per_turn"))
	for sid: String in _learn_step_id_to_checkbox.keys():
		var cb_ls: CheckBox = _learn_step_id_to_checkbox[sid]
		cb_ls.text = I18N.tr_key("menu.vocab_learn_" + sid)
	for mid: String in _review_mode_id_to_checkbox.keys():
		var cb_rm: CheckBox = _review_mode_id_to_checkbox[mid]
		cb_rm.text = I18N.tr_key("vocab.review.mode_" + mid)
	if _vocab_style_sub:
		_vocab_style_sub.text = I18N.tr_key("menu.vocab_console_domain_label")
	if _vocab_custom_label:
		_vocab_custom_label.text = I18N.tr_key("overlay.vocab_domains_custom")
	if _vocab_custom_domain:
		_vocab_custom_domain.placeholder_text = I18N.tr_key("overlay.vocab_domains_custom")
	if _vocab_import_btn:
		_vocab_import_btn.text = I18N.tr_key("menu.vocab_import_json")
	for pid: String in _preset_id_to_checkbox.keys():
		var cb: CheckBox = _preset_id_to_checkbox[pid]
		cb.text = I18N.tr_key("vocab.domain." + pid)
	for bid: String in _book_id_to_checkbox.keys():
		_refresh_single_book_row_label(bid)
	_refresh_dashboard_stats()


func _sync_vocab_study_prefs_from_settings() -> void:
	if _vocab_daily_spin:
		_vocab_daily_spin.set_value_no_signal(float(Global.user_settings_data.settings_vocab_daily_due_cap))
	if _vocab_daily_new_spin:
		_vocab_daily_new_spin.set_value_no_signal(float(Global.user_settings_data.settings_vocab_daily_new_words))
	if _vocab_ord_spin:
		_vocab_ord_spin.set_value_no_signal(float(Global.user_settings_data.settings_vocab_daily_ordered_example_words))
	if _vocab_mode_option:
		_vocab_mode_option.set_block_signals(true)
		if Global.user_settings_data.settings_vocab_mode == "per_turn":
			_vocab_mode_option.selected = 1
		else:
			_vocab_mode_option.selected = 0
		_vocab_mode_option.set_block_signals(false)
	for sid: String in _learn_step_id_to_checkbox.keys():
		var cb_ls: CheckBox = _learn_step_id_to_checkbox[sid]
		cb_ls.set_block_signals(true)
		cb_ls.button_pressed = _array_contains_str(Global.user_settings_data.settings_vocab_learn_steps_enabled, sid)
		cb_ls.set_block_signals(false)
	for mid: String in _review_mode_id_to_checkbox.keys():
		var cb_rm: CheckBox = _review_mode_id_to_checkbox[mid]
		cb_rm.set_block_signals(true)
		cb_rm.button_pressed = _array_contains_str(Global.user_settings_data.settings_vocab_review_modes_enabled, mid)
		cb_rm.set_block_signals(false)
	for pid: String in _preset_id_to_checkbox.keys():
		var cb: CheckBox = _preset_id_to_checkbox[pid]
		cb.set_block_signals(true)
		cb.button_pressed = Global.user_settings_data.settings_vocab_example_domain_tags.has(pid)
		cb.set_block_signals(false)
	if _vocab_custom_domain:
		_vocab_custom_domain.text = Global.user_settings_data.settings_vocab_example_domain_custom
	for bid: String in _book_id_to_checkbox.keys():
		var cb2: CheckBox = _book_id_to_checkbox[bid]
		cb2.set_block_signals(true)
		cb2.button_pressed = Global.user_settings_data.settings_vocab_enabled_book_ids.has(bid)
		cb2.set_block_signals(false)


func _refresh_dashboard_stats() -> void:
	if _today_status == null:
		return
	var stats: Dictionary = VocabStudy.get_vocab_dashboard_stats()
	var total_words: int = int(stats.get("total_words", 0))
	var due_total: int = int(stats.get("due_review_words", 0))
	var due_today: int = int(stats.get("due_review_available_today", due_total))
	var learned: int = int(stats.get("learned_words", 0))
	if _console_summary:
		_console_summary.text = I18N.tr_key("menu.vocab_console_summary", [
			int(stats.get("new_words", 0)),
			due_total,
			int(stats.get("enabled_book_count", 0)),
			total_words,
			int(stats.get("example_ready_words", 0)),
		])
	if _today_status:
		_today_status.text = I18N.tr_key("menu.vocab_console_today_stats", [
			int(stats.get("new_words", 0)),
			due_total,
			due_today,
			learned,
			total_words,
		])
	if _books_status:
		_books_status.text = I18N.tr_key("menu.vocab_console_books_stats", [
			int(stats.get("enabled_book_count", 0)),
			int(stats.get("known_book_count", 0)),
			total_words,
		])
	if _quiz_status:
		_quiz_status.text = I18N.tr_key("menu.vocab_console_quiz_stats", [
			_format_enabled_learn_steps_summary(),
			_format_enabled_review_modes_summary(),
		])
	if _examples_status:
		var api_state := (
			I18N.tr_key("menu.vocab_console_api_ready")
			if bool(stats.get("has_openai", false))
			else I18N.tr_key("menu.vocab_console_api_missing")
		)
		var batch_n: int = int(stats.get("daily_example_batch_size", 0))
		var batch_state := I18N.tr_key("menu.vocab_console_batch_off")
		if batch_n > 0:
			batch_state = (
				I18N.tr_key("menu.vocab_console_batch_done")
				if bool(stats.get("daily_example_batch_done_today", false))
				else I18N.tr_key("menu.vocab_console_batch_waiting")
			)
		_examples_status.text = I18N.tr_key("menu.vocab_console_examples_stats", [
			str(stats.get("domain_summary", "")),
			api_state,
			int(stats.get("example_ready_words", 0)),
			total_words,
			batch_n,
			batch_state,
		])


func _on_vocab_daily_cap_changed(v: float) -> void:
	Global.user_settings_data.settings_vocab_daily_due_cap = clampi(int(round(v)), 0, 300)
	FileLoader.save_user_settings()
	_refresh_dashboard_stats()


func _on_vocab_daily_new_words_changed(v: float) -> void:
	Global.user_settings_data.settings_vocab_daily_new_words = clampi(int(round(v)), 0, 300)
	FileLoader.save_user_settings()
	VocabStudy.reload_from_settings()
	_refresh_dashboard_stats()


func _on_vocab_ordered_example_words_changed(v: float) -> void:
	Global.user_settings_data.settings_vocab_daily_ordered_example_words = clampi(int(round(v)), 0, 200)
	FileLoader.save_user_settings()
	_refresh_dashboard_stats()


func _array_contains_str(arr: Variant, needle: String) -> bool:
	if typeof(arr) != TYPE_ARRAY:
		return false
	for v: Variant in arr as Array:
		if str(v).strip_edges() == needle:
			return true
	return false


func _format_enabled_learn_steps_summary() -> String:
	var parts: PackedStringArray = []
	for sid: String in _VOCAB_LEARN_STEP_IDS:
		if _array_contains_str(Global.user_settings_data.settings_vocab_learn_steps_enabled, sid):
			parts.append(I18N.tr_key("menu.vocab_learn_" + sid))
	return " · ".join(parts)


func _format_enabled_review_modes_summary() -> String:
	var parts: PackedStringArray = []
	for mid: String in _VOCAB_REVIEW_MODE_IDS:
		if _array_contains_str(Global.user_settings_data.settings_vocab_review_modes_enabled, mid):
			parts.append(I18N.tr_key("vocab.review.mode_" + mid))
	return " · ".join(parts)


func _on_learn_step_toggled(_pressed: bool, step_id: String) -> void:
	var arr: Array[String] = []
	for sid: String in _VOCAB_LEARN_STEP_IDS:
		if _learn_step_id_to_checkbox[sid].button_pressed:
			arr.append(sid)
	if arr.is_empty():
		var cb: CheckBox = _learn_step_id_to_checkbox[step_id]
		cb.set_block_signals(true)
		cb.button_pressed = true
		cb.set_block_signals(false)
		arr.append(step_id)
	Global.user_settings_data.settings_vocab_learn_steps_enabled = arr
	FileLoader.save_user_settings()
	VocabStudy.reload_from_settings()
	_refresh_dashboard_stats()


func _on_vocab_mode_selected(index: int) -> void:
	if index == 0:
		Global.user_settings_data.settings_vocab_mode = "per_card"
	else:
		Global.user_settings_data.settings_vocab_mode = "per_turn"
	FileLoader.save_user_settings()
	VocabStudy.reload_from_settings()
	_refresh_dashboard_stats()

func _on_review_mode_toggled(_pressed: bool, mode_id: String) -> void:
	var arr: Array[String] = []
	for mid: String in _VOCAB_REVIEW_MODE_IDS:
		if _review_mode_id_to_checkbox[mid].button_pressed:
			arr.append(mid)
	if arr.is_empty():
		var cb: CheckBox = _review_mode_id_to_checkbox[mode_id]
		cb.set_block_signals(true)
		cb.button_pressed = true
		cb.set_block_signals(false)
		arr.append(mode_id)
	Global.user_settings_data.settings_vocab_review_modes_enabled = arr
	Global.user_settings_data.settings_vocab_combat_review_mode = arr[0]
	FileLoader.save_user_settings()
	VocabStudy.reload_from_settings()
	_refresh_dashboard_stats()


func _on_domain_preset_toggled(pressed: bool, preset_id: String) -> void:
	var arr: Array[String] = Global.user_settings_data.settings_vocab_example_domain_tags.duplicate()
	if pressed:
		if not arr.has(preset_id):
			arr.append(preset_id)
	else:
		while arr.has(preset_id):
			arr.erase(preset_id)
	Global.user_settings_data.settings_vocab_example_domain_tags = arr
	FileLoader.save_user_settings()
	VocabStudy.notify_example_preferences_changed()
	_refresh_dashboard_stats()


func _persist_vocab_custom_domain() -> void:
	var t: String = _vocab_custom_domain.text.strip_edges()
	if t == Global.user_settings_data.settings_vocab_example_domain_custom:
		return
	Global.user_settings_data.settings_vocab_example_domain_custom = t
	FileLoader.save_user_settings()
	VocabStudy.notify_example_preferences_changed()
	_refresh_dashboard_stats()


func _on_vocab_custom_domain_submitted(_t: String) -> void:
	_persist_vocab_custom_domain()


func _rebuild_vocab_book_rows() -> void:
	if _vocab_books_box == null:
		return
	for i in range(_vocab_books_box.get_child_count() - 1, -1, -1):
		_vocab_books_box.get_child(i).queue_free()
	_book_id_to_checkbox.clear()
	var metas: Array[Dictionary] = VocabStudy.list_known_books()
	metas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ida: String = str(a.get("book_id", ""))
		var idb: String = str(b.get("book_id", ""))
		if ida == "builtin_default":
			return true
		if idb == "builtin_default":
			return false
		return ida.to_lower() < idb.to_lower()
	)
	for meta: Dictionary in metas:
		var bid: String = str(meta.get("book_id", ""))
		if bid.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var cb := CheckBox.new()
		cb.name = "Book_" + bid
		cb.add_theme_font_size_override("font_size", 13)
		cb.button_pressed = Global.user_settings_data.settings_vocab_enabled_book_ids.has(bid)
		cb.tooltip_text = _book_row_tooltip(meta)
		cb.toggled.connect(_on_book_toggled.bind(bid))
		_style_check_box(cb)
		row.add_child(cb)
		_book_id_to_checkbox[bid] = cb
		var cap := Label.new()
		cap.name = "BookCap"
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cap.add_theme_font_size_override("font_size", 13)
		cap.add_theme_color_override("font_color", _TXT_PRIMARY)
		cap.text = _book_row_caption(meta)
		cap.tooltip_text = _book_row_tooltip(meta)
		row.add_child(cap)
		var src: String = str(meta.get("source", ""))
		if src == "user":
			var del_btn := Button.new()
			del_btn.text = "×"
			del_btn.tooltip_text = I18N.tr_key("menu.vocab_book_delete_tooltip")
			del_btn.custom_minimum_size = Vector2(28, 28)
			del_btn.add_theme_font_size_override("font_size", 16)
			del_btn.add_theme_color_override("font_color", Color(0.95, 0.55, 0.50, 1.0))
			del_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.70, 0.65, 1.0))
			del_btn.add_theme_color_override("font_pressed_color", Color(0.80, 0.40, 0.35, 1.0))
			del_btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
			del_btn.add_theme_constant_override("outline_size", 1)
			var del_sb := StyleBoxFlat.new()
			del_sb.bg_color = Color(0.12, 0.05, 0.05, 0.6)
			del_sb.border_color = Color(0.60, 0.25, 0.20, 0.8)
			del_sb.set_border_width_all(1)
			del_sb.set_corner_radius_all(4)
			del_btn.add_theme_stylebox_override("normal", del_sb)
			var del_sb_h := StyleBoxFlat.new()
			del_sb_h.bg_color = Color(0.22, 0.08, 0.08, 0.75)
			del_sb_h.border_color = Color(0.85, 0.35, 0.30, 1.0)
			del_sb_h.set_border_width_all(1)
			del_sb_h.set_corner_radius_all(4)
			del_btn.add_theme_stylebox_override("hover", del_sb_h)
			var del_sb_p := StyleBoxFlat.new()
			del_sb_p.bg_color = Color(0.30, 0.10, 0.10, 0.85)
			del_sb_p.border_color = Color(0.70, 0.30, 0.25, 1.0)
			del_sb_p.set_border_width_all(1)
			del_sb_p.set_corner_radius_all(4)
			del_btn.add_theme_stylebox_override("pressed", del_sb_p)
			del_btn.pressed.connect(_on_delete_book_pressed.bind(bid))
			row.add_child(del_btn)
		_vocab_books_box.add_child(row)


func _on_delete_book_pressed(bid: String) -> void:
	_pending_delete_book_id = bid
	if _delete_confirm_dialog:
		_delete_confirm_dialog.dialog_text = I18N.tr_key("menu.vocab_book_delete_confirm", [bid])
		_delete_confirm_dialog.popup_centered()


func _on_delete_confirmed() -> void:
	if _pending_delete_book_id.is_empty():
		return
	var ok := VocabStudy.delete_user_book(_pending_delete_book_id)
	if ok and _vocab_import_status:
		_vocab_import_status.text = I18N.tr_key("menu.vocab_book_deleted", [_pending_delete_book_id])
	_pending_delete_book_id = ""
	_rebuild_vocab_book_rows()
	_sync_vocab_study_prefs_from_settings()
	_refresh_dashboard_stats()


func _book_row_caption(meta: Dictionary) -> String:
	var bid: String = str(meta.get("book_id", ""))
	var nm: String = str(meta.get("book_name", "")).strip_edges()
	var src: String = str(meta.get("source", ""))
	var src_disp: String = ""
	if not src.is_empty():
		match src:
			"builtin", "packaged", "user":
				src_disp = I18N.tr_key("menu.vocab_book_source." + src)
			_:
				src_disp = src
	if nm.is_empty():
		if bid == "builtin_default":
			nm = I18N.tr_key("menu.vocab_book_builtin_name")
		else:
			nm = bid
	if src == "builtin":
		return I18N.tr_key("menu.vocab_book_row_named_locked", [nm, bid, src_disp])
	if nm == bid:
		if src_disp.is_empty():
			return bid
		return I18N.tr_key("menu.vocab_book_row_id_only", [bid, src_disp])
	if src_disp.is_empty():
		return I18N.tr_key("menu.vocab_book_row_two", [nm, bid])
	return I18N.tr_key("menu.vocab_book_row_named", [nm, bid, src_disp])


func _book_row_tooltip(meta: Dictionary) -> String:
	var src: String = str(meta.get("source", ""))
	match src:
		"builtin":
			return I18N.tr_key("menu.vocab_book_builtin_tooltip")
		"packaged":
			return I18N.tr_key("menu.vocab_book_packaged_tooltip")
		"user":
			return I18N.tr_key("menu.vocab_book_user_tooltip")
		_:
			return ""


func _refresh_single_book_row_label(bid: String) -> void:
	var cb: CheckBox = _book_id_to_checkbox.get(bid, null) as CheckBox
	if cb == null:
		return
	var row: Node = cb.get_parent()
	if row == null:
		return
	var cap: Label = row.find_child("BookCap", true, false) as Label
	if cap == null:
		return
	for meta: Dictionary in VocabStudy.list_known_books():
		if str(meta.get("book_id", "")) == bid:
			cap.text = _book_row_caption(meta)
			var tip := _book_row_tooltip(meta)
			cap.tooltip_text = tip
			cb.tooltip_text = tip
			return


func _on_book_toggled(pressed: bool, book_id: String) -> void:
	var arr: Array[String] = Global.user_settings_data.settings_vocab_enabled_book_ids.duplicate()
	if pressed:
		if not arr.has(book_id):
			arr.append(book_id)
	else:
		if arr.size() <= 1:
			var cb: CheckBox = _book_id_to_checkbox.get(book_id, null) as CheckBox
			if cb:
				cb.set_block_signals(true)
				cb.button_pressed = true
				cb.set_block_signals(false)
			if _vocab_import_status:
				_vocab_import_status.text = I18N.tr_key("menu.vocab_book_keep_one")
			return
		while arr.has(book_id):
			arr.erase(book_id)
	Global.user_settings_data.settings_vocab_enabled_book_ids = arr
	FileLoader.save_user_settings()
	VocabStudy.reload_from_settings()
	call_deferred("_rebuild_vocab_book_rows")
	call_deferred("_refresh_dashboard_stats")


func _on_vocab_import_pressed() -> void:
	if _vocab_import_status:
		_vocab_import_status.text = ""
	_file_dialog.popup_centered(Vector2i(720, 520))


func _on_vocab_import_file_selected(path: String) -> void:
	var bid: String = VocabStudy.import_book_from_user_absolute_path(path, true)
	if bid != "":
		if _vocab_import_status:
			_vocab_import_status.text = I18N.tr_key("menu.vocab_import_ok", [bid])
		_rebuild_vocab_book_rows()
		_sync_vocab_study_prefs_from_settings()
		_refresh_dashboard_stats()
	else:
		if _vocab_import_status:
			_vocab_import_status.text = I18N.tr_key("menu.vocab_import_failed")
