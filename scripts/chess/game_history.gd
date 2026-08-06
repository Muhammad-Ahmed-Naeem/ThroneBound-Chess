class_name GameHistory
extends RefCounted

class Snapshot:
	var white_kingside: bool
	var white_queenside: bool
	var black_kingside: bool
	var black_queenside: bool
	var en_passant_target # Variant, null or Vector2i
	var halfmove_clock: int
	
var white_can_castle_kingside: bool = true
var white_can_castle_queenside: bool = true
var black_can_castle_kingside: bool = true
var black_can_castle_queenside: bool = true

var en_passant_target = null # Vector2i if available, else null
var halfmove_clock: int = 0

var history_stack: Array[Snapshot] = []
var position_keys: Array[String] = []

func push_state() -> void:
	var snap = Snapshot.new()
	snap.white_kingside = white_can_castle_kingside
	snap.white_queenside = white_can_castle_queenside
	snap.black_kingside = black_can_castle_kingside
	snap.black_queenside = black_can_castle_queenside
	snap.en_passant_target = en_passant_target
	snap.halfmove_clock = halfmove_clock
	history_stack.append(snap)

func pop_state() -> void:
	if history_stack.size() > 0:
		var snap = history_stack.pop_back()
		white_can_castle_kingside = snap.white_kingside
		white_can_castle_queenside = snap.white_queenside
		black_can_castle_kingside = snap.black_kingside
		black_can_castle_queenside = snap.black_queenside
		en_passant_target = snap.en_passant_target
		halfmove_clock = snap.halfmove_clock
		
		# Also pop the position key if we recorded one for the popped move
		if position_keys.size() > history_stack.size():
			position_keys.pop_back()

func record_position(board: BoardState, current_turn: ChessTypes.PieceColor) -> void:
	position_keys.append(generate_position_key(board, current_turn))

func generate_position_key(board: BoardState, current_turn: ChessTypes.PieceColor) -> String:
	# A deterministic representation of the board state for 3-fold repetition
	var key = "Turn:" + str(current_turn) + "|"
	key += "W_Castle:" + str(white_can_castle_kingside) + str(white_can_castle_queenside) + "|"
	key += "B_Castle:" + str(black_can_castle_kingside) + str(black_can_castle_queenside) + "|"
	key += "EP:" + (str(en_passant_target) if en_passant_target != null else "-") + "|"
	key += "Board:"
	for y in range(8):
		for x in range(8):
			var p = board.get_piece(Vector2i(x, y))
			if p == null:
				key += "."
			else:
				var c = "w" if p.color == ChessTypes.PieceColor.WHITE else "b"
				key += c + str(p.type)
	return key
