extends BaseAction
## Grants strength (damage increase) equal to the status effect's charges

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		
		var strength_amount: int = action_interceptor_processor.get_shadowed_action_values("strength", 0)
		if strength_amount > 0:
			target.add_status_effect_charges("status_effect_damage_increase", strength_amount)
