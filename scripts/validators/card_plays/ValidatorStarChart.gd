extends BaseValidator
## Validates star chart conditions for card play.
## Checks: star_count (total), star_house_count (specific house), star_houses_occupied (how many houses have stars)

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var required_total: int = values.get("star_count", -1)
	var required_house: int = values.get("star_house", -1)
	var required_house_count: int = values.get("star_house_count", -1)
	var required_houses_occupied: int = values.get("star_houses_occupied", -1)
	
	var chart := StarChartHelper.get_star_chart()
	var total_stars := StarChartHelper.get_total_stars()
	
	# Check minimum total stars
	if required_total >= 0 and total_stars < required_total:
		return false
	
	# Check specific house has enough stars
	if required_house >= 0 and required_house_count >= 0:
		if int(chart[required_house]) < required_house_count:
			return false
	
	# Check how many houses are occupied
	if required_houses_occupied >= 0:
		var occupied := 0
		for c in chart:
			if int(c) > 0:
				occupied += 1
		if occupied < required_houses_occupied:
			return false
	
	return true
