extends BaseAction
class_name ActionTriggerAlignment
## Trigger the Alignment effect for a specific House.
## Instead of applying effects directly, adds a corresponding card to the player's hand.

const ALIGNMENT_CARDS: Array[String] = [
	"card_astrology_dawn_blessing",    # Dawn - +2 energy
	"card_astrology_noon_fury",        # Noon - AOE damage
	"card_astrology_dusk_guard",       # Dusk - block
	"card_astrology_night_whisper",    # Night - draw cards
	"card_astrology_wisdom_insight",   # Wisdom - upgrade card
	"card_astrology_fate_decree",      # Fate - all effects at half
]

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var house: int = aip.get_shadowed_action_values("star_house", 0)
		var stars := StarChartHelper.get_star_count(house)
		if stars < 2:
			return
		_add_alignment_card(house)
		# Twin Destiny: double trigger for the designated house
		var player := Global.get_player()
		if player != null:
			var twin_house: int = int(Global.player_data.player_values.get("_twin_destiny_house", -1))
			if twin_house == house:
				_add_alignment_card(house)

func _add_alignment_card(house: int) -> void:
	if house < 0 or house >= ALIGNMENT_CARDS.size():
		return
	var card_object_id: String = ALIGNMENT_CARDS[house]
	var card_data: CardData = Global.get_card_data_from_prototype(card_object_id)
	if card_data == null:
		return
	# Create a copy and add to hand
	var new_card: CardData = card_data.get_prototype(true)
	new_card.set_card_energy_cost_until_played(0)
	Global.player_data.player_hand.append(new_card)
	Signals.card_created.emit(new_card)
	Signals.alignment_triggered.emit(house, StarChartHelper.get_star_count(house))

static func trigger_house_alignment(house: int, stars: int) -> void:
	# Static version for direct calls (kept for compatibility)
	var card_object_id: String = ALIGNMENT_CARDS[house] if house < ALIGNMENT_CARDS.size() else ""
	if card_object_id.is_empty():
		return
	var card_data: CardData = Global.get_card_data_from_prototype(card_object_id)
	if card_data == null:
		return
	var new_card: CardData = card_data.get_prototype(true)
	new_card.set_card_energy_cost_until_played(0)
	Global.player_data.player_hand.append(new_card)
	Signals.card_created.emit(new_card)
	Signals.alignment_triggered.emit(house, stars)

func is_action_async() -> bool:
	return false
