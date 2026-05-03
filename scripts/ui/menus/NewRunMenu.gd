extends Control

@onready var title_screen: Control = $%TitleScreen

@onready var title_label: Label = $Label
@onready var character_name_label = $CharacterNameLabel
@onready var character_health_label = $CharacterHealthLabel
@onready var character_money_label = $CharacterMoneyLabel
@onready var character_description_label = $CharacterDescriptionLabel

@onready var character_artifact_texture_rect = $CharacterArtifactTextureRect
@onready var character_artifact_name_label = $CharacterArtifactNameLabel
@onready var character_artifact_description_label = $CharacterArtifactDescriptionLabel

@onready var decrease_difficulty_button = $DifficultySelect/DecreaseDifficultyButton
@onready var difficulty_label = $DifficultySelect/DifficultyLabel
@onready var increase_difficulty_button = $DifficultySelect/IncreaseDifficultyButton

@onready var custom_run_modifier_button_container = $CustomRunModifierButtonContainer
@onready var custom_modifiers_label: Label = $Label4

@onready var character_button_container = $CharacterButtonContainer

@onready var start_run_button: Button = $StartRunButton
@onready var seed_label: Label = $Label3
@onready var seed_input: LineEdit = $SeedInput
@onready var back_button: Button = $BackButton

const _DOMAIN_PRESET_IDS: Array[String] = [
	"film_tv",
	"anime",
	"exam_style",
	"daily",
	"news",
	"game_scifi",
]

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0

var _vocab_scroll: ScrollContainer
var _vocab_section_title: Label
var _vocab_daily_label: Label
var _vocab_daily_hint: Label
var _vocab_daily_spin: SpinBox
var _vocab_ord_label: Label
var _vocab_ord_hint: Label
var _vocab_ord_spin: SpinBox
var _vocab_review_mode_label: Label
var _vocab_review_mode_opt: OptionButton
var _vocab_review_mode_hint: Label
var _vocab_style_sub: Label
var _preset_id_to_checkbox: Dictionary[String, CheckBox] = {}
var _vocab_custom_domain: LineEdit
var _vocab_books_sub: Label
var _vocab_books_box: VBoxContainer
var _book_id_to_checkbox: Dictionary[String, CheckBox] = {}
var _vocab_import_btn: Button
var _vocab_import_status: Label
var _file_dialog: FileDialog


func _ready():
	for b in [start_run_button, back_button]:
		for legacy in b.get_children():
			if legacy.name == "LocalizedTextLabel":
				legacy.queue_free()
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 1.0))
		b.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
		b.add_theme_constant_override("outline_size", 1)
	start_run_button.pressed.connect(_on_start_run_button_up)
	back_button.pressed.connect(_on_back_button_up)

	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)

	seed_input.text_changed.connect(_on_seed_input_text_changed)

	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	I18N.locale_changed.connect(_on_locale_changed)

	_build_vocab_study_prefs()
	_apply_localized_text()


func _on_seed_input_text_changed(new_text: String):
	# validate the input of the line edit
	var caret_column: int = seed_input.caret_column	# store cursor position as changing text resets it
	seed_input.text = str(new_text.to_int()) # validate inputs to only int
	seed_input.caret_column = min(caret_column, len(seed_input.text)) # reset the cursor position

func _on_character_selected(character_object_id: String):
	selected_character_object_id = character_object_id
	populate_character_info(selected_character_object_id)

func _on_decrease_difficulty_button():
	selected_difficulty_level = max(0, selected_difficulty_level -1)
	difficulty_label.text = I18N.tr_key("menu.difficulty", [selected_difficulty_level])
func _on_increase_difficulty_button():
	selected_difficulty_level = min(selected_difficulty_level + 1, len(PlayerData.DIFFICULTY_RUN_MODIFIER_OBJECT_IDS))
	difficulty_label.text = I18N.tr_key("menu.difficulty", [selected_difficulty_level])

func populate_new_run_menu() -> void:
	character_button_container.populate_character_buttons()
	custom_run_modifier_button_container.populate_custom_run_modifiers()
	if _vocab_import_status:
		_vocab_import_status.text = ""
	_sync_vocab_study_prefs_from_settings()
	_rebuild_vocab_book_rows()
	_apply_localized_text()

func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null:
		character_name_label.text = I18N.tr_data(character_data.object_id, "character_name", character_data.character_name)
		character_health_label.text = I18N.tr_key("menu.hp_prefix", [character_data.character_starting_health])
		character_money_label.text = I18N.tr_key("menu.money_prefix", [character_data.character_starting_money])
		character_description_label.text = I18N.tr_data(character_data.object_id, "character_description", character_data.character_description)
		
		# TODO potentially update ui to support multiple starter artifacts displayed
		if len(character_data.character_starting_artifact_ids) > 0:
			var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
			if artifact_data != null:
				character_artifact_texture_rect.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
				character_artifact_name_label.text = I18N.tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)
				character_artifact_description_label.text = I18N.tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)

func _on_start_run_button_up():
	# get the seed and start the run
	var run_seed: int = seed_input.text.to_int()
	Global.start_run(selected_character_object_id, run_seed, selected_difficulty_level, custom_run_modifier_button_container.selected_custom_run_modififers)

func _on_back_button_up():
	title_screen.show_main_menu()

func _on_run_ended():
	# go back to tile screen on failed run, but not abandoned run
	var has_save_file: bool = FileLoader.has_save_file()
	visible = not has_save_file
	populate_new_run_menu()

func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
	custom_run_modifier_button_container.refresh_custom_run_modifier_labels()
	if selected_character_object_id != "":
		populate_character_info(selected_character_object_id)

func _apply_localized_text() -> void:
	title_label.text = I18N.tr_key("menu.new_run")
	seed_label.text = I18N.tr_key("menu.seed")
	custom_modifiers_label.text = I18N.tr_key("menu.custom_modifiers")
	difficulty_label.text = I18N.tr_key("menu.difficulty", [selected_difficulty_level])
	start_run_button.text = I18N.tr_key("menu.start_run")
	back_button.text = I18N.tr_key("menu.back")
	_refresh_vocab_study_prefs_i18n()


func _build_vocab_study_prefs() -> void:
	_vocab_scroll = ScrollContainer.new()
	_vocab_scroll.name = "VocabStudyPrefsScroll"
	_vocab_scroll.layout_mode = 0
	_vocab_scroll.position = Vector2(8, 108)
	_vocab_scroll.size = Vector2(364, 400)
	_vocab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vocab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_vocab_scroll)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.94)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	_vocab_scroll.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	_vocab_section_title = Label.new()
	_vocab_section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_section_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_section_title.add_theme_font_size_override("font_size", 16)
	outer.add_child(_vocab_section_title)

	_vocab_daily_label = Label.new()
	_vocab_daily_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_daily_label.add_theme_font_size_override("font_size", 13)
	outer.add_child(_vocab_daily_label)

	var spin_row := HBoxContainer.new()
	spin_row.add_theme_constant_override("separation", 10)
	outer.add_child(spin_row)
	_vocab_daily_spin = SpinBox.new()
	_vocab_daily_spin.min_value = 0.0
	_vocab_daily_spin.max_value = 300.0
	_vocab_daily_spin.step = 1.0
	_vocab_daily_spin.custom_minimum_size = Vector2(120, 0)
	_vocab_daily_spin.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_daily_spin.value_changed.connect(_on_vocab_daily_cap_changed)
	spin_row.add_child(_vocab_daily_spin)

	_vocab_daily_hint = Label.new()
	_vocab_daily_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_daily_hint.add_theme_font_size_override("font_size", 11)
	_vocab_daily_hint.modulate = Color(0.82, 0.86, 0.9, 0.95)
	outer.add_child(_vocab_daily_hint)

	_vocab_ord_label = Label.new()
	_vocab_ord_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_ord_label.add_theme_font_size_override("font_size", 13)
	outer.add_child(_vocab_ord_label)

	var ord_row := HBoxContainer.new()
	ord_row.add_theme_constant_override("separation", 10)
	outer.add_child(ord_row)
	_vocab_ord_spin = SpinBox.new()
	_vocab_ord_spin.min_value = 0.0
	_vocab_ord_spin.max_value = 200.0
	_vocab_ord_spin.step = 1.0
	_vocab_ord_spin.custom_minimum_size = Vector2(120, 0)
	_vocab_ord_spin.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_ord_spin.value_changed.connect(_on_vocab_ordered_example_words_changed)
	ord_row.add_child(_vocab_ord_spin)

	_vocab_ord_hint = Label.new()
	_vocab_ord_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_ord_hint.add_theme_font_size_override("font_size", 11)
	_vocab_ord_hint.modulate = Color(0.82, 0.86, 0.9, 0.95)
	outer.add_child(_vocab_ord_hint)

	_vocab_review_mode_label = Label.new()
	_vocab_review_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_review_mode_label.add_theme_font_size_override("font_size", 13)
	outer.add_child(_vocab_review_mode_label)

	_vocab_review_mode_opt = OptionButton.new()
	_vocab_review_mode_opt.custom_minimum_size = Vector2(280, 0)
	_vocab_review_mode_opt.add_theme_font_size_override("font_size", 13)
	_vocab_review_mode_opt.item_selected.connect(_on_vocab_review_mode_selected)
	outer.add_child(_vocab_review_mode_opt)

	_vocab_review_mode_hint = Label.new()
	_vocab_review_mode_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_review_mode_hint.add_theme_font_size_override("font_size", 11)
	_vocab_review_mode_hint.modulate = Color(0.82, 0.86, 0.9, 0.95)
	outer.add_child(_vocab_review_mode_hint)

	_vocab_style_sub = Label.new()
	_vocab_style_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_style_sub.add_theme_font_size_override("font_size", 14)
	outer.add_child(_vocab_style_sub)

	var tag_scroll := ScrollContainer.new()
	tag_scroll.custom_minimum_size = Vector2(0, 76)
	tag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tag_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(tag_scroll)
	var flow := FlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 4)
	tag_scroll.add_child(flow)

	_preset_id_to_checkbox.clear()
	for pid: String in _DOMAIN_PRESET_IDS:
		var cb := CheckBox.new()
		cb.name = "VocabDomain_" + pid
		cb.add_theme_font_size_override("font_size", 12)
		cb.button_pressed = Global.user_settings_data.settings_vocab_example_domain_tags.has(pid)
		cb.toggled.connect(_on_domain_preset_toggled.bind(pid))
		flow.add_child(cb)
		_preset_id_to_checkbox[pid] = cb

	_vocab_custom_domain = LineEdit.new()
	_vocab_custom_domain.add_theme_font_size_override("font_size", 12)
	_vocab_custom_domain.text = Global.user_settings_data.settings_vocab_example_domain_custom
	_vocab_custom_domain.focus_exited.connect(_persist_vocab_custom_domain)
	_vocab_custom_domain.text_submitted.connect(_on_vocab_custom_domain_submitted)
	outer.add_child(_vocab_custom_domain)

	_vocab_books_sub = Label.new()
	_vocab_books_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_books_sub.add_theme_font_size_override("font_size", 14)
	outer.add_child(_vocab_books_sub)

	var books_scroll := ScrollContainer.new()
	books_scroll.custom_minimum_size = Vector2(0, 108)
	books_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	books_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(books_scroll)
	_vocab_books_box = VBoxContainer.new()
	_vocab_books_box.add_theme_constant_override("separation", 4)
	books_scroll.add_child(_vocab_books_box)

	_vocab_import_btn = Button.new()
	_vocab_import_btn.add_theme_font_size_override("font_size", 13)
	_vocab_import_btn.pressed.connect(_on_vocab_import_pressed)
	outer.add_child(_vocab_import_btn)

	_vocab_import_status = Label.new()
	_vocab_import_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vocab_import_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vocab_import_status.add_theme_font_size_override("font_size", 11)
	_vocab_import_status.modulate = Color(0.78, 0.92, 0.8, 1.0)
	outer.add_child(_vocab_import_status)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.add_filter("*.json", "JSON")
	_file_dialog.file_selected.connect(_on_vocab_import_file_selected)
	add_child(_file_dialog)

	_sync_vocab_study_prefs_from_settings()
	_rebuild_vocab_book_rows()


func _refresh_vocab_study_prefs_i18n() -> void:
	if _vocab_section_title:
		_vocab_section_title.text = I18N.tr_key("menu.vocab_study_section_title")
	if _vocab_daily_label:
		_vocab_daily_label.text = I18N.tr_key("menu.vocab_daily_cap_label")
	if _vocab_daily_hint:
		_vocab_daily_hint.text = I18N.tr_key("menu.vocab_daily_cap_hint")
	if _vocab_ord_label:
		_vocab_ord_label.text = I18N.tr_key("menu.vocab_ordered_batch_label")
	if _vocab_ord_hint:
		_vocab_ord_hint.text = I18N.tr_key("menu.vocab_ordered_batch_hint")
	if _vocab_review_mode_label:
		_vocab_review_mode_label.text = I18N.tr_key("menu.vocab_review_mode_label")
	if _vocab_review_mode_hint:
		_vocab_review_mode_hint.text = I18N.tr_key("menu.vocab_review_mode_hint")
	if _vocab_review_mode_opt:
		_populate_vocab_review_mode_option(str(Global.user_settings_data.settings_vocab_combat_review_mode))
	if _vocab_style_sub:
		_vocab_style_sub.text = I18N.tr_key("menu.vocab_example_style_sub")
	if _vocab_custom_domain:
		_vocab_custom_domain.placeholder_text = I18N.tr_key("overlay.vocab_domains_custom")
	if _vocab_books_sub:
		_vocab_books_sub.text = I18N.tr_key("menu.vocab_books_sub")
	if _vocab_import_btn:
		_vocab_import_btn.text = I18N.tr_key("menu.vocab_import_json")
	for pid: String in _preset_id_to_checkbox.keys():
		var cb: CheckBox = _preset_id_to_checkbox[pid]
		cb.text = I18N.tr_key("vocab.domain." + pid)
	for bid: String in _book_id_to_checkbox.keys():
		_refresh_single_book_row_label(bid)


func _sync_vocab_study_prefs_from_settings() -> void:
	if _vocab_daily_spin:
		_vocab_daily_spin.set_value_no_signal(float(Global.user_settings_data.settings_vocab_daily_due_cap))
	if _vocab_ord_spin:
		_vocab_ord_spin.set_value_no_signal(float(Global.user_settings_data.settings_vocab_daily_ordered_example_words))
	if _vocab_review_mode_opt:
		_populate_vocab_review_mode_option(str(Global.user_settings_data.settings_vocab_combat_review_mode))
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


func _on_vocab_daily_cap_changed(v: float) -> void:
	Global.user_settings_data.settings_vocab_daily_due_cap = clampi(int(round(v)), 0, 300)
	FileLoader.save_user_settings()


func _on_vocab_ordered_example_words_changed(v: float) -> void:
	Global.user_settings_data.settings_vocab_daily_ordered_example_words = clampi(int(round(v)), 0, 200)
	FileLoader.save_user_settings()


func _populate_vocab_review_mode_option(select_mode: String) -> void:
	if _vocab_review_mode_opt == null:
		return
	_vocab_review_mode_opt.set_block_signals(true)
	_vocab_review_mode_opt.clear()
	var ids: Array[String] = [
		VocabStudy.VOCAB_REVIEW_MODE_SPELL,
		VocabStudy.VOCAB_REVIEW_MODE_MEANING,
		VocabStudy.VOCAB_REVIEW_MODE_MC4,
	]
	for mid: String in ids:
		_vocab_review_mode_opt.add_item(I18N.tr_key("vocab.review.mode_" + mid))
		_vocab_review_mode_opt.set_item_metadata(_vocab_review_mode_opt.item_count - 1, mid)
	var pick: int = 0
	for i in range(_vocab_review_mode_opt.item_count):
		if str(_vocab_review_mode_opt.get_item_metadata(i)) == select_mode:
			pick = i
			break
	_vocab_review_mode_opt.select(pick)
	_vocab_review_mode_opt.set_block_signals(false)


func _on_vocab_review_mode_selected(idx: int) -> void:
	if _vocab_review_mode_opt == null:
		return
	var m: Variant = _vocab_review_mode_opt.get_item_metadata(idx)
	Global.user_settings_data.settings_vocab_combat_review_mode = str(m)
	FileLoader.save_user_settings()


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


func _persist_vocab_custom_domain() -> void:
	var t: String = _vocab_custom_domain.text.strip_edges()
	Global.user_settings_data.settings_vocab_example_domain_custom = t
	FileLoader.save_user_settings()


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
		row.add_theme_constant_override("separation", 6)
		var cb := CheckBox.new()
		cb.name = "Book_" + bid
		cb.add_theme_font_size_override("font_size", 12)
		cb.button_pressed = Global.user_settings_data.settings_vocab_enabled_book_ids.has(bid)
		cb.toggled.connect(_on_book_toggled.bind(bid))
		row.add_child(cb)
		_book_id_to_checkbox[bid] = cb
		var cap := Label.new()
		cap.name = "BookCap"
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cap.add_theme_font_size_override("font_size", 12)
		cap.text = _book_row_caption(meta)
		row.add_child(cap)
		_vocab_books_box.add_child(row)


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
		if src_disp.is_empty():
			return bid
		return I18N.tr_key("menu.vocab_book_row_id_only", [bid, src_disp])
	if src_disp.is_empty():
		return I18N.tr_key("menu.vocab_book_row_two", [nm, bid])
	return I18N.tr_key("menu.vocab_book_row_named", [nm, bid, src_disp])


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
			return
		while arr.has(book_id):
			arr.erase(book_id)
	Global.user_settings_data.settings_vocab_enabled_book_ids = arr
	FileLoader.save_user_settings()
	VocabStudy.reload_from_settings()
	call_deferred("_rebuild_vocab_book_rows")


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
	else:
		if _vocab_import_status:
			_vocab_import_status.text = I18N.tr_key("menu.vocab_import_failed")
