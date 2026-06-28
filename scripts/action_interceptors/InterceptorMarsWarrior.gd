extends BaseActionInterceptor
## Mars, the Warrior: +3 damage when a Star is in House of Noon.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = processor.parent_action.parent_combatant
	if parent_combatant == null:
		return ACTION_ACCEPTENCES.CONTINUE
	if parent_combatant.get_status_charges("status_effect_mars_warrior") <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	if StarChartHelper.get_star_count(1) > 0:
		var val: int = processor.get_shadowed_action_values("damage", 0)
		processor.shadowed_action_values["damage"] = val + 3
	return ACTION_ACCEPTENCES.CONTINUE
