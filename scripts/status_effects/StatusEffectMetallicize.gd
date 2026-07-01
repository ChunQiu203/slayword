extends BaseStatusEffect
## Metallicize: At end of turn, gain block equal to charges

func perform_status_effect_actions() -> void:
	var block_amount: int = status_charges
	if block_amount <= 0:
		return
	
	var card_play_request: CardPlayRequest = _generate_status_effect_card_play_request()
	card_play_request.card_values["block"] = block_amount
	
	var action_data: Array[Dictionary] = [{
		"res://scripts/actions/ActionBlock.gd": {
			"target_override": 1,
			"time_delay": 0.0
		}
	}]
	
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(
		parent_combatant, card_play_request, [parent_combatant], action_data, null
	)
	ActionHandler.add_actions(generated_actions)
