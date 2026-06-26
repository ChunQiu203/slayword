extends BaseArtifact
## The Astrologer's starting relic. Places 2 Stars at combat start.
## At end of each turn, rotates all Stars clockwise and checks for Eclipse.

func connect_signals() -> void:
	super()
	Signals.combat_started.connect(_on_combat_started_astro)

func _on_combat_started_astro(_event_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in range(2):
		StarChartHelper.place_star(rng.randi_range(0, 5))

func _on_player_turn_ended() -> void:
	super()
	StarChartHelper.rotate_stars()
	if StarChartHelper.check_eclipse():
		StarChartHelper.trigger_eclipse()
