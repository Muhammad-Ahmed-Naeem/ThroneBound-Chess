extends Control

@onready var local_button = $CenterContainer/VBoxContainer/MarginContainer/LocalButton
@onready var ai_button = $CenterContainer/VBoxContainer/AiButton
@onready var back_button = $CenterContainer/VBoxContainer/MarginContainer2/HBoxContainer/BackButton
@onready var start_button = $CenterContainer/VBoxContainer/MarginContainer2/HBoxContainer/StartButton

var _config = GameConfiguration.new()

func _ready() -> void:
	local_button.pressed.connect(_on_local_pressed)
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	local_button.grab_focus()
	# Optional: Give Local button a pressed state look if we wanted it to look selected

func _on_local_pressed() -> void:
	_config.game_mode = GameConfiguration.GameMode.LOCAL_2_PLAYER

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _on_start_pressed() -> void:
	SceneTransition.start_match(_config)
