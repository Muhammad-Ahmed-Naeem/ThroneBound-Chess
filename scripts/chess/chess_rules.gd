class_name ChessRules
extends RefCounted

var move_generator: MoveGenerator
var move_executor: MoveExecutor

func _init():
	move_generator = MoveGenerator.new()
	move_executor = MoveExecutor.new()

# Locate the King of the specified color on the board
func find_king(board: BoardState, color: ChessTypes.PieceColor) -> ChessPiece:
	var pieces = board.get_all_pieces()
	for p in pieces:
		if p.color == color and p.type == ChessTypes.PieceType.KING:
			return p
	return null

# Determine if the given color is in check
func is_in_check(board: BoardState, color: ChessTypes.PieceColor) -> bool:
	var king = find_king(board, color)
	if king == null:
		return false
		
	var enemy_color = ChessTypes.PieceColor.BLACK if color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
	return is_square_attacked(board, king.position, enemy_color)

# Check if a square is attacked by pieces of `by_color`
func is_square_attacked(board: BoardState, pos: Vector2i, by_color: ChessTypes.PieceColor) -> bool:
	# Check Knight attacks
	var knight_jumps = [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
	]
	for jump in knight_jumps:
		var target = pos + jump
		if board.is_valid_position(target):
			var p = board.get_piece(target)
			if p != null and p.color == by_color and p.type == ChessTypes.PieceType.KNIGHT:
				return true
				
	# Check King (adjacency) attacks
	var king_steps = [
		Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1),
		Vector2i(0, 1),                 Vector2i(0, -1),
		Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1)
	]
	for step in king_steps:
		var target = pos + step
		if board.is_valid_position(target):
			var p = board.get_piece(target)
			if p != null and p.color == by_color and p.type == ChessTypes.PieceType.KING:
				return true
				
	# Check Pawn attacks
	var pawn_forward = -1 if by_color == ChessTypes.PieceColor.WHITE else 1
	var pawn_attacks = [Vector2i(-1, pawn_forward), Vector2i(1, pawn_forward)]
	for atk in pawn_attacks:
		var target = pos + atk
		if board.is_valid_position(target):
			var p = board.get_piece(target)
			if p != null and p.color == by_color and p.type == ChessTypes.PieceType.PAWN:
				return true
				
	# Check Diagonal Sliding attacks (Bishop, Queen)
	var diags: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var valid_diags: Array[ChessTypes.PieceType] = [ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.QUEEN]
	if _check_sliders(board, pos, by_color, diags, valid_diags):
		return true
		
	# Check Orthogonal Sliding attacks (Rook, Queen)
	var orths: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var valid_orths: Array[ChessTypes.PieceType] = [ChessTypes.PieceType.ROOK, ChessTypes.PieceType.QUEEN]
	if _check_sliders(board, pos, by_color, orths, valid_orths):
		return true
		
	return false

# Helper to trace rays for sliding attackers
func _check_sliders(board: BoardState, pos: Vector2i, by_color: ChessTypes.PieceColor, directions: Array[Vector2i], valid_types: Array[ChessTypes.PieceType]) -> bool:
	for dir in directions:
		var current = pos + dir
		while board.is_valid_position(current):
			var p = board.get_piece(current)
			if p != null:
				if p.color == by_color and p.type in valid_types:
					return true
				break
			current += dir
	return false

func generate_legal_moves(board: BoardState, pos: Vector2i, history: GameHistory = null) -> Array[ChessMove]:
	var legal_moves: Array[ChessMove] = []
	var piece = board.get_piece(pos)
	if piece == null:
		return legal_moves
		
	var pseudo_moves = move_generator.generate_moves(board, pos, history)
	var enemy_color = ChessTypes.PieceColor.BLACK if piece.color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
	
	for move in pseudo_moves:
		if move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE or move.move_type == ChessMove.MoveType.CASTLE_QUEENSIDE:
			# Castling cannot be done if king is in check
			if is_in_check(board, piece.color):
				continue
				
			# Castling cannot pass through check
			var is_kingside = (move.move_type == ChessMove.MoveType.CASTLE_KINGSIDE)
			var intermediate_x = 5 if is_kingside else 3
			var intermediate_pos = Vector2i(intermediate_x, pos.y)
			if is_square_attacked(board, intermediate_pos, enemy_color):
				continue
		
		# Simulate move
		var record = move_executor.simulate_move(board, move, history)
		# Validate King safety
		var in_check = is_in_check(board, piece.color)
		# Restore original state
		move_executor.restore_move(board, record, history)
		
		if not in_check:
			legal_moves.append(move)
			
	return legal_moves

func get_all_legal_moves(board: BoardState, history: GameHistory, color: ChessTypes.PieceColor) -> Array[ChessMove]:
	var all_moves: Array[ChessMove] = []
	var pieces = board.get_all_pieces()
	for p in pieces:
		if p.color == color:
			var moves = generate_legal_moves(board, p.position, history)
			for m in moves:
				all_moves.append(m)
	return all_moves

func is_checkmate(board: BoardState, history: GameHistory, color: ChessTypes.PieceColor) -> bool:
	if not is_in_check(board, color):
		return false
	var moves = get_all_legal_moves(board, history, color)
	return moves.size() == 0

func is_stalemate(board: BoardState, history: GameHistory, color: ChessTypes.PieceColor) -> bool:
	if is_in_check(board, color):
		return false
	var moves = get_all_legal_moves(board, history, color)
	return moves.size() == 0

func is_draw_by_fifty_move_rule(history: GameHistory) -> bool:
	# 50 moves = 100 halfmoves
	return history.halfmove_clock >= 100

func is_draw_by_repetition(history: GameHistory) -> bool:
	if history.position_keys.size() == 0:
		return false
	var current = history.position_keys.back()
	var count = 0
	for k in history.position_keys:
		if k == current:
			count += 1
	return count >= 3

func is_insufficient_material(board: BoardState) -> bool:
	var pieces = board.get_all_pieces()
	if pieces.size() <= 2:
		return true # Only Kings left
		
	if pieces.size() == 3:
		for p in pieces:
			if p.type == ChessTypes.PieceType.BISHOP or p.type == ChessTypes.PieceType.KNIGHT:
				return true # King + Bishop/Knight vs King
				
	# Additional complex dead positions can be added here
	return false
