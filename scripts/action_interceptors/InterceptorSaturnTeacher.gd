extends BaseActionInterceptor
## Saturn, the Teacher: when a Star is in House of Wisdom, duplicate the played card.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = processor.parent_action.parent_combatant
	if parent_combatant == null:
		return ACTION_ACCEPTENCES.CONTINUE
	if parent_combatant.get_status_charges("status_effect_saturn_teacher") <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	if StarChartHelper.get_star_count(4) > 0:
		# Duplicate by re-emitting the card play request
		var card_play_request: CardPlayRequest = processor.parent_action.card_play_request
		if card_play_request != null and card_play_request.card_data != null:
			Signals.card_play_requested.emit(card_play_request.card_data, card_play_request.selected_target)
	return ACTION_ACCEPTENCES.CONTINUE
