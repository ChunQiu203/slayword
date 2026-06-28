extends BaseStatusEffect
## Singularity: When total stars == 1, triple all House passive bonuses.
## This status effect is checked by StarChartHelper.get_house_passive_bonus().

func _connect_signals() -> void:
	super()
	# No custom signal connections needed — StarChartHelper checks for this status
	pass
