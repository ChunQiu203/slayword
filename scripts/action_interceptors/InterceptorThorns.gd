extends BaseActionInterceptor
## Thorns: When the parent combatant is attacked, deal damage back to the attacker

const THORNS_STATUS_EFFECT_ID: String = "status_effect_thorns"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = action_interceptor_processor.parent_action.parent_combatant
	if parent_combatant == null or not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	
	# Only trigger on damage actions targeting us
	var target: BaseCombatant = action_interceptor_processor.target
	if target == null or target != parent_combatant:
		return ACTION_ACCEPTENCES.CONTINUE
	
	var damage: int = action_interceptor_processor.get_shadowed_action_values("damage", 0)
	if damage <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	
	if _preview_mode:
		return ACTION_ACCEPTENCES.CONTINUE
	
	# Deal thorns damage back to the attacker
	var thorns_charges: int = parent_combatant.get_status_charges(THORNS_STATUS_EFFECT_ID)
	if thorns_charges > 0:
		var card_play_request: CardPlayRequest = action_interceptor_processor.parent_action.card_play_request
		var action_data: Array[Dictionary] = [{
			"res://scripts/actions/ActionDirectDamage.gd": {
				"damage": thorns_charges,
				"target_override": 0,
				"time_delay": 0.1
			}
		}]
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(
			parent_combatant, card_play_request, [parent_combatant], action_data, null
		)
		ActionHandler.add_actions(generated_actions)
	
	return ACTION_ACCEPTENCES.CONTINUE
