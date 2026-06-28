extends BaseArtifact
## Lens of Clarity: Whenever you Scry, Scry 1 additional card.

func connect_signals() -> void:
	super()
	Signals.card_pick_requested.connect(_on_card_pick_requested)

func _on_card_pick_requested(pick_action) -> void:
	if pick_action == null:
		return
	var pick_type: int = pick_action.get_card_pick_type()
	if pick_type != 0:
		return
	var current_max: int = pick_action.get_card_pick_max_amount()
	pick_action.values["max_card_amount"] = current_max + 1
