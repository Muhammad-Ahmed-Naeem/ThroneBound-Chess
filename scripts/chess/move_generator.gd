class_name MoveGenerator
extends RefCounted

# Generates pseudo-legal moves for a given position.
# Pseudo-legal means it follows movement and occupancy rules,
# but DOES NOT yet check if the move leaves the King in check.
func generate_moves(board: BoardState, pos: Vector2i) -> Array[ChessMove]:
	var moves: Array[ChessMove] = []
	var piece = board.get_piece(pos)
	if piece == null:
		return moves
		
	match piece.type:
		ChessTypes.PieceType.PAWN:
			_generate_pawn_moves(board, pos, piece, moves)
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
			_generate_king_moves(board, pos, piece, moves)
			
	return moves

func generate_moves_for_piece(board: BoardState, piece: ChessPiece) -> Array[ChessMove]:
	return generate_moves(board, piece.position)

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

func _generate_king_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove]) -> void:
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
	# Note: Castling is intentionally deferred to later milestones

func _generate_pawn_moves(board: BoardState, origin: Vector2i, piece: ChessPiece, moves: Array[ChessMove]) -> void:
	var forward = 1 if piece.color == ChessTypes.PieceColor.WHITE else -1
	var start_rank = 1 if piece.color == ChessTypes.PieceColor.WHITE else 6
	
	var single_step = origin + Vector2i(0, forward)
	if board.is_valid_position(single_step) and board.get_piece(single_step) == null:
		moves.append(ChessMove.new(origin, single_step, piece))
		
		# Initial double step
		if origin.y == start_rank:
			var double_step = origin + Vector2i(0, forward * 2)
			if board.is_valid_position(double_step) and board.get_piece(double_step) == null:
				moves.append(ChessMove.new(origin, double_step, piece))
	
	# Diagonal captures
	var capture_offsets = [Vector2i(-1, forward), Vector2i(1, forward)]
	for offset in capture_offsets:
		var target = origin + offset
		if board.is_valid_position(target):
			var target_piece = board.get_piece(target)
			if target_piece != null and target_piece.color != piece.color:
				moves.append(ChessMove.new(origin, target, piece, target_piece))
	
	# Note: En passant and promotion are intentionally deferred to later milestones
