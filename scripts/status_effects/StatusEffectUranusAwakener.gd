extends BaseStatusEffect
## Uranus, the Awakener: Each turn, move 1 random Star to an adjacent House.

func _connect_signals() -> void:
	super()
	if not Signals.player_turn_ended.is_connected(_on_player_turn_ended_uranus):
		Signals.player_turn_ended.connect(_on_player_turn_ended_uranus)

func _on_player_turn_ended_uranus() -> void:
	if StarChartHelper.get_star_count(5) <= 0:
		return
	var chart := StarChartHelper.get_star_chart()
	# Find a house with stars to move
	for i in range(6):
		if int(chart[i]) > 0:
			StarChartHelper.consume_stars(i, 1)
			var next_house := (i + 1) % 6
			StarChartHelper.place_star(next_house)
			break
