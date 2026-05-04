extends Node

func _ready():
	print("Testing fixed AI Statistics Feature...")

	# Test creating the statistics overlay
	var stats_overlay = preload("res://scripts/ui/RunStatisticsOverlay.gd").new()
	add_child(stats_overlay)

	# Test showing statistics
	stats_overlay.show_statistics(
		"VICTORY",
		5,  # floor
		12, # cards
		8,  # enemies
		150, # damage
		25, # words reviewed
		20, # words correct
		""  # death reason
	)

	print("Statistics overlay created successfully!")
	print("AI Statistics Feature test completed!")