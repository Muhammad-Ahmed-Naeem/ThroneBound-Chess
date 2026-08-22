extends Node

# A minimal autoload for transitioning scenes and holding the active game configuration.
# DO NOT turn this into a giant GameManager.

const GameConfig = preload("res://scripts/ui/game_configuration.gd")

var current_config: GameConfig = GameConfig.new()

func change_scene(path: String) -> void:
	# Unpause in case we transition from a paused state
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func start_match(config: GameConfig) -> void:
	current_config = config
	change_scene("res://scenes/chess/chess_board.tscn")
