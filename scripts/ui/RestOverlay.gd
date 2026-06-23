# Overlay for actions at a rest site
extends Control

@onready var rest_action_container: GridContainer = $ScrollContainer/MarginContainer/RestActionContainer
@onready var continue_button: Button = $ContinueButton

@onready var map = $%Map

var _layout_built: bool = false
var _title_label: Label
var _hint_label: Label
var _preview_label: Label
var _result_label: Label
var _result_panel: PanelContainer
var _pending_rest_action_id: String = ""
var _pending_result_handled: bool = false
var _health_before: int = 0
var _money_before: int = 0
var _consumables_before: Dictionary = {}

func _ready():
	_build_mobile_layout()
	I18N.locale_changed.connect(_on_locale_changed)
	Signals.combat_started.connect(_on_combat_started)
	Signals.card_upgraded.connect(_on_card_upgraded)
	Signals.card_removed_from_deck.connect(_on_card_removed_from_deck)
	Signals.consumable_added.connect(_on_consumable_added)
	Signals.map_location_selected.connect(_on_map_location_selected)
	for legacy in continue_button.get_children():
		if legacy.name == "LocalizedTextLabel":
			legacy.queue_free()
	continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	SlayMobileStyle.style_button(continue_button, "green", 22)
	continue_button.pressed.connect(_on_continue_button_up)
	_apply_localized_text()


func _build_mobile_layout() -> void:
	if _layout_built:
		return
	_layout_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg: TextureRect = get_node_or_null("Background") as TextureRect
	if bg:
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left = 0
		bg.offset_top = 0
		bg.offset_right = 0
		bg.offset_bottom = 0
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var shade := ColorRect.new()
	shade.name = "RestShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.30)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.name = "RestMobileRoot"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 28
	margin.offset_top = 24
	margin.offset_right = -28
	margin.offset_bottom = -22
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var header_panel := PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.035, 0.040, 0.038, 0.72), SlayMobileStyle.BORDER_GOLD, 8))
	root.add_child(header_panel)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 2)
	header_panel.add_child(header_box)

	_title_label = Label.new()
	SlayMobileStyle.style_label(_title_label, 30, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	header_box.add_child(_title_label)

	_hint_label = Label.new()
	SlayMobileStyle.style_label(_hint_label, 16, SlayMobileStyle.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	header_box.add_child(_hint_label)

	_result_panel = PanelContainer.new()
	_result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.022, 0.027, 0.026, 0.66), SlayMobileStyle.BORDER_MUTED, 7))
	root.add_child(_result_panel)

	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 5)
	_result_panel.add_child(result_box)

	_preview_label = Label.new()
	SlayMobileStyle.style_label(_preview_label, 17, SlayMobileStyle.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	result_box.add_child(_preview_label)

	_result_label = Label.new()
	SlayMobileStyle.style_label(_result_label, 18, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	result_box.add_child(_result_label)

	var actions_panel := PanelContainer.new()
	actions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.018, 0.022, 0.021, 0.46), Color(0.55, 0.45, 0.25, 0.74), 7))
	root.add_child(actions_panel)

	var scroll := get_node_or_null("ScrollContainer") as ScrollContainer
	if scroll:
		scroll.reparent(actions_panel)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rest_action_container.columns = 3
		rest_action_container.add_theme_constant_override("h_separation", 14)
		rest_action_container.add_theme_constant_override("v_separation", 14)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(button_row)
	continue_button.reparent(button_row)
	continue_button.custom_minimum_size = Vector2(260, SlayMobileStyle.TOUCH_H)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
	for rest_action_button: RestActionButton in rest_action_container.get_children():
		rest_action_button.refresh_localized_text()
		_apply_rest_action_button_text(rest_action_button)


func _apply_localized_text() -> void:
	if _title_label:
		_title_label.text = I18N.tr_key("rest.title")
	if _hint_label:
		_hint_label.text = I18N.tr_key("rest.hint")
	if _preview_label:
		_preview_label.text = I18N.tr_key("rest.preview.empty")
	if _result_label and _result_label.text.strip_edges().is_empty():
		_result_label.text = I18N.tr_key("rest.result.empty")
	continue_button.text = I18N.tr_key("overlay.continue")

func _on_map_location_selected(_location_data: LocationData):
	if _location_data.location_type == LocationData.LOCATION_TYPES.REST_SITE:
		visible = true
		_clear_result()
		populate_rest_actions()
	else:
		visible = false
		clear_rest_actions()

func populate_rest_actions() -> void:
	clear_rest_actions()
	
	# get the rest actions the player can perform
	var player_rest_action_object_ids: Array[String] = Global.player_data.player_available_rest_action_object_ids
	for rest_action_object_id in player_rest_action_object_ids:
		var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_object_id)
		if rest_action_data != null:
			var rest_action_button: RestActionButton = Scenes.REST_ACTION_BUTTON.instantiate()
			rest_action_container.add_child(rest_action_button)
			rest_action_button.init(rest_action_object_id)
			_style_rest_action_button(rest_action_button)
			_apply_rest_action_button_text(rest_action_button)
			rest_action_button.rest_action_button_up.connect(_on_rest_action_button_up)
			rest_action_button.mouse_entered.connect(_show_preview_for_action.bind(rest_action_object_id))
			rest_action_button.focus_entered.connect(_show_preview_for_action.bind(rest_action_object_id))
			rest_action_button.disabled = not rest_action_button.validate_rest_button()

func _style_rest_action_button(button: RestActionButton) -> void:
	button.custom_minimum_size = Vector2(250, 132)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	button.clip_text = true
	SlayMobileStyle.style_button(button, "dark", 23)


func _apply_rest_action_button_text(button: RestActionButton) -> void:
	var rest_action_data: RestActionData = Global.get_rest_action_data(button.rest_action_object_id)
	if rest_action_data == null:
		return
	var name := I18N.tr_data(rest_action_data.object_id, "rest_action_name", rest_action_data.rest_action_name).replace("\n", " ")
	button.text = "%s\n%s" % [name, _get_rest_action_brief(rest_action_data)]


func _on_rest_action_button_up(rest_action_button: RestActionButton):
	# perform actions
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_button.rest_action_object_id)
	if rest_action_data != null:
		_pending_rest_action_id = rest_action_button.rest_action_object_id
		_pending_result_handled = false
		_health_before = Global.player_data.player_health
		_money_before = Global.player_data.player_money
		_consumables_before = Global.player_data.player_consumable_slot_to_consumable_object_id.duplicate(true)
		_show_preview_for_action(_pending_rest_action_id)
		_set_result(I18N.tr_key("rest.result.waiting"), SlayMobileStyle.TEXT_MUTED)

		var action_data: Array[Dictionary] = rest_action_data.rest_actions
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(null, null, [], action_data, null)
		ActionHandler.add_actions(generated_actions, false)
		if generated_actions.size() > 0:
			await ActionHandler.actions_ended
		_finalize_pending_result()
	
		# disable buttons based on pressed button's exclusivity
		var rest_action_cost_type: int = rest_action_data.rest_action_cost_type
		
		if rest_action_cost_type == RestActionData.REST_ACTION_COST_TYPES.INCLUSIVE:
			# disable non repeatable free buttons after single use
			rest_action_button.excluded = true
		if rest_action_cost_type == RestActionData.REST_ACTION_COST_TYPES.EXCLUSIVE:
			# disable all exclusive buttons if action taken exclusive
			for other_button: RestActionButton in rest_action_container.get_children():
				var other_button_rest_action_data: RestActionData = Global.get_rest_action_data(other_button.rest_action_object_id)
				if other_button_rest_action_data.rest_action_cost_type == RestActionData.REST_ACTION_COST_TYPES.EXCLUSIVE:
					other_button.excluded = true
	
	# re-validate all rest buttons
	for button: RestActionButton in rest_action_container.get_children():
		button.disabled = not button.validate_rest_button()
		_apply_rest_action_button_text(button)


func _show_preview_for_action(rest_action_object_id: String) -> void:
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_object_id)
	if rest_action_data == null or _preview_label == null:
		return
	_preview_label.text = _get_rest_action_preview(rest_action_data)


func _set_result(text: String, color: Color = SlayMobileStyle.TEXT_MAIN) -> void:
	if _result_label:
		_result_label.text = text
		_result_label.add_theme_color_override("font_color", color)


func _clear_result() -> void:
	_pending_rest_action_id = ""
	_pending_result_handled = false
	if _preview_label:
		_preview_label.text = I18N.tr_key("rest.preview.empty")
	if _result_label:
		_result_label.text = I18N.tr_key("rest.result.empty")
		_result_label.add_theme_color_override("font_color", SlayMobileStyle.TEXT_MAIN)


func _finalize_pending_result() -> void:
	if _pending_result_handled:
		return
	var health_after := Global.player_data.player_health
	var money_after := Global.player_data.player_money
	match _pending_rest_action_id:
		"rest_action_rest":
			_pending_result_handled = true
			_set_result(I18N.tr_key("rest.result.heal", [
				max(0, health_after - _health_before),
				_health_before,
				health_after,
				Global.player_data.player_health_max,
			]))
		"rest_action_add_random_consumable":
			_pending_result_handled = true
			_set_result(I18N.tr_key("rest.result.consumable_full"), SlayMobileStyle.TEXT_WARN)
		"rest_action_archivist_study":
			_pending_result_handled = true
			_set_result(I18N.tr_key("rest.result.health_money", [
				max(0, health_after - _health_before),
				max(0, money_after - _money_before),
			]))
		_:
			_pending_result_handled = true
			_set_result(I18N.tr_key("rest.result.generic"))


func _on_card_upgraded(card_data: CardData) -> void:
	if not visible or _pending_rest_action_id != "rest_action_upgrade_card":
		return
	_pending_result_handled = true
	_set_result(I18N.tr_key("rest.result.upgrade", [
		card_data.get_card_name(),
		card_data.get_card_description(),
	]))


func _on_card_removed_from_deck(card_data: CardData) -> void:
	if not visible or _pending_rest_action_id != "rest_action_remove_cards":
		return
	_pending_result_handled = true
	_set_result(I18N.tr_key("rest.result.remove", [card_data.get_card_name()]))


func _on_consumable_added(_slot_index: int, consumable_object_id: String) -> void:
	if not visible or _pending_rest_action_id != "rest_action_add_random_consumable":
		return
	var consumable_data := Global.get_consumable_data(consumable_object_id)
	if consumable_data == null:
		return
	_pending_result_handled = true
	_set_result(I18N.tr_key("rest.result.consumable", [
		I18N.tr_data(consumable_data.object_id, "consumable_name", consumable_data.consumable_name),
		I18N.tr_data(consumable_data.object_id, "consumable_description", consumable_data.consumable_description),
	]))


func _get_rest_action_brief(rest_action_data: RestActionData) -> String:
	match rest_action_data.object_id:
		"rest_action_rest":
			return I18N.tr_key("rest.brief.heal", [_get_rest_heal_amount(rest_action_data)])
		"rest_action_upgrade_card":
			return I18N.tr_key("rest.brief.upgrade")
		"rest_action_remove_cards":
			return I18N.tr_key("rest.brief.remove")
		"rest_action_add_random_consumable":
			if Global.player_data.are_consumable_slots_full():
				return I18N.tr_key("rest.brief.consumable_full")
			return I18N.tr_key("rest.brief.consumable", [Global.player_data.get_empty_consumable_slot_count()])
		"rest_action_increase_attack_on_rest":
			return I18N.tr_key("rest.brief.damage")
		"rest_action_archivist_study":
			return I18N.tr_key("rest.brief.study")
	return I18N.tr_key("rest.brief.generic")


func _get_rest_action_preview(rest_action_data: RestActionData) -> String:
	match rest_action_data.object_id:
		"rest_action_rest":
			var heal_amount := _get_rest_heal_amount(rest_action_data)
			var after_health := mini(Global.player_data.player_health + heal_amount, Global.player_data.player_health_max)
			return I18N.tr_key("rest.preview.heal", [
				heal_amount,
				Global.player_data.player_health,
				after_health,
				Global.player_data.player_health_max,
			])
		"rest_action_upgrade_card":
			return I18N.tr_key("rest.preview.upgrade")
		"rest_action_remove_cards":
			return I18N.tr_key("rest.preview.remove")
		"rest_action_add_random_consumable":
			if Global.player_data.are_consumable_slots_full():
				return I18N.tr_key("rest.preview.consumable_full")
			return I18N.tr_key("rest.preview.consumable", [Global.player_data.get_empty_consumable_slot_count()])
		"rest_action_increase_attack_on_rest":
			return I18N.tr_key("rest.preview.damage")
		"rest_action_archivist_study":
			return I18N.tr_key("rest.preview.study")
	return I18N.tr_key("rest.preview.generic")


func _get_rest_heal_amount(rest_action_data: RestActionData) -> int:
	var values := _get_first_action_values(rest_action_data.rest_actions, Scripts.ACTION_HEAL_PERCENT)
	var percent := float(values.get("percentage_heal_amount", 0.0))
	var raw_heal := int(ceil(float(Global.player_data.player_health_max) * percent))
	return max(0, mini(raw_heal, Global.player_data.player_health_max - Global.player_data.player_health))


func _get_first_action_values(action_data: Array, script_path: String) -> Dictionary:
	for action_entry_v in action_data:
		var action_entry: Dictionary = action_entry_v
		for key_v in action_entry.keys():
			var key := str(key_v)
			if key == script_path:
				return action_entry[key_v]
			if key == Scripts.ACTION_PICK_CARDS:
				var values: Dictionary = action_entry[key_v]
				var child_action_data: Array = values.get("action_data", [])
				var child_values := _get_first_action_values(child_action_data, script_path)
				if not child_values.is_empty():
					return child_values
	return {}

func clear_rest_actions():
	for child in rest_action_container.get_children():
		child.queue_free()

func _on_combat_started(_event_id: String):
	visible = false
	clear_rest_actions()

func _on_continue_button_up():
	if not Global.is_end_of_run():
		map.can_travel = true
		map.show_map()
	else:
		visible = false
		Signals.run_victory.emit()
