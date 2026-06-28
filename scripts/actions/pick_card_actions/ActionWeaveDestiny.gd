extends ActionPickCards
## Weave Destiny: Choose a card in hand (excluding self).
## It gains Retain. Next turn, it costs 0.

# Override to exclude the card being played from pickable cards
func _get_pickable_cards() -> Array:
	var cards := super()
	# Remove the card being played (this Weave Destiny card)
	var self_card: CardData = null
	if card_play_request != null:
		self_card = card_play_request.card_data
	if self_card != null:
		cards = cards.filter(func(c): return c != self_card)
	return cards

# After picking, apply Retain and 0-cost until next turn
func perform_async_action():
	if picked_cards.is_empty():
		action_async_finished.emit()
		return

	# Remove picked_cards before processing (standard pattern)
	var picked: Array = picked_cards.duplicate()
	picked_cards.clear()

	for card_data: CardData in picked:
		card_data.card_is_retained = true
		card_data.card_energy_cost_until_turn = 0

	action_async_finished.emit()
