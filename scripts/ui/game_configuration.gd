class_name GameConfiguration
extends RefCounted

enum GameMode {
	LOCAL_2_PLAYER,
	VS_AI
}

enum PlayerColor {
	WHITE,
	BLACK,
	RANDOM
}

enum AIDifficulty {
	EASY,
	MEDIUM,
	HARD
}

var game_mode: GameMode = GameMode.LOCAL_2_PLAYER
var player_color: PlayerColor = PlayerColor.WHITE
var ai_difficulty: AIDifficulty = AIDifficulty.MEDIUM

func _init(mode: GameMode = GameMode.LOCAL_2_PLAYER, color: PlayerColor = PlayerColor.WHITE, diff: AIDifficulty = AIDifficulty.MEDIUM):
	game_mode = mode
	player_color = color
	ai_difficulty = diff
