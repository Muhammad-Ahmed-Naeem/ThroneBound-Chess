class_name ChessMove
extends RefCounted

var from_position: Vector2i
var to_position: Vector2i
var moving_piece: ChessPiece
var captured_piece: ChessPiece

func _init(p_from: Vector2i, p_to: Vector2i, p_moving: ChessPiece, p_captured: ChessPiece = null):
	from_position = p_from
	to_position = p_to
	moving_piece = p_moving
	captured_piece = p_captured

func is_capture() -> bool:
	return captured_piece != null

func equals(other: ChessMove) -> bool:
	return from_position == other.from_position and to_position == other.to_position
