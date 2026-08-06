class_name ChessMove
extends RefCounted
enum MoveType {
	NORMAL,
	CASTLE_KINGSIDE,
	CASTLE_QUEENSIDE,
	EN_PASSANT,
	PROMOTION
}

var from_position: Vector2i
var to_position: Vector2i
var moving_piece: ChessPiece
var captured_piece: ChessPiece
var move_type: MoveType
var promotion_type: int # Using int to allow -1 for none, or cast to PieceType

func _init(p_from: Vector2i, p_to: Vector2i, p_moving: ChessPiece, p_captured: ChessPiece = null, p_type: MoveType = MoveType.NORMAL, p_promotion: int = -1):
	from_position = p_from
	to_position = p_to
	moving_piece = p_moving
	captured_piece = p_captured
	move_type = p_type
	promotion_type = p_promotion

func is_capture() -> bool:
	return captured_piece != null

func equals(other: ChessMove) -> bool:
	return from_position == other.from_position and to_position == other.to_position
