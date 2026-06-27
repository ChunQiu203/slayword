## Action to pick cards then upgrade them.
## Can be used to target a combat card, a combat card's parent with upgrade_parent_card flag (permanent),
## or directly target the player's deck using CARD_PICK_TYPES.DECK (permanent).
## NOTE: This action simply provides an easy wrapper for picking cards to upgrade under one action.
## For more control you'll want to use validators and ActionUpgradeCards with ActionPickCards
extends ActionBasePickCards

func perform_async_action() -> void:
	var upgrade_parent_card: bool = get_action_value("upgrade_parent_card", false)
	for card in picked_cards:
		# Store localized card info before upgrade for dialogue display
		Global.event_last_upgraded_card_name = I18N.get_card_name(card)
		Global.event_last_upgraded_card_description = I18N.get_card_description(card)
		card.upgrade_card()
		if upgrade_parent_card and card.parent_card != null:
			card.parent_card.upgrade_card()
			Global.event_last_upgraded_card_name = I18N.get_card_name(card.parent_card)
			Global.event_last_upgraded_card_description = I18N.get_card_description(card.parent_card)
			
	action_async_finished.emit()

func is_card_pickable(_card: CardData) -> bool:
	# determine if cards can qualify for user upgrade selection
	var max_card_amount: int = get_action_value("max_card_amount", PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
	var upgrade_parent_card: bool = get_action_value("upgrade_parent_card", false)	# This should be false if using CARD_PICK_TYPES.DECK
	
	# determine to check the card or its parent
	var card: CardData = _card
	if upgrade_parent_card:
		if card.parent_card == null:
			print("No parent card exists")
			return false
		else:
			card = card.parent_card
	
	# check if the card can be upgraded
	if card.card_upgrade_amount >= _card.card_upgrade_amount_max:
		return false
	
	if len(picked_cards) >= max_card_amount:
		return false
	return true	# by default all cards are pickable
