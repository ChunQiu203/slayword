extends Control
class_name RunStatisticsOverlay

var _result_title: Label
var _subtitle: Label
var _core_stats: Label
var _route_text: Label
var _deck_text: Label
var _artifact_text: Label
var _vocab_text: Label
var _death_reason_label: Label
var _back_button: Button
var _finish_button: Button
var _section_titles: Dictionary = {}

var run_result: String = ""
var floor_reached: int = 0
var cards_obtained: int = 0
var enemies_defeated: int = 0
var damage_taken: int = 0
var words_reviewed: int = 0
var words_correct: int = 0
var death_reason: String = ""


func _ready() -> void:
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	I18N.locale_changed.connect(_on_locale_changed)
	visible = false
	_create_ui_elements()


func _create_ui_elements() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 34
	margin.offset_top = 26
	margin.offset_right = -34
	margin.offset_bottom = -24
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	_result_title = Label.new()
	SlayMobileStyle.style_label(_result_title, 34, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_result_title)

	_subtitle = Label.new()
	SlayMobileStyle.style_label(_subtitle, 17, SlayMobileStyle.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_subtitle)

	var board := PanelContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.040, 0.047, 0.044, 0.78), SlayMobileStyle.BORDER_GOLD, 8))
	root.add_child(board)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_core_stats = _add_section(content, "run.stats.core")
	_route_text = _add_section(content, "run.stats.route")
	_artifact_text = _add_section(content, "run.stats.artifacts")
	_deck_text = _add_section(content, "run.stats.deck")
	_vocab_text = _add_section(content, "run.stats.vocab")

	_death_reason_label = Label.new()
	SlayMobileStyle.style_label(_death_reason_label, 17, SlayMobileStyle.TEXT_WARN)
	_death_reason_label.visible = false
	content.add_child(_death_reason_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)

	_back_button = Button.new()
	_back_button.text = I18N.tr_key("menu.back")
	_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SlayMobileStyle.style_button(_back_button, "dark", 20)
	_back_button.pressed.connect(_on_back_button_up)
	buttons.add_child(_back_button)

	_finish_button = Button.new()
	_finish_button.text = I18N.tr_key("overlay.back_to_main_menu")
	_finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SlayMobileStyle.style_button(_finish_button, "red", 20)
	_finish_button.pressed.connect(_on_finish_button_up)
	buttons.add_child(_finish_button)
	_refresh_static_text()


func _add_section(parent: Node, title_key: String) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _summary_section_style())
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var title := Label.new()
	title.text = I18N.tr_key(title_key)
	SlayMobileStyle.style_label(title, 19, SlayMobileStyle.TEXT_MAIN)
	box.add_child(title)
	_section_titles[title_key] = title
	var body := Label.new()
	SlayMobileStyle.style_label(body, 17, SlayMobileStyle.TEXT_MUTED)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	return body


func _summary_section_style() -> StyleBoxFlat:
	var sb := SlayMobileStyle.panel_style(Color(0.015, 0.019, 0.018, 0.42), Color(0.54, 0.45, 0.25, 0.70), 6)
	sb.set_border_width_all(1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


func show_statistics(
	result: String,
	floor: int,
	cards: int,
	enemies: int,
	damage: int,
	words_review: int,
	words_correct_count: int,
	death_cause: String = ""
) -> void:
	run_result = result
	floor_reached = floor
	cards_obtained = cards
	enemies_defeated = enemies
	damage_taken = damage
	words_reviewed = words_review
	words_correct = words_correct_count
	death_reason = death_cause
	_update_display()
	visible = true


func _update_display() -> void:
	_refresh_static_text()
	match run_result:
		"VICTORY":
			_result_title.text = I18N.tr_key("run.stats.result_victory")
			_result_title.add_theme_color_override("font_color", Color(0.76, 0.95, 0.62, 1.0))
		"DEFEAT":
			_result_title.text = I18N.tr_key("run.stats.result_defeat")
			_result_title.add_theme_color_override("font_color", Color(1.0, 0.52, 0.48, 1.0))
		_:
			_result_title.text = I18N.tr_key("run.stats.result_quit")
			_result_title.add_theme_color_override("font_color", SlayMobileStyle.TEXT_MAIN)

	var char_name := Global.player_data.player_character_object_id
	var character_data: CharacterData = Global.get_character_data(char_name)
	if character_data:
		char_name = I18N.tr_data(character_data.object_id, "character_name", character_data.character_name)
	_subtitle.text = I18N.tr_key("run.stats.subtitle", [char_name, Global.player_data.player_run_difficulty_level, Global.player_data.player_run_seed])

	_core_stats.text = I18N.tr_key("run.stats.core_body", [
		floor_reached,
		cards_obtained,
		enemies_defeated,
		damage_taken,
	])
	_route_text.text = _format_route(Global.player_data.get_run_route_summary())
	_artifact_text.text = _format_named_list(Global.player_data.get_artifact_summary_for_history(), "run.stats.none_artifacts", 18)
	_deck_text.text = _format_deck(Global.player_data.get_deck_summary_for_history(), 18)
	_vocab_text.text = _format_vocab()
	_death_reason_label.visible = run_result == "DEFEAT" and not death_reason.strip_edges().is_empty()
	if _death_reason_label.visible:
		_death_reason_label.text = I18N.tr_key("run.stats.death_reason", [death_reason])


func _refresh_static_text() -> void:
	for title_key in _section_titles.keys():
		var title := _section_titles[title_key] as Label
		if is_instance_valid(title):
			title.text = I18N.tr_key(title_key)
	if _back_button:
		_back_button.text = I18N.tr_key("menu.back")
	if _finish_button:
		_finish_button.text = I18N.tr_key("overlay.back_to_main_menu")


func _on_locale_changed(_locale: String) -> void:
	_update_display()


func _format_route(route: Array[Dictionary]) -> String:
	if route.is_empty():
		return I18N.tr_key("run.stats.none_route")
	var parts: PackedStringArray = []
	for i in range(mini(route.size(), 20)):
		var item := route[i]
		parts.append(I18N.tr_key("run.stats.route_item", [
			int(item.get("floor", 0)),
			_location_type_label(str(item.get("type", ""))),
		]))
	if route.size() > 20:
		parts.append(I18N.tr_key("run.stats.more", [route.size() - 20]))
	return "  ".join(parts)


func _format_named_list(items: Array[Dictionary], empty_key: String, limit: int) -> String:
	if items.is_empty():
		return I18N.tr_key(empty_key)
	var parts: PackedStringArray = []
	for i in range(mini(items.size(), limit)):
		parts.append(str(items[i].get("name", items[i].get("id", ""))))
	if items.size() > limit:
		parts.append(I18N.tr_key("run.stats.more", [items.size() - limit]))
	return " / ".join(parts)


func _format_deck(items: Array[Dictionary], limit: int) -> String:
	if items.is_empty():
		return I18N.tr_key("run.stats.none_deck")
	var parts: PackedStringArray = []
	for i in range(mini(items.size(), limit)):
		var item := items[i]
		var name := str(item.get("name", item.get("id", "")))
		var count := int(item.get("count", 1))
		if count > 1:
			parts.append("%s x%d" % [name, count])
		else:
			parts.append(name)
	if items.size() > limit:
		parts.append(I18N.tr_key("run.stats.more", [items.size() - limit]))
	return " / ".join(parts)


func _format_vocab() -> String:
	var accuracy := 0
	if words_reviewed > 0:
		accuracy = int(float(words_correct) / float(words_reviewed) * 100.0)
	var vocab_stats := VocabStudy.get_vocab_dashboard_stats()
	return I18N.tr_key("run.stats.vocab_body", [
		words_reviewed,
		words_correct,
		accuracy,
		int(vocab_stats.get("learned_words", 0)),
		int(vocab_stats.get("total_words", 0)),
		int(vocab_stats.get("example_ready_words", 0)),
	])


func _location_type_label(type_name: String) -> String:
	return I18N.tr_key("run.location." + type_name.to_lower())


func _on_run_started() -> void:
	visible = false


func _on_run_ended() -> void:
	visible = false


func _on_back_button_up() -> void:
	visible = false


func _on_finish_button_up() -> void:
	visible = false
	var run_screen = get_node_or_null("/root/Root/RunScreen")
	if run_screen:
		run_screen.visible = false
	var end_state := Global.RUN_ENDS.QUIT
	if run_result == "VICTORY":
		end_state = Global.RUN_ENDS.VICTORY
	elif run_result == "DEFEAT":
		end_state = Global.RUN_ENDS.LOSS
	Global.end_run(end_state)
