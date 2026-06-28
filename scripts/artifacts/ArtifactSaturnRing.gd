extends BaseArtifact
## Saturn's Ring: Stars in the House of Dusk give +2 extra Block per Star.
## Implemented via a player_values flag that the block interceptor reads.

func connect_signals() -> void:
	super()
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended_clean)

func _on_combat_started(_event_id: String) -> void:
	Global.player_data.player_values["_saturn_ring_active"] = true

func _on_combat_ended_clean() -> void:
	Global.player_data.player_values.erase("_saturn_ring_active")
