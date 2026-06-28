extends BaseAsyncAction
## Async action: enters StarChartUI selection mode, awaits player's House choice,
## then triggers the Alignment effect for the chosen House.

var _chosen_house: int = -1

func perform_action():
	# Find the StarChartUI
	var player := Global.get_player()
	if player == null:
		action_async_finished.emit()
		return

	var star_chart_ui: StarChartUI = Global.player_data.player_values.get("_star_chart_ui_ref", null)
	if star_chart_ui == null:
		# Fallback: search player's custom_ui_container children
		for child in player.custom_ui_container.get_children():
			if child is StarChartUI:
				star_chart_ui = child
				break

	if star_chart_ui == null:
		action_async_finished.emit()
		return

	# Enter selection mode and wait for player choice
	async_awaiting = true
	_chosen_house = -1

	star_chart_ui.enter_selection_mode(func(house: int):
		_chosen_house = house
		async_awaiting = false
		perform_async_action()
	)

	# ActionHandler will await action_async_finished — we emit it in perform_async_action

func perform_async_action():
	if _chosen_house < 0 or _chosen_house > 5:
		action_async_finished.emit()
		return

	var stars := StarChartHelper.get_star_count(_chosen_house)
	if stars < 2:
		action_async_finished.emit()
		return

	# Delegate to the static trigger logic (which emits alignment_triggered) (defined in ActionTriggerAlignment)
	ActionTriggerAlignment.trigger_house_alignment(_chosen_house, stars)

	# Twin Destiny: double trigger for the designated house
	var player := Global.get_player()
	if player != null:
		var twin_house: int = int(Global.player_data.player_values.get("_twin_destiny_house", -1))
		if twin_house == _chosen_house:
			ActionTriggerAlignment.trigger_house_alignment(_chosen_house, stars)

	action_async_finished.emit()

func is_action_async() -> bool:
	return true

func force_action_end() -> void:
	if async_awaiting:
		var player := Global.get_player()
		if player != null:
			var star_chart_ui: StarChartUI = Global.player_data.player_values.get("_star_chart_ui_ref", null)
			if star_chart_ui != null:
				star_chart_ui.exit_selection_mode()
		async_awaiting = false
		_chosen_house = -1
		action_async_finished.emit()
