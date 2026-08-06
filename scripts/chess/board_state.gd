class_name BoardState
extends RefCounted

# Coordinate convention: Vector2i(file, rank)
# file: 0-7 (a-h)
# rank: 0-7 (1-8)
# We store the board as a 1D array of 64 elements for fast contiguous access.
# Index = rank * 8 + file

var _board: Array[ChessPiece] = []

func _init():
	_board.resize(64)
	clear()

func clear() -> void:
	for i in range(64):
		_board[i] = null

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x <= 7 and pos.y >= 0 and pos.y <= 7

func _get_index(pos: Vector2i) -> int:
	return pos.y * 8 + pos.x

func get_piece(pos: Vector2i) -> ChessPiece:
	if not is_valid_position(pos):
		return null
	return _board[_get_index(pos)]

func set_piece(pos: Vector2i, piece: ChessPiece) -> void:
	if not is_valid_position(pos):
		push_error("Attempted to place piece at invalid board position: " + str(pos))
		return
	if piece:
		piece.position = pos
	_board[_get_index(pos)] = piece

func remove_piece(pos: Vector2i) -> void:
	if not is_valid_position(pos):
		return
	_board[_get_index(pos)] = null

func is_occupied(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	return _board[_get_index(pos)] != null

func get_all_pieces() -> Array[ChessPiece]:
	var pieces: Array[ChessPiece] = []
	for p in _board:
		if p != null:
			pieces.append(p)
	return pieces

func setup_initial_position() -> void:
	clear()
	
	# White pieces (Ranks 0 and 1)
	_setup_rank(0, ChessTypes.PieceColor.WHITE, [
		ChessTypes.PieceType.ROOK, ChessTypes.PieceType.KNIGHT, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.QUEEN,
		ChessTypes.PieceType.KING, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT, ChessTypes.PieceType.ROOK
	])
	_setup_rank(1, ChessTypes.PieceColor.WHITE, [
		ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN,
		ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN
	])
	
	# Black pieces (Ranks 7 and 6)
	_setup_rank(7, ChessTypes.PieceColor.BLACK, [
		ChessTypes.PieceType.ROOK, ChessTypes.PieceType.KNIGHT, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.QUEEN,
		ChessTypes.PieceType.KING, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT, ChessTypes.PieceType.ROOK
	])
	_setup_rank(6, ChessTypes.PieceColor.BLACK, [
		ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN,
		ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN
	])

func _setup_rank(rank: int, color: ChessTypes.PieceColor, types: Array[ChessTypes.PieceType]) -> void:
	for file in range(8):
		var pos = Vector2i(file, rank)
		set_piece(pos, ChessPiece.new(types[file], color, pos))

# Helper for basic debugging verification
func get_debug_board_string() -> String:
	var output = ""
	for rank in range(7, -1, -1):
		var line = str(rank + 1) + ": "
		for file in range(8):
			var p = get_piece(Vector2i(file, rank))
			if p == null:
				line += ". "
			else:
				line += p.get_fen_char() + " "
		output += line.strip_edges() + "\n"
	output += "\n   a b c d e f g h"
	return output
