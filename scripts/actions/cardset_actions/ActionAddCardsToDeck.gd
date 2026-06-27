# Action add given cards to your permanent deck
extends BaseCardsetAction

func perform_action() -> void:
	var picked_cards: Array[CardData] = _get_picked_cards()
	for card_data in picked_cards:
		# Store localized card info for dialogue display
		Global.event_last_traded_card_name = I18N.get_card_name(card_data)
		Global.event_last_traded_card_description = I18N.get_card_description(card_data)
		Global.player_data.add_card_to_deck(card_data)
