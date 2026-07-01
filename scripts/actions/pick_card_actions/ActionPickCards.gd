## General use pick cards action that generates cardset related sub actions.
## Use this for making child cardset actions with action_data and they can use this as their parent to access picked_cards
extends ActionBasePickCards
class_name ActionPickCards

func perform_async_action() -> void:
	print("PICK_CARDS: perform_async_action picked_count=", picked_cards.size())
	for c in picked_cards:
		print("PICK_CARDS: picked=", I18N.get_card_name(c))
	_generate_child_actions()
	action_async_finished.emit()

func _generate_child_actions() -> void:
	var action_data: Array[Dictionary] = []
	
	var child_action_data: Array = get_action_value("action_data", [])
	action_data.assign(child_action_data)
	
	print("PICK_CARDS: generating ", action_data.size(), " child actions")
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, targets, action_data, self)
	print("PICK_CARDS: generated ", generated_actions.size(), " actions, parent_self=", self)
	ActionHandler.add_actions(generated_actions)
