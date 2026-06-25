extends Node2D

const TEXTURE_BUTTON_LABEL_NAME := "LocalizedTextLabel"
const MIN_WINDOW_WIDTH := 960
const MIN_WINDOW_HEIGHT := 540

func _ready() -> void:
	# Enforce minimum window size
	get_window().min_size = Vector2i(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)
	# Notify SlayMobileStyle of initial viewport size for font scaling
	_update_viewport_ref_size()
	get_window().size_changed.connect(_update_viewport_ref_size)

	_apply_base_theme()
	_apply_static_localization()
	I18N.locale_changed.connect(_on_locale_changed)

func _update_viewport_ref_size() -> void:
	# In viewport stretch mode the game always renders at 1280×720.
	# Font scaling uses this as the baseline (scale = 1.0 at 720p).
	SlayMobileStyle.set_viewport_ref(Vector2i(1280, 720))

func _apply_base_theme() -> void:
	# Load custom fonts (best-effort — falls back to system fonts)
	SlayMobileStyle.load_fonts()

	# Build a base Theme so every child inherits font & colour defaults.
	# Apply to both top-level Control nodes so ALL UI benefits.
	var base_theme := SlayMobileStyle.create_base_theme()
	for unique_name in ["TitleScreen", "RunScreen"]:
		var ctrl := get_node_or_null(NodePath("%" + unique_name)) as Control
		if ctrl != null:
			ctrl.theme = base_theme

func _on_locale_changed(_locale: String) -> void:
	_apply_static_localization()

func _apply_static_localization() -> void:
	var label_updates: Dictionary = {
		"%TitleScreen/MainMenu/Label": "app.title",
		"%TitleScreen/MainMenu/VBoxContainer/ContinueButton": "menu.continue",
		"%TitleScreen/MainMenu/VBoxContainer/ForfeitRunButton": "menu.forfeit_run",
		"%TitleScreen/MainMenu/VBoxContainer/NewRunButton": "menu.new_game",
		"%TitleScreen/MainMenu/VBoxContainer/CodexButton": "menu.codex",
		"%TitleScreen/MainMenu/VBoxContainer/VocabPrefsButton": "menu.vocab_prefs_button",
		"%TitleScreen/MainMenu/VBoxContainer/SettingsButton": "menu.setting",
		"%TitleScreen/MainMenu/VBoxContainer/ExitButton": "menu.exit",
		"%TitleScreen/NewRunMenu/Label": "menu.new_run",
		"%TitleScreen/NewRunMenu/CharacterNameLabel": "menu.character_name",
		"%TitleScreen/NewRunMenu/CharacterHealthLabel": "menu.hp_label",
		"%TitleScreen/NewRunMenu/CharacterMoneyLabel": "menu.money_label",
		"%TitleScreen/NewRunMenu/CharacterDescriptionLabel": "menu.character_description",
		"%TitleScreen/NewRunMenu/CharacterArtifactNameLabel": "menu.artifact_name",
		"%TitleScreen/NewRunMenu/CharacterArtifactDescriptionLabel": "menu.artifact_description",
		"%TitleScreen/NewRunMenu/Label3": "menu.seed",
		"%TitleScreen/NewRunMenu/Label4": "menu.custom_modifiers",
		"%TitleScreen/NewRunMenu/StartRunButton": "menu.start_run",
		"%TitleScreen/NewRunMenu/BackButton": "menu.back",
		"%TitleScreen/CodexMenu/BackButton": "menu.back",
		"%TitleScreen/CodexMenu/VBoxContainer/Button": "menu.cards",
		"%TitleScreen/CodexMenu/VBoxContainer/Button2": "menu.enemies",
		"%TitleScreen/CodexMenu/VBoxContainer/Button3": "menu.artifacts",
		"%TitleScreen/CodexMenu/VBoxContainer/Button4": "menu.consumables",
		"%TitleScreen/VocabPrefsMenu/Label": "menu.vocab_prefs_title",
		"%TitleScreen/VocabPrefsMenu/BackButton": "menu.back",
		"%RunScreen/Combat/Consumables/ConsumableActionDropdown/UseConsumableButton": "combat.use",
		"%RunScreen/Combat/Consumables/ConsumableActionDropdown/DiscardConsumableButton": "combat.discard",
		"%RunScreen/Combat/Chest/Label": "combat.chest",
		"%RunScreen/Combat/Shop/Label": "combat.shop",
		"%RunScreen/Combat/CardPicking/CardPickLabel": "combat.pick_x_cards",
		"%RunScreen/Combat/CardPicking/ConfirmPickButton": "combat.confirm",
		"%RunScreen/Combat/EndTurnButton": "combat.end_turn",
		"%RunScreen/Combat/SelectTargetLabel": "combat.select_target",
		"%RunScreen/RestOverlay/ContinueButton": "overlay.continue",
		"%RunScreen/ShopOverlay/ContinueButton": "overlay.continue",
		"%RunScreen/RunSummaryOverlay/VictoryLabel": "overlay.victory",
		"%RunScreen/RunSummaryOverlay/DefeatLabel": "overlay.defeat",
		"%RunScreen/RunSummaryOverlay/EndRunButton": "overlay.back_to_main_menu",
		"%RunScreen/RewardOverlay/ContinueButton": "overlay.continue",
		"%RunScreen/CardSelectionOverlay/BackButton": "menu.back",
		"%RunScreen/CardSelectionOverlay/ConfirmButton": "combat.confirm",
		"%RunScreen/CardSelectionOverlay/CardPickLabel": "combat.pick_cards",
		"%RunScreen/CardDraftSelectionOverlay/SkipButton": "overlay.skip",
		"%RunScreen/PauseOverlay/Background2/VBoxContainer/ResumeButton": "overlay.resume",
		"%RunScreen/PauseOverlay/Background2/VBoxContainer/ReturnToTitleButton": "overlay.return_to_title",
		"%RunScreen/PauseOverlay/Background2/VBoxContainer/ForfeitRunButton": "menu.forfeit_run"
	}
	for node_path: String in label_updates.keys():
		var node := get_node_or_null(NodePath(node_path))
		if node != null:
			_apply_localized_text(node, I18N.tr_key(label_updates[node_path]))

	var tooltip_updates: Dictionary = {
		"%RunScreen/Combat/Energy": "combat.energy",
		"%RunScreen/Combat/DrawPile": "combat.draw_pile",
		"%RunScreen/Combat/DiscardPile": "combat.discard_pile",
		"%RunScreen/Combat/ExhaustPile": "combat.exhaust_pile"
	}
	for node_path: String in tooltip_updates.keys():
		var node := get_node_or_null(NodePath(node_path))
		if node != null:
			node.tooltip_text = I18N.tr_key(tooltip_updates[node_path])

func _apply_localized_text(node: Node, localized_text: String) -> void:
	if node is TextureButton:
		_set_texture_button_label(node as TextureButton, localized_text)
	elif node is Button:
		(node as Button).text = localized_text
	elif node is Label:
		(node as Label).text = localized_text
	elif node is RichTextLabel:
		(node as RichTextLabel).text = localized_text

func _set_texture_button_label(button: TextureButton, localized_text: String) -> void:
	var label := button.get_node_or_null(TEXTURE_BUTTON_LABEL_NAME) as Label
	if label == null:
		label = Label.new()
		label.name = TEXTURE_BUTTON_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		button.add_child(label)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.offset_left = 0.0
		label.offset_top = 0.0
		label.offset_right = 0.0
		label.offset_bottom = 0.0

	label.text = localized_text
	_resize_texture_button_label(button, label)
	call_deferred("_resize_texture_button_label", button, label)
	label.add_theme_font_size_override("font_size", _get_texture_button_font_size(localized_text))
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("outline_size", 1)

func _resize_texture_button_label(button: TextureButton, label: Label) -> void:
	if not is_instance_valid(button) or not is_instance_valid(label):
		return
	label.position = Vector2.ZERO
	label.size = button.size

func _get_texture_button_font_size(localized_text: String) -> int:
	if localized_text.length() >= 13:
		return 17
	if localized_text.length() >= 9:
		return 19
	return 21
