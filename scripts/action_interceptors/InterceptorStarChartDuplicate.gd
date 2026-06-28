extends BaseActionInterceptor
## House of Wisdom passive: duplicate the first card played each turn.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var bonuses := StarChartHelper.get_house_passive_bonus()
	if not bonuses.get("bonus_duplicate", false):
		return ACTION_ACCEPTENCES.CONTINUE
	var player := Global.get_player()
	if player == null:
		return ACTION_ACCEPTENCES.CONTINUE
	var already_duplicated: bool = Global.player_data.player_values.get("_wisdom_duplicated_this_turn", false)
	if already_duplicated:
		return ACTION_ACCEPTENCES.CONTINUE
	Global.player_data.player_values["_wisdom_duplicated_this_turn"] = true
	# Duplicate by re-emitting card play request
	var card_play_request: CardPlayRequest = processor.parent_action.card_play_request
	if card_play_request != null and card_play_request.card_data != null:
		var dup_request := CardPlayRequest.new()
		dup_request.card_data = card_play_request.card_data
		dup_request.selected_target = card_play_request.selected_target
		dup_request.is_duplicate_play = true
		Signals.card_play_requested.emit(dup_request, true, false)
	return ACTION_ACCEPTENCES.CONTINUE
