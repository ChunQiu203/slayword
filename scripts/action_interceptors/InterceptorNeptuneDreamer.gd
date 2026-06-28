extends BaseActionInterceptor
## Neptune, the Dreamer: +1 draw when a Star is in House of Night.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = processor.parent_action.parent_combatant
	if parent_combatant == null:
		return ACTION_ACCEPTENCES.CONTINUE
	if parent_combatant.get_status_charges("status_effect_neptune_dreamer") <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	if StarChartHelper.get_star_count(3) > 0:
		var val: int = processor.get_shadowed_action_values("draw_count", 0)
		processor.shadowed_action_values["draw_count"] = val + 1
	return ACTION_ACCEPTENCES.CONTINUE
