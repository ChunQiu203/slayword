extends BaseArtifact
## Mercury's Quill: The first card you play each turn costs 0.

var _used_this_turn: bool = false

func connect_signals() -> void:
	super()
	Signals.player_turn_started.connect(_on_turn_start)
	Signals.card_played.connect(_on_card_played)

func _on_turn_start() -> void:
	_used_this_turn = false

func _on_card_played(card_play_request: CardPlayRequest) -> void:
	if _used_this_turn:
		return
	if card_play_request != null and card_play_request.card_data != null:
		card_play_request.card_data.set_card_energy_cost_until_played(0)
		_used_this_turn = true
