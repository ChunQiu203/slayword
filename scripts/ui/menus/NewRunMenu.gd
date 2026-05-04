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

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0
var _mobile_layout_built: bool = false
var _character_stats_line: Label


func _ready():
	_build_mobile_layout()
	for b in [start_run_button, back_button]:
		for legacy in b.get_children():
			if legacy.name == "LocalizedTextLabel":
				legacy.queue_free()
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 1.0))
		b.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
		b.add_theme_constant_override("outline_size", 1)
	SlayMobileStyle.style_button(start_run_button, "red", 22)
	SlayMobileStyle.style_button(back_button, "dark", 20)
	start_run_button.pressed.connect(_on_start_run_button_up)
	back_button.pressed.connect(_on_back_button_up)

	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)

	seed_input.text_changed.connect(_on_seed_input_text_changed)

	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	I18N.locale_changed.connect(_on_locale_changed)

	_apply_localized_text()


func _build_mobile_layout() -> void:
	if _mobile_layout_built:
		return
	_mobile_layout_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg: Control = get_node_or_null("Background") as Control
	if bg:
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left = 0
		bg.offset_top = 0
		bg.offset_right = 0
		bg.offset_bottom = 0

	var shade := ColorRect.new()
	shade.name = "MobileShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, 1)

	var margin := MarginContainer.new()
	margin.name = "MobileRoot"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 26
	margin.offset_top = 20
	margin.offset_right = -26
	margin.offset_bottom = -20
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	title_label.reparent(root)
	SlayMobileStyle.style_label(title_label, 30, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.custom_minimum_size.y = 42

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var board := VBoxContainer.new()
	board.add_theme_constant_override("separation", 10)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(board)

	var roster_panel := _new_mobile_panel(board, Color(0.035, 0.042, 0.038, 0.70), SlayMobileStyle.BORDER_GOLD, 8)
	character_button_container.reparent(roster_panel)
	character_button_container.custom_minimum_size = Vector2(0, 82)
	character_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_button_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var character_grid: GridContainer = character_button_container.get_node_or_null("GridContainer") as GridContainer
	if character_grid:
		character_grid.columns = 8
		character_grid.add_theme_constant_override("h_separation", 12)
		character_grid.add_theme_constant_override("v_separation", 8)

	var info_panel := _new_mobile_panel(board, Color(0.050, 0.058, 0.053, 0.82), SlayMobileStyle.BORDER_GOLD, 8)
	info_panel.add_theme_constant_override("separation", 8)
	character_name_label.reparent(info_panel)
	SlayMobileStyle.style_label(character_name_label, 26, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	character_health_label.visible = false
	character_money_label.visible = false
	_character_stats_line = Label.new()
	_character_stats_line.name = "CharacterStatsLine"
	_character_stats_line.custom_minimum_size.y = 28
	SlayMobileStyle.style_label(_character_stats_line, 18, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	info_panel.add_child(_character_stats_line)
	character_description_label.reparent(info_panel)
	character_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_description_label.custom_minimum_size.y = 40
	SlayMobileStyle.style_label(character_description_label, 16, SlayMobileStyle.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	var artifact_row := HBoxContainer.new()
	artifact_row.add_theme_constant_override("separation", 12)
	artifact_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_panel.add_child(artifact_row)
	character_artifact_texture_rect.reparent(artifact_row)
	character_artifact_texture_rect.custom_minimum_size = Vector2(56, 56)
	var artifact_text := VBoxContainer.new()
	artifact_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifact_text.add_theme_constant_override("separation", 4)
	artifact_row.add_child(artifact_text)
	character_artifact_name_label.reparent(artifact_text)
	character_artifact_description_label.reparent(artifact_text)
	SlayMobileStyle.style_label(character_artifact_name_label, 18)
	SlayMobileStyle.style_label(character_artifact_description_label, 15, SlayMobileStyle.TEXT_MUTED)

	var setup_panel := _new_mobile_panel(board, Color(0.036, 0.043, 0.041, 0.78), SlayMobileStyle.BORDER_MUTED, 8)
	setup_panel.add_theme_constant_override("separation", 8)
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_color", SlayMobileStyle.TEXT_MAIN)
	var setup_row := HBoxContainer.new()
	setup_row.add_theme_constant_override("separation", 12)
	setup_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_panel.add_child(setup_row)
	var difficulty_node: Control = decrease_difficulty_button.get_parent() as Control
	if difficulty_node:
		difficulty_node.reparent(setup_row)
		difficulty_node.custom_minimum_size = Vector2(260, 58)
		difficulty_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	seed_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_row.add_child(seed_row)
	seed_label.reparent(seed_row)
	seed_label.custom_minimum_size.x = 74
	SlayMobileStyle.style_label(seed_label, 18)
	seed_input.reparent(seed_row)
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SlayMobileStyle.style_line_edit(seed_input, 18)
	custom_modifiers_label.reparent(setup_panel)
	SlayMobileStyle.style_label(custom_modifiers_label, 17, SlayMobileStyle.TEXT_MAIN)
	custom_run_modifier_button_container.reparent(setup_panel)
	custom_run_modifier_button_container.custom_minimum_size = Vector2(0, 86)
	custom_run_modifier_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	root.add_child(action_row)
	back_button.reparent(action_row)
	start_run_button.reparent(action_row)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _new_mobile_panel(
	parent: Node,
	fill: Color = SlayMobileStyle.BG_PANEL,
	border: Color = SlayMobileStyle.BORDER_MUTED,
	radius: int = 8
) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(fill, border, radius))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	return box


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
	_apply_localized_text()

func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null:
		character_name_label.text = I18N.tr_data(character_data.object_id, "character_name", character_data.character_name)
		character_health_label.text = I18N.tr_key("menu.hp_prefix", [character_data.character_starting_health])
		character_money_label.text = I18N.tr_key("menu.money_prefix", [character_data.character_starting_money])
		if _character_stats_line:
			_character_stats_line.text = "%s     %s" % [character_health_label.text, character_money_label.text]
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
