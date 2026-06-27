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

func _ready():
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

func populate_codex_menu() -> void:
	_apply_tab_styles()
	codex_card_container.columns = 4
	codex_card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_card_container.custom_minimum_size.x = 600
	populate_current_tab()

func populate_current_tab() -> void:
	clear_codex_card_container()
	match current_tab:
		"cards":
			populate_cards()
		"enemies":
			populate_enemies()
		"artifacts":
			populate_artifacts()
		"consumables":
			populate_consumables()

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

func populate_cards() -> void:
	var card_object_ids: Array = Global._id_to_card_data.keys()
	for card_object_id: String in card_object_ids:
		var card_data: CardData = Global.get_card_data(card_object_id)
		var card: Card = Scenes.CARD.instantiate()
		codex_card_container.add_child(card)
		card.init(card_data, 0, false, false)

func populate_enemies() -> void:
	var enemy_ids: Array = Global._id_to_enemy_data.keys()
	for enemy_id: String in enemy_ids:
		var enemy_data: EnemyData = Global.get_enemy_data(enemy_id)
		if enemy_data == null:
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 160)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)
		
		# Enemy texture
		if enemy_data.enemy_texture_path != "":
			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = FileLoader.load_texture(enemy_data.enemy_texture_path)
			texture_rect.custom_minimum_size = Vector2(100, 100)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox.add_child(texture_rect)
		
		# Enemy name
		var name_label: Label = Label.new()
		name_label.text = I18N.get_enemy_name(enemy_data)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)
		
		# Enemy HP
		var hp_label: Label = Label.new()
		hp_label.text = "HP: %d" % enemy_data.enemy_health
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 12)
		hp_label.add_theme_color_override("font_color", Color.RED)
		vbox.add_child(hp_label)
		
		panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style())
		codex_card_container.add_child(panel)

func populate_artifacts() -> void:
	var artifact_ids: Array = Global._id_to_artifact_data.keys()
	for artifact_id: String in artifact_ids:
		var artifact_data: ArtifactData = Global.get_artifact_data(artifact_id)
		if artifact_data == null:
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 160)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)
		
		# Artifact texture
		if artifact_data.artifact_texture_path != "":
			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
			texture_rect.custom_minimum_size = Vector2(100, 100)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox.add_child(texture_rect)
		
		# Artifact name
		var name_label: Label = Label.new()
		name_label.text = I18N.get_artifact_name(artifact_data)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)
		
		# Artifact description
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

func populate_consumables() -> void:
	var consumable_ids: Array = Global._id_to_consumable_data.keys()
	for consumable_id: String in consumable_ids:
		var consumable_data: ConsumableData = Global.get_consumable_data(consumable_id)
		if consumable_data == null:
			continue
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 160)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)
		
		# Consumable texture
		if consumable_data.consumable_texture_path != "":
			var texture_rect: TextureRect = TextureRect.new()
			texture_rect.texture = FileLoader.load_texture(consumable_data.consumable_texture_path)
			texture_rect.custom_minimum_size = Vector2(100, 100)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			vbox.add_child(texture_rect)
		
		# Consumable name
		var name_label: Label = Label.new()
		name_label.text = I18N.get_consumable_name(consumable_data)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)
		
		# Consumable description
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

func clear_codex_card_container() -> void:
	for child in codex_card_container.get_children():
		child.queue_free()

func _on_back_button_up():
	clear_codex_card_container()
	title_screen.show_main_menu()
