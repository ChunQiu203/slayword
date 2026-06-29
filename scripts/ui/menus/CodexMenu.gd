## UI menu to display all content in the game such as all cards, enemies, relics, consumables
extends Control

@onready var title_screen: Control = $%TitleScreen
@onready var back_button: Button = $BackButton
@onready var codex_card_container: GridContainer = $ScrollContainer/MarginContainer/CodexCardContainer

# Tab buttons
@onready var btn_cards: Button = $VBoxContainer/Button
@onready var btn_enemies: Button = $VBoxContainer/Button2
@onready var btn_artifacts: Button = $VBoxContainer/Button3
@onready var btn_consumables: Button = $VBoxContainer/Button4

var current_tab: String = "cards"

# Progress bar for loading
var _progress_panel: PanelContainer = null
var _progress_bar: ProgressBar = null
var _progress_label: Label = null
var _loading: bool = false

func _ready():
	_build_progress_bar()
	for legacy in back_button.get_children():
		if legacy.name == "LocalizedTextLabel":
			legacy.queue_free()
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	SlayMobileStyle.style_button(back_button, "gold", SlayMobileStyle.FS_LG)
	back_button.pressed.connect(_on_back_button_up)

	# Enable all tab buttons
	btn_cards.disabled = false
	btn_enemies.disabled = false
	btn_artifacts.disabled = false
	btn_consumables.disabled = false

	# Connect tab buttons
	btn_cards.pressed.connect(_on_tab_pressed.bind("cards"))
	btn_enemies.pressed.connect(_on_tab_pressed.bind("enemies"))
	btn_artifacts.pressed.connect(_on_tab_pressed.bind("artifacts"))
	btn_consumables.pressed.connect(_on_tab_pressed.bind("consumables"))

	_apply_tab_styles()

	# Refresh UI when language changes
	I18N.locale_changed.connect(_on_locale_changed)


func _build_progress_bar() -> void:
	_progress_panel = PanelContainer.new()
	_progress_panel.name = "CodexProgressPanel"
	_progress_panel.visible = false
	_progress_panel.set_anchors_preset(Control.PRESET_CENTER)
	_progress_panel.offset_left = -180
	_progress_panel.offset_top = -40
	_progress_panel.offset_right = 180
	_progress_panel.offset_bottom = 60
	_progress_panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(
		Color(0.08, 0.09, 0.10, 0.95), SlayMobileStyle.BORDER_GOLD, 8))
	add_child(_progress_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_progress_panel.add_child(vbox)

	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	SlayMobileStyle.style_label(_progress_label, 14, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.custom_minimum_size = Vector2(300, 20)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_progress_bar)

func _on_locale_changed(_locale: String):
	_apply_tab_styles()
	populate_current_tab()

func populate_codex_menu() -> void:
	_apply_tab_styles()
	codex_card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_card_container.custom_minimum_size.x = 0
	_update_columns()
	# Recalculate columns when the window is resized
	var scroll = $ScrollContainer
	if scroll and not scroll.is_connected("resized", _update_columns):
		scroll.resized.connect(_update_columns)
	populate_current_tab()

func _update_columns():
	var total = $ScrollContainer.size.x
	# Subtract margins: left 10 + right 50 + scrollbar ~20 + grid spacing ~16
	var safe = total - 96
	var new_cols = clamp(int(safe / 160.0), 1, 5)
	if codex_card_container.columns != new_cols:
		codex_card_container.columns = new_cols
	print("CodexCols total=", total, " safe=", safe, " cols=", new_cols)

func populate_current_tab() -> void:
	if _loading:
		return
	_loading = true
	clear_codex_card_container()
	_show_progress(I18N.tr_key("codex.tab." + current_tab) + " ...")
	match current_tab:
		"cards":
			await _populate_cards_async()
		"enemies":
			await _populate_enemies_async()
		"artifacts":
			await _populate_artifacts_async()
		"consumables":
			await _populate_consumables_async()
	_hide_progress()
	_loading = false


func _show_progress(text: String) -> void:
	if _progress_panel == null:
		return
	_progress_label.text = text
	_progress_bar.value = 0.0
	_progress_panel.visible = true


func _hide_progress() -> void:
	if _progress_panel == null:
		return
	_progress_panel.visible = false


func _update_progress(current: int, total: int) -> void:
	if _progress_bar == null:
		return
	_progress_bar.max_value = float(total)
	_progress_bar.value = float(current)


func _on_tab_pressed(tab: String) -> void:
	current_tab = tab
	_apply_tab_styles()
	populate_current_tab()

func _apply_tab_styles() -> void:
	btn_cards.text = I18N.tr_key("codex.tab.cards")
	btn_enemies.text = I18N.tr_key("codex.tab.enemies")
	btn_artifacts.text = I18N.tr_key("codex.tab.artifacts")
	btn_consumables.text = I18N.tr_key("codex.tab.consumables")
	
	for btn in [btn_cards, btn_enemies, btn_artifacts, btn_consumables]:
		var is_active: bool = btn == get("btn_" + current_tab)
		SlayMobileStyle.style_button(btn, "gold" if is_active else "dark", 16)

func _populate_cards_async() -> void:
	var card_object_ids: Array = Global._id_to_card_data.keys()
	var total := card_object_ids.size()
	for i: int in card_object_ids.size():
		var card_data: CardData = Global.get_card_data(card_object_ids[i])
		var card: Card = Scenes.CARD.instantiate()
		codex_card_container.add_child(card)
		card.init(card_data, 0, false, false)
		# Yield every 10 items to keep UI responsive
		if i % 10 == 0:
			_update_progress(i + 1, total)
			await get_tree().process_frame
	_update_progress(total, total)

func _populate_enemies_async() -> void:
	var enemy_ids: Array = Global._id_to_enemy_data.keys()
	var total := enemy_ids.size()
	for i: int in enemy_ids.size():
		var enemy_data: EnemyData = Global.get_enemy_data(enemy_ids[i])
		if enemy_data == null:
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 160)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)

		if enemy_data.enemy_texture_path != "":
			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = FileLoader.load_texture(enemy_data.enemy_texture_path)
			texture_rect.custom_minimum_size = Vector2(100, 100)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox.add_child(texture_rect)

		var name_label: Label = Label.new()
		name_label.text = I18N.get_enemy_name(enemy_data)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)

		var hp_label: Label = Label.new()
		hp_label.text = "HP: %d" % enemy_data.enemy_health
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 12)
		hp_label.add_theme_color_override("font_color", Color.RED)
		vbox.add_child(hp_label)

		panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style())
		codex_card_container.add_child(panel)

		if i % 8 == 0:
			_update_progress(i + 1, total)
			await get_tree().process_frame
	_update_progress(total, total)

func _populate_artifacts_async() -> void:
	var artifact_ids: Array = Global._id_to_artifact_data.keys()
	var total := artifact_ids.size()
	for i: int in artifact_ids.size():
		var artifact_data: ArtifactData = Global.get_artifact_data(artifact_ids[i])
		if artifact_data == null:
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 160)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)

		if artifact_data.artifact_texture_path != "":
			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
			texture_rect.custom_minimum_size = Vector2(100, 100)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox.add_child(texture_rect)

		var name_label: Label = Label.new()
		name_label.text = I18N.get_artifact_name(artifact_data)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)

		var desc_label: Label = Label.new()
		var desc_text: String = I18N.get_artifact_description(artifact_data)
		if desc_text.length() > 30:
			desc_text = desc_text.substr(0, 27) + "..."
		desc_label.text = desc_text
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(desc_label)

		panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style())
		codex_card_container.add_child(panel)

		if i % 8 == 0:
			_update_progress(i + 1, total)
			await get_tree().process_frame
	_update_progress(total, total)

func _populate_consumables_async() -> void:
	var consumable_ids: Array = Global._id_to_consumable_data.keys()
	var total := consumable_ids.size()
	for i: int in consumable_ids.size():
		var consumable_data: ConsumableData = Global.get_consumable_data(consumable_ids[i])
		if consumable_data == null:
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 160)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)

		if consumable_data.consumable_texture_path != "":
			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = FileLoader.load_texture(consumable_data.consumable_texture_path)
			texture_rect.custom_minimum_size = Vector2(100, 100)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox.add_child(texture_rect)

		var name_label: Label = Label.new()
		name_label.text = I18N.get_consumable_name(consumable_data)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)

		var desc_label: Label = Label.new()
		var desc_text: String = I18N.get_consumable_description(consumable_data)
		if desc_text.length() > 30:
			desc_text = desc_text.substr(0, 27) + "..."
		desc_label.text = desc_text
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(desc_label)

		panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style())
		codex_card_container.add_child(panel)

		if i % 8 == 0:
			_update_progress(i + 1, total)
			await get_tree().process_frame
	_update_progress(total, total)

func clear_codex_card_container() -> void:
	for child in codex_card_container.get_children():
		child.queue_free()

func _on_back_button_up():
	clear_codex_card_container()
	title_screen.show_main_menu()
