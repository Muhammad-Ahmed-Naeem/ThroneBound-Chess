extends Control

@onready var play_button = $CenterContainer/VBoxContainer/MarginContainer/PlayButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	play_button.grab_focus()

func _on_play_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/game_setup.tscn")

func _on_settings_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
