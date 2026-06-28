extends BaseArtifact
## Nebula Gem: When you place a Star, 50% chance for a second Star in the same House.

func connect_signals() -> void:
	super()
	Signals.star_placed.connect(_on_star_placed)

func _on_star_placed(house: int) -> void:
	var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_nebula_gem")
	if rng.randf() < 0.5:
		StarChartHelper.place_star(house)
