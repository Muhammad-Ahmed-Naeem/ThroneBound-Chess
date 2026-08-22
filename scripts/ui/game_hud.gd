extends Control

@onready var turn_label = $MarginContainer/VBoxContainer/TurnLabel
@onready var check_label = $MarginContainer/VBoxContainer/CheckLabel

func update_hud(current_turn: int, is_in_check: bool) -> void:
	if current_turn == ChessTypes.PieceColor.WHITE:
		turn_label.text = "WHITE TO MOVE"
	else:
		turn_label.text = "BLACK TO MOVE"
	
	check_label.visible = is_in_check
