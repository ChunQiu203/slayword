extends BaseAction
## Consume 1 Star from each House that has at least 1 Star.
## Total consumed count is stored in player_values["_star_consumed_count"].

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for _aip in action_interceptor_processors:
		var total_consumed := 0
		for h in range(6):
			var taken := StarChartHelper.consume_stars(h, 1)
			total_consumed += taken
		Global.player_data.player_values["_star_consumed_count"] = total_consumed

func is_action_async() -> bool:
	return false
