class_name ChessPiece
extends RefCounted

var type: ChessTypes.PieceType
var color: ChessTypes.PieceColor
var position: Vector2i # file (x), rank (y)

func _init(p_type: ChessTypes.PieceType, p_color: ChessTypes.PieceColor, p_position: Vector2i):
	type = p_type
	color = p_color
	position = p_position

# Helper for debugging purposes
func get_fen_char() -> String:
	var c = ""
	match type:
		ChessTypes.PieceType.PAWN: c = "p"
		ChessTypes.PieceType.KNIGHT: c = "n"
		ChessTypes.PieceType.BISHOP: c = "b"
		ChessTypes.PieceType.ROOK: c = "r"
		ChessTypes.PieceType.QUEEN: c = "q"
		ChessTypes.PieceType.KING: c = "k"
	
	if color == ChessTypes.PieceColor.WHITE:
		return c.to_upper()
	return c
