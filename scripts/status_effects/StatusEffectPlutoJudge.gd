extends BaseStatusEffect
## Pluto, the Judge: First enemy killed each combat gives bonus gold while a Star is in House of Fate.

var _used_this_combat: bool = false

func _connect_signals() -> void:
	super()
	if not Signals.combat_started.is_connected(_on_combat_started):
		Signals.combat_started.connect(_on_combat_started)
	if not Signals.enemy_killed.is_connected(_on_enemy_killed):
		Signals.enemy_killed.connect(_on_enemy_killed)

func _on_combat_started(_event_id: String) -> void:
	_used_this_combat = false

func _on_enemy_killed(_enemy: BaseCombatant) -> void:
	if _used_this_combat:
		return
	if StarChartHelper.get_star_count(5) <= 0:
		return
	_used_this_combat = true
	# Bonus gold equal to a standard combat reward
	Global.player_data.add_money(15)
