extends Control

@onready var resume_button: Button = %ResumeButton
@onready var return_to_title_button: Button = %ReturnToTitleButton
@onready var forfeit_run_button: Button = %ForfeitRunButton


func _ready() -> void:
	_strip_legacy_texture_button_labels()
	for b in [resume_button, return_to_title_button, forfeit_run_button]:
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		SlayMobileStyle.style_button(b, "dark", SlayMobileStyle.FS_MD)
	_apply_localized_text()
	I18N.locale_changed.connect(_on_locale_changed)

	resume_button.pressed.connect(_on_resume_button_pressed)
	return_to_title_button.pressed.connect(_on_return_to_title_button_pressed)
	forfeit_run_button.pressed.connect(_on_forfeit_run_button_pressed)

	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)

	Signals.game_paused.connect(_on_game_paused)
	Signals.game_unpaused.connect(_on_game_unpaused)


func _strip_legacy_texture_button_labels() -> void:
	for b in [resume_button, return_to_title_button, forfeit_run_button]:
		for child in b.get_children():
			if child.name == "LocalizedTextLabel" or child.name == "PauseButtonTextCenter":
				child.queue_free()

func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()

func _apply_localized_text() -> void:
	_set_pause_button_text(resume_button, I18N.tr_key("overlay.resume"))
	_set_pause_button_text(return_to_title_button, I18N.tr_key("overlay.return_to_title"))
	_set_pause_button_text(forfeit_run_button, I18N.tr_key("menu.forfeit_run"))

func _set_pause_button_text(button: Button, localized_text: String) -> void:
	button.text = localized_text
	# Only override font-size dynamically (SlayMobileStyle already set the base style)
	button.add_theme_font_size_override("font_size", _get_pause_button_font_size(localized_text))

func _get_pause_button_font_size(localized_text: String) -> int:
	if localized_text.length() >= 13:
		return 17
	if localized_text.length() >= 9:
		return 19
	return 21

func _on_run_started():
	visible = false

func _on_run_ended():
	visible = false

func _on_resume_button_pressed() -> void:
	Global.unpause_game()

func _on_return_to_title_button_pressed() -> void:
	Global.unpause_game()
	Global.end_run(Global.RUN_ENDS.QUIT)

func _on_forfeit_run_button_pressed() -> void:
	Global.unpause_game()
	Global.end_run(Global.RUN_ENDS.LOSS)

func _on_game_paused() -> void:
	visible = true
	_apply_localized_text()

func _on_game_unpaused() -> void:
	visible = false
