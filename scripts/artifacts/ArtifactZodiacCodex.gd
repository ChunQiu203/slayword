extends BaseArtifact
## Zodiac Codex: At start of turn, if any House has 3+ Stars, gain 1 Energy.

func connect_signals() -> void:
	super()
	Signals.player_turn_started.connect(_on_turn_start)

func _on_turn_start() -> void:
	var chart := StarChartHelper.get_star_chart()
	for c in chart:
		if int(c) >= 3:
			Global.player_data.player_energy += 1
			Signals.energy_added.emit(1)
			return
