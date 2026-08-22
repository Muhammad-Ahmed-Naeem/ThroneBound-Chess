extends Control

@onready var local_button = $CenterContainer/VBoxContainer/MarginContainer/LocalButton
@onready var ai_button = $CenterContainer/VBoxContainer/AiButton
@onready var ai_options = $CenterContainer/VBoxContainer/AiOptions
@onready var color_options = $CenterContainer/VBoxContainer/AiOptions/ColorOptions
@onready var diff_options = $CenterContainer/VBoxContainer/AiOptions/DiffOptions
@onready var back_button = $CenterContainer/VBoxContainer/MarginContainer2/HBoxContainer/BackButton
@onready var start_button = $CenterContainer/VBoxContainer/MarginContainer2/HBoxContainer/StartButton

var _config = GameConfiguration.new()

func _ready() -> void:
	local_button.pressed.connect(_on_local_pressed)
	ai_button.pressed.connect(_on_ai_pressed)
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	color_options.add_item("Play as White", GameConfiguration.PlayerColor.WHITE)
	color_options.add_item("Play as Black", GameConfiguration.PlayerColor.BLACK)
	
	diff_options.add_item("Easy", GameConfiguration.AIDifficulty.EASY)
	diff_options.add_item("Medium", GameConfiguration.AIDifficulty.MEDIUM)
	diff_options.add_item("Hard", GameConfiguration.AIDifficulty.HARD)
	diff_options.select(1) # Medium
	
	local_button.grab_focus()

func _on_local_pressed() -> void:
	_config.game_mode = GameConfiguration.GameMode.LOCAL_2_PLAYER
	ai_options.visible = false

func _on_ai_pressed() -> void:
	_config.game_mode = GameConfiguration.GameMode.VS_AI
	ai_options.visible = true

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _on_start_pressed() -> void:
	if _config.game_mode == GameConfiguration.GameMode.VS_AI:
		_config.player_color = color_options.get_selected_id()
		_config.ai_difficulty = diff_options.get_selected_id()
	SceneTransition.start_match(_config)
