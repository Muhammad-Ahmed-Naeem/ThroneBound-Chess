class_name TurnManager
extends RefCounted

var current_turn: ChessTypes.PieceColor = ChessTypes.PieceColor.WHITE

func switch_turn() -> void:
	if current_turn == ChessTypes.PieceColor.WHITE:
		current_turn = ChessTypes.PieceColor.BLACK
	else:
		current_turn = ChessTypes.PieceColor.WHITE

func is_turn(color: ChessTypes.PieceColor) -> bool:
	return current_turn == color
