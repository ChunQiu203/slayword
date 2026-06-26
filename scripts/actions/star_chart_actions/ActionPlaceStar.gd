extends BaseAction
## Place a Star into a specific House of the Star Chart.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var house: int = aip.get_shadowed_action_values("star_house", 0)
		var count: int = aip.get_shadowed_action_values("star_count", 1)
		for _i in range(count):
			StarChartHelper.place_star(house)

func is_action_async() -> bool:
	return false
