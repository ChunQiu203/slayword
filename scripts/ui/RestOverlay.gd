# Overlay for actions at a rest site
extends Control

@onready var rest_action_container: GridContainer = $ScrollContainer/MarginContainer/RestActionContainer
@onready var continue_button: Button = $ContinueButton

@onready var map = $%Map

func _ready():
	I18N.locale_changed.connect(_on_locale_changed)
	Signals.combat_started.connect(_on_combat_started)

	Signals.map_location_selected.connect(_on_map_location_selected)
	for legacy in continue_button.get_children():
		if legacy.name == "LocalizedTextLabel":
			legacy.queue_free()
	continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_button.add_theme_font_size_override("font_size", 20)
	continue_button.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 1.0))
	continue_button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	continue_button.add_theme_constant_override("outline_size", 1)
	continue_button.pressed.connect(_on_continue_button_up)

func _on_locale_changed(_locale: String) -> void:
	for rest_action_button: RestActionButton in rest_action_container.get_children():
		rest_action_button.refresh_localized_text()

func _on_map_location_selected(_location_data: LocationData):
	if _location_data.location_type == LocationData.LOCATION_TYPES.REST_SITE:
		visible = true
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
			rest_action_button.rest_action_button_up.connect(_on_rest_action_button_up)
			rest_action_button.disabled = not rest_action_button.validate_rest_button()

func _on_rest_action_button_up(rest_action_button: RestActionButton):
	# perform actions
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_button.rest_action_object_id)
	if rest_action_data != null:
		var action_data: Array[Dictionary] = rest_action_data.rest_actions
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(null, null, [], action_data, null)
		ActionHandler.add_actions(generated_actions, false)
	
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
