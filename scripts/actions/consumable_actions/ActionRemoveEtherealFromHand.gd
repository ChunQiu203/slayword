extends BaseAction
## Remove Ethereal from all cards in hand.

func perform_action():
	var hand := Global.player_data.player_hand
	for card in hand:
		card.card_is_ethereal = false

func is_action_async() -> bool:
	return false
