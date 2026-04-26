extends Node2D

func _ready() -> void:
	_apply_static_localization()
	I18N.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_locale: String) -> void:
	_apply_static_localization()

func _apply_static_localization() -> void:
	var label_updates: Dictionary = {
		"%TitleScreen/MainMenu/Label": "app.title",
		"%TitleScreen/MainMenu/VBoxContainer/ContinueButton": "menu.continue",
		"%TitleScreen/MainMenu/VBoxContainer/ForfeitRunButton": "menu.forfeit_run",
		"%TitleScreen/MainMenu/VBoxContainer/NewRunButton": "menu.new_game",
		"%TitleScreen/MainMenu/VBoxContainer/CodexButton": "menu.codex",
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
		"%RunScreen/Combat/Consumables/ConsumableActionDropdown/UseConsumableButton": "combat.use",
		"%RunScreen/Combat/Consumables/ConsumableActionDropdown/DiscardConsumableButton": "combat.discard",
		"%RunScreen/Combat/Chest/Label": "combat.chest",
		"%RunScreen/Combat/Shop/Label": "combat.shop",
		"%RunScreen/Combat/CardPicking/CardPickLabel": "combat.pick_x_cards",
		"%RunScreen/Combat/CardPicking/ConfirmPickButton": "combat.confirm",
		"%RunScreen/Combat/EndTurnButton": "combat.end_turn",
		"%RunScreen/Combat/SelectTargetLabel": "combat.select_target",
		"%RunScreen/Combat/TurnOverlay/TurnLabel": "combat.turn",
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
		"%RunScreen/Map/BackButton": "menu.back",
		"%RunScreen/PauseOverlay/Background2/VBoxContainer/ResumeButton": "overlay.resume",
		"%RunScreen/PauseOverlay/Background2/VBoxContainer/ReturnToTitleButton": "overlay.return_to_title",
		"%RunScreen/PauseOverlay/Background2/VBoxContainer/ForfeitRunButton": "menu.forfeit_run"
	}
	for node_path: String in label_updates.keys():
		var node := get_node_or_null(NodePath(node_path))
		if node != null:
			node.text = I18N.tr_key(label_updates[node_path])

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
