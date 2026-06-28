extends BaseArtifact
## Constellation Globe: At combat start, place 1 extra Star in a random House.

func connect_signals() -> void:
	super()
	Signals.combat_started.connect(_on_combat_started)

func _on_combat_started(_event_id: String) -> void:
	StarChartHelper.place_star(randi_range(0, 5))
