extends BaseAction
## Grants block equal to the status effect's charges

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		
		var block_amount: int = action_interceptor_processor.get_shadowed_action_values("block", 0)
		if block_amount > 0:
			target.add_block(block_amount)
