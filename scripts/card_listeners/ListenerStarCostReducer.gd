## Card listener that reduces energy cost based on total Star count.
## Each Star reduces cost by 1. Cost never goes below 0.
extends BaseCardListener

func _init(_parent_card: Card, _values: Dictionary = {}):
	super(_parent_card, _values)
	# Calculate cost immediately on creation
	_update_cost()

func _connect_signals():
	Signals.star_placed.connect(_on_star_changed)
	Signals.star_consumed.connect(_on_star_changed)

func _on_star_changed(_arg1 = null, _arg2 = null):
	_update_cost()

func _update_cost() -> void:
	var base_cost: int = card_data.get_card_energy_cost(false)
	var total_stars: int = StarChartHelper.get_total_stars()
	var max_reduce: int = values.get("max_reduce", 3)
	var reduction: int = mini(total_stars, max_reduce)
	var new_cost: int = maxi(base_cost - reduction, 0)
	if new_cost != card_data.get_card_energy_cost(true):
		card_data.set_card_energy_cost_until_played(new_cost)
