extends BaseArtifact
## Jupiter's Favor: When you place a Star in an empty House, gain 1 Energy.

func connect_signals() -> void:
	super()
	Signals.star_placed.connect(_on_star_placed)

func _on_star_placed(house: int) -> void:
	var chart := StarChartHelper.get_star_chart()
	if int(chart[house]) == 1:
		Global.player_data.player_energy += 1
		Signals.energy_added.emit(1)
