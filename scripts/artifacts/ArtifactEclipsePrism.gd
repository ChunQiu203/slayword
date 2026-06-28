extends BaseArtifact
## Eclipse Prism: When Eclipse triggers, heal 10 HP.

func connect_signals() -> void:
	super()
	Signals.eclipse_triggered.connect(_on_eclipse_triggered)

func _on_eclipse_triggered(_total: int) -> void:
	var player := Global.get_player()
	if player != null and player.is_alive():
		Global.player_data.player_health = mini(
			Global.player_data.player_health + 10,
			Global.player_data.player_health_max
		)
		Signals.player_health_changed.emit()
