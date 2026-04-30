# Main menu on title screen
extends Control

@onready var title_screen: Control = $%TitleScreen

@onready var continue_button: TextureButton = $VBoxContainer/ContinueButton
@onready var forfeit_run_button: TextureButton = $VBoxContainer/ForfeitRunButton
@onready var new_run_button: TextureButton = $VBoxContainer/NewRunButton
@onready var codex_button: TextureButton = $VBoxContainer/CodexButton
@onready var language_button: TextureButton = $VBoxContainer/SettingsButton
@onready var exit_button: TextureButton = $VBoxContainer/ExitButton

func _ready():
	continue_button.button_up.connect(_on_continue_button_up)
	forfeit_run_button.button_up.connect(_on_forfeit_run_button_up)
	new_run_button.button_up.connect(_on_new_run_button_up)
	codex_button.button_up.connect(_on_codex_button_up)
	language_button.button_up.connect(_on_language_button_up)
	exit_button.button_up.connect(_on_exit_button_up)
	
	Signals.run_ended.connect(_on_run_ended)
	I18N.locale_changed.connect(_on_locale_changed)
	
	language_button.disabled = false
	update_continue_button_visibility()
	_update_language_button()

func _on_continue_button_up():
	FileLoader.autoload()

func _on_forfeit_run_button_up():
	FileLoader.delete_save()
	update_continue_button_visibility()

func _on_new_run_button_up():
	title_screen.show_new_run_menu()

func _on_codex_button_up():
	title_screen.show_codex_menu()

func _on_language_button_up():
	I18N.toggle_locale()

func _on_exit_button_up():
	get_tree().quit()

func update_continue_button_visibility() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	continue_button.visible = has_save_file
	forfeit_run_button.visible = has_save_file
	new_run_button.visible = not has_save_file

func _on_run_ended():
	# go back to tile screen on abandoned run, but not failed run
	var has_save_file: bool = FileLoader.has_save_file()
	visible = has_save_file
	update_continue_button_visibility()

func _on_locale_changed(_locale: String) -> void:
	_update_language_button()

func _update_language_button() -> void:
	if I18N.current_locale == "zh_CN":
		language_button.tooltip_text = I18N.tr_key("menu.language_switch_to_en")
	else:
		language_button.tooltip_text = I18N.tr_key("menu.language_switch_to_zh")
