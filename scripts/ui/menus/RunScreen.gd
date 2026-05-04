# Base ui screen for a player's run
extends Control

func _ready() -> void:
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)

func _on_run_started():
	visible = true

func _on_run_ended():
	# Don't hide if RunSummaryOverlay is visible (showing end game summary)
	var summary_overlay = get_node_or_null("RunSummaryOverlay")
	if summary_overlay and summary_overlay.visible:
		# Keep RunScreen visible so summary can be seen
		return
	visible = false
