extends Control

@onready var resume_button = $CenterContainer/VBoxContainer/MarginContainer/ResumeButton
@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenuButton

signal restart_requested
signal main_menu_requested

const SettingsMenu = preload("res://scenes/ui/settings_menu.tscn")
var _settings_instance: Control = null

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	hide()

func open() -> void:
	show()
	get_tree().paused = true
	resume_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false
	if _settings_instance != null:
		_settings_instance.queue_free()
		_settings_instance = null

func _on_resume_pressed() -> void:
	close()

func _on_restart_pressed() -> void:
	close()
	restart_requested.emit()

func _on_settings_pressed() -> void:
	if _settings_instance == null:
		_settings_instance = SettingsMenu.instantiate()
		add_child(_settings_instance)
		# Hide pause menu buttons behind the settings? 
		# Setting process_mode on settings might not be needed if this whole branch is PROCESS_MODE_ALWAYS.

func _on_main_menu_pressed() -> void:
	close()
	main_menu_requested.emit()
