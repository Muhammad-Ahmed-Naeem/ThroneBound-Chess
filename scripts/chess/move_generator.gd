class_name MoveGenerator
extends RefCounted

# Generates pseudo-legal moves for a given position.
func generate_moves(board: BoardState, pos: Vector2i, history: GameHistory = null) -> Array[ChessMove]:
	var moves: Array[ChessMove] = []
	var piece = board.get_piece(pos)
	if piece == null:
		return moves
		
	match piece.type:
		ChessTypes.PieceType.PAWN:
			_generate_pawn_moves(board, pos, piece, moves, history)
		ChessTypes.PieceType.KNIGHT:
			_generate_knight_moves(board, pos, piece, moves)
		ChessTypes.PieceType.BISHOP:
			_generate_sliding_moves(board, pos, piece, moves, [
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
			])
		ChessTypes.PieceType.ROOK:
			_generate_sliding_moves(board, pos, piece, moves, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
			])
		ChessTypes.PieceType.QUEEN:
			_generate_sliding_moves(board, pos, piece, moves, [
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
			])
		ChessTypes.PieceType.KING:
			_generate_king_moves(board, pos, piece, moves, history)
			
	return moves

func generate_moves_for_piece(board: BoardState, piece: ChessPiece, history: GameHistory = null) -> Array[ChessMove]:
	return generate_moves(board, piece.position, history)

func _generate_sliding_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove], directions: Array[Vector2i]) -> void:
	for dir in directions:
		var current = origin + dir
		while board.is_valid_position(current):
			var target_piece = board.get_piece(current)
			if target_piece == null:
				moves.append(ChessMove.new(origin, current, piece))
			elif target_piece.color != piece.color:
				moves.append(ChessMove.new(origin, current, piece, target_piece))
				break # Stop sliding past an enemy piece
			else:
				break # Stop sliding at friendly piece
			current += dir

func _generate_knight_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove]) -> void:
	var jumps = [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
	]
	for jump in jumps:
		var target = origin + jump
		if board.is_valid_position(target):
			var target_piece = board.get_piece(target)
			if target_piece == null:
				moves.append(ChessMove.new(origin, target, piece))
			elif target_piece.color != piece.color:
				moves.append(ChessMove.new(origin, target, piece, target_piece))

func _generate_king_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove], history: GameHistory = null) -> void:
	var steps = [
		Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1),
		Vector2i(0, 1),                 Vector2i(0, -1),
		Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1)
	]
	for step in steps:
		var target = origin + step
		if board.is_valid_position(target):
			var target_piece = board.get_piece(target)
			if target_piece == null:
				moves.append(ChessMove.new(origin, target, piece))
			elif target_piece.color != piece.color:
				moves.append(ChessMove.new(origin, target, piece, target_piece))
				
	if history != null:
		_generate_castling_moves(board, origin, piece, moves, history)

func _generate_castling_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove], history: GameHistory) -> void:
	if piece.color == ChessTypes.PieceColor.WHITE:
		if origin == Vector2i(4, 0): # e1
			if history.white_can_castle_kingside and board.get_piece(Vector2i(5, 0)) == null and board.get_piece(Vector2i(6, 0)) == null:
				var rook = board.get_piece(Vector2i(7, 0))
				if rook != null and rook.type == ChessTypes.PieceType.ROOK and rook.color == ChessTypes.PieceColor.WHITE:
					moves.append(ChessMove.new(origin, Vector2i(6, 0), piece, null, ChessMove.MoveType.CASTLE_KINGSIDE))
			if history.white_can_castle_queenside and board.get_piece(Vector2i(3, 0)) == null and board.get_piece(Vector2i(2, 0)) == null and board.get_piece(Vector2i(1, 0)) == null:
				var rook = board.get_piece(Vector2i(0, 0))
				if rook != null and rook.type == ChessTypes.PieceType.ROOK and rook.color == ChessTypes.PieceColor.WHITE:
					moves.append(ChessMove.new(origin, Vector2i(2, 0), piece, null, ChessMove.MoveType.CASTLE_QUEENSIDE))
	else:
		if origin == Vector2i(4, 7): # e8
			if history.black_can_castle_kingside and board.get_piece(Vector2i(5, 7)) == null and board.get_piece(Vector2i(6, 7)) == null:
				var rook = board.get_piece(Vector2i(7, 7))
				if rook != null and rook.type == ChessTypes.PieceType.ROOK and rook.color == ChessTypes.PieceColor.BLACK:
					moves.append(ChessMove.new(origin, Vector2i(6, 7), piece, null, ChessMove.MoveType.CASTLE_KINGSIDE))
			if history.black_can_castle_queenside and board.get_piece(Vector2i(3, 7)) == null and board.get_piece(Vector2i(2, 7)) == null and board.get_piece(Vector2i(1, 7)) == null:
				var rook = board.get_piece(Vector2i(0, 7))
				if rook != null and rook.type == ChessTypes.PieceType.ROOK and rook.color == ChessTypes.PieceColor.BLACK:
					moves.append(ChessMove.new(origin, Vector2i(2, 7), piece, null, ChessMove.MoveType.CASTLE_QUEENSIDE))

func _add_pawn_move(moves: Array[ChessMove], origin: Vector2i, target: Vector2i, piece: ChessPiece, captured: ChessPiece = null) -> void:
	var prom_rank = 7 if piece.color == ChessTypes.PieceColor.WHITE else 0
	if target.y == prom_rank:
		for ptype in [ChessTypes.PieceType.QUEEN, ChessTypes.PieceType.ROOK, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT]:
			moves.append(ChessMove.new(origin, target, piece, captured, ChessMove.MoveType.PROMOTION, ptype))
	else:
		moves.append(ChessMove.new(origin, target, piece, captured, ChessMove.MoveType.NORMAL))

func _generate_pawn_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove], history: GameHistory = null) -> void:
	var forward = 1 if piece.color == ChessTypes.PieceColor.WHITE else -1
	var start_rank = 1 if piece.color == ChessTypes.PieceColor.WHITE else 6
	
	var single_step = origin + Vector2i(0, forward)
	if board.is_valid_position(single_step) and board.get_piece(single_step) == null:
		_add_pawn_move(moves, origin, single_step, piece)
		
		# Initial double step
		if origin.y == start_rank:
			var double_step = origin + Vector2i(0, forward * 2)
			if board.is_valid_position(double_step) and board.get_piece(double_step) == null:
				moves.append(ChessMove.new(origin, double_step, piece)) # Double step is never a promotion
	
	# Diagonal captures and En Passant
	var capture_offsets = [Vector2i(-1, forward), Vector2i(1, forward)]
	for offset in capture_offsets:
		var target = origin + offset
		if board.is_valid_position(target):
			var target_piece = board.get_piece(target)
			if target_piece != null and target_piece.color != piece.color:
				_add_pawn_move(moves, origin, target, piece, target_piece)
			elif target_piece == null and history != null and history.en_passant_target != null:
				if history.en_passant_target == target:
					var cap_pos = Vector2i(target.x, origin.y)
					var cap_piece = board.get_piece(cap_pos)
					if cap_piece != null and cap_piece.color != piece.color and cap_piece.type == ChessTypes.PieceType.PAWN:
						moves.append(ChessMove.new(origin, target, piece, cap_piece, ChessMove.MoveType.EN_PASSANT))
