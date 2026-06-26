extends BaseAction
## Consume Stars from a specific House or from the most populous House.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var house: int = aip.get_shadowed_action_values("star_house", -1)
		var count: int = aip.get_shadowed_action_values("star_count", 1)
		var consumed := 0
		if house < 0:
			var chart = StarChartHelper.get_star_chart()
			var best_house := 0
			var best_count := 0
			for i in range(6):
				if int(chart[i]) > best_count:
					best_count = int(chart[i])
					best_house = i
			consumed = StarChartHelper.consume_stars(best_house, count)
		else:
			consumed = StarChartHelper.consume_stars(house, count)
		Global.player_data.player_values["_last_consumed"] = consumed

func is_action_async() -> bool:
	return false
