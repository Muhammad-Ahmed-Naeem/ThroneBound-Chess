class_name MoveExecutor
extends RefCounted

class UndoRecord:
	var move: ChessMove
	var original_moving_piece: ChessPiece
	var original_captured_piece: ChessPiece
	var original_from_pos: Vector2i
	var original_to_pos: Vector2i
	
	var castling_rook: ChessPiece
	var castling_rook_from: Vector2i
	var castling_rook_to: Vector2i
	
	var original_piece_type: int

# Permanently execute a move on the board, updating history if provided
func execute_move(board: BoardState, move: ChessMove, history: GameHistory = null) -> void:
	if history != null:
		history.push_state()
		_update_history(board, move, history)
	
	match move.move_type:
		ChessMove.MoveType.NORMAL:
			board.remove_piece(move.from_position)
			if move.captured_piece != null:
				board.remove_piece(move.to_position)
			board.set_piece(move.to_position, move.moving_piece)
		ChessMove.MoveType.EN_PASSANT:
			board.remove_piece(move.from_position)
			var cap_pos = Vector2i(move.to_position.x, move.from_position.y)
			board.remove_piece(cap_pos)
			board.set_piece(move.to_position, move.moving_piece)
		ChessMove.MoveType.CASTLE_KINGSIDE, ChessMove.MoveType.CASTLE_QUEENSIDE:
			board.remove_piece(move.from_position)
			board.set_piece(move.to_position, move.moving_piece)
			var rook_from = Vector2i(7 if move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE else 0, move.from_position.y)
			var rook_to = Vector2i(5 if move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE else 3, move.from_position.y)
			var rook = board.get_piece(rook_from)
			if rook != null:
				board.remove_piece(rook_from)
				board.set_piece(rook_to, rook)
		ChessMove.MoveType.PROMOTION:
			board.remove_piece(move.from_position)
			if move.captured_piece != null:
				board.remove_piece(move.to_position)
			move.moving_piece.type = move.promotion_type
			board.set_piece(move.to_position, move.moving_piece)

func _update_history(board: BoardState, move: ChessMove, history: GameHistory) -> void:
	# 1. Halfmove clock
	if move.moving_piece.type == ChessTypes.PieceType.PAWN or move.captured_piece != null:
		history.halfmove_clock = 0
	else:
		history.halfmove_clock += 1
		
	# 2. En passant target
	history.en_passant_target = null
	if move.moving_piece.type == ChessTypes.PieceType.PAWN and abs(move.from_position.y - move.to_position.y) == 2:
		history.en_passant_target = Vector2i(move.from_position.x, (move.from_position.y + move.to_position.y) / 2)
		
	# 3. Castling rights
	if move.moving_piece.type == ChessTypes.PieceType.KING:
		if move.moving_piece.color == ChessTypes.PieceColor.WHITE:
			history.white_can_castle_kingside = false
			history.white_can_castle_queenside = false
		else:
			history.black_can_castle_kingside = false
			history.black_can_castle_queenside = false
			
	if move.moving_piece.type == ChessTypes.PieceType.ROOK:
		_revoke_castling_for_rook(move.from_position, history)
		
	if move.captured_piece != null and move.captured_piece.type == ChessTypes.PieceType.ROOK:
		var cap_pos = move.to_position
		if move.move_type == ChessMove.MoveType.EN_PASSANT:
			cap_pos = Vector2i(move.to_position.x, move.from_position.y)
		_revoke_castling_for_rook(cap_pos, history)

func _revoke_castling_for_rook(pos: Vector2i, history: GameHistory) -> void:
	if pos == Vector2i(0, 0): history.white_can_castle_queenside = false
	elif pos == Vector2i(7, 0): history.white_can_castle_kingside = false
	elif pos == Vector2i(0, 7): history.black_can_castle_queenside = false
	elif pos == Vector2i(7, 7): history.black_can_castle_kingside = false

# Simulates a move, returning an undo record to completely restore the previous state
func simulate_move(board: BoardState, move: ChessMove, history: GameHistory = null) -> UndoRecord:
	var record = UndoRecord.new()
	record.move = move
	record.original_moving_piece = move.moving_piece
	record.original_captured_piece = move.captured_piece
	record.original_from_pos = move.from_position
	record.original_to_pos = move.to_position
	record.original_piece_type = move.moving_piece.type
	
	if move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE or move.move_type == ChessMove.MoveType.CASTLE_QUEENSIDE:
		var rook_from = Vector2i(7 if move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE else 0, move.from_position.y)
		var rook_to = Vector2i(5 if move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE else 3, move.from_position.y)
		record.castling_rook = board.get_piece(rook_from)
		record.castling_rook_from = rook_from
		record.castling_rook_to = rook_to
		
	execute_move(board, move, history)
	return record

# Completely restores the board to its pre-simulated state
func restore_move(board: BoardState, record: UndoRecord, history: GameHistory = null) -> void:
	if history != null:
		history.pop_state()
		
	# Restore moving piece original type if it promoted
	if record.move.move_type == ChessMove.MoveType.PROMOTION:
		record.original_moving_piece.type = record.original_piece_type
		
	if record.move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE or record.move.move_type == ChessMove.MoveType.CASTLE_QUEENSIDE:
		board.remove_piece(record.original_to_pos)
		board.set_piece(record.original_from_pos, record.original_moving_piece)
		if record.castling_rook != null:
			board.remove_piece(record.castling_rook_to)
			board.set_piece(record.castling_rook_from, record.castling_rook)
	elif record.move.move_type == ChessMove.MoveType.EN_PASSANT:
		board.remove_piece(record.original_to_pos)
		board.set_piece(record.original_from_pos, record.original_moving_piece)
		var cap_pos = Vector2i(record.original_to_pos.x, record.original_from_pos.y)
		board.set_piece(cap_pos, record.original_captured_piece)
	else:
		board.remove_piece(record.original_to_pos)
		board.set_piece(record.original_from_pos, record.original_moving_piece)
		if record.original_captured_piece != null:
			board.set_piece(record.original_to_pos, record.original_captured_piece)
