extends BaseArtifact
## Comet Shard: Whenever you consume a Star, gain 2 Block.

func connect_signals() -> void:
	super()
	Signals.star_consumed.connect(_on_star_consumed)

func _on_star_consumed(_house: int, _count: int) -> void:
	var player := Global.get_player()
	if player != null and player.is_alive():
		Global.player_data.player_block += 2
		Signals.combatant_block_added.emit(player)
