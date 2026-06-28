extends BaseArtifact
## Dark Star: The first time you would die each combat, consume all Stars, heal to 1 HP, and gain 1 Intangible.

var _used: bool = false

func connect_signals() -> void:
	super()
	Signals.combat_started.connect(_on_combat_started)
	Signals.player_health_changed.connect(_on_player_health_changed)

func _on_combat_started(_event_id: String) -> void:
	_used = false

func _on_player_health_changed() -> void:
	if _used:
		return
	if Global.player_data.player_health <= 0:
		_used = true
		for i in range(6):
			StarChartHelper.consume_stars(i, 999)
		Global.player_data.player_health = 1
		var player := Global.get_player()
		if player != null:
			player.add_status_effect_charges("status_effect_negate_damage", 1)
		Signals.player_health_changed.emit()
