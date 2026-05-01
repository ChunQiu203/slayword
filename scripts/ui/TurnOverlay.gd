extends Control

@onready var turn_label: Label = $TurnLabel

func _ready() -> void:
	I18N.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_locale: String) -> void:
	if Global.is_player_in_combat():
		update_turn_label()

func update_turn_label() -> void:
	# called from animation player
	turn_label.text = I18N.tr_key("combat.turn", [Global.get_combat_stats().turn_count])
