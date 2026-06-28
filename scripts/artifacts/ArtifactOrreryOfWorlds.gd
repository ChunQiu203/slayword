extends BaseArtifact
## Orrery of Worlds: Constellation cards place 1 extra Star. Gain 1 less Energy per turn.

var _extra_star_this_play: bool = false

func connect_signals() -> void:
	super()
	Signals.star_placed.connect(_on_star_placed)
	Signals.card_played.connect(_on_card_played)
	Signals.player_turn_started.connect(_on_turn_start)

func _on_turn_start() -> void:
	if Global.player_data.player_energy > 0:
		Global.player_data.player_energy -= 1
		Signals.energy_added.emit(-1)

func _on_card_played(card_play_request: CardPlayRequest) -> void:
	_extra_star_this_play = false
	if card_play_request == null or card_play_request.card_data == null:
		return
	var card: CardData = card_play_request.card_data
	if card.card_type != 2:
		return
	if card.card_color_id != "color_blue":
		return
	_extra_star_this_play = true

func _on_star_placed(house: int) -> void:
	if _extra_star_this_play:
		_extra_star_this_play = false
		StarChartHelper.place_star(house)
