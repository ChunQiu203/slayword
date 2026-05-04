extends Node

func _ready():
	print("Testing AI Statistics Feature...")

	# Test PlayerData statistics
	var player_data = preload("res://data/prototype/PlayerData.gd").new()
	player_data.init()

	# Test initial statistics
	print("Initial stats: ", player_data.get_statistics_for_summary())

	# Test adding some statistics
	player_data.run_statistics["cards_obtained"] = 5
	player_data.run_statistics["enemies_defeated"] = 3
	player_data.run_statistics["words_reviewed"] = 10
	player_data.run_statistics["words_correct"] = 8

	var stats = player_data.get_statistics_for_summary()
	print("Updated stats: ", stats)

	# Test statistics overlay
	var stats_overlay = preload("res://scripts/ui/RunStatisticsOverlay.gd").new()
	stats_overlay.show_statistics("VICTORY", stats["floor_reached"], stats["cards_obtained"], stats["enemies_defeated"], stats["damage_taken"], stats["words_reviewed"], stats["words_correct"], "")

	print("AI Statistics Feature test completed successfully!")