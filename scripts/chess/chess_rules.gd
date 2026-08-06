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
	# If by_color is WHITE, they move in +1 y direction, so to attack us they must be -1 y from us
	var pawn_forward = -1 if by_color == ChessTypes.PieceColor.WHITE else 1
	var pawn_attacks = [Vector2i(-1, pawn_forward), Vector2i(1, pawn_forward)]
	for atk in pawn_attacks:
		var target = pos + atk
		if board.is_valid_position(target):
			var p = board.get_piece(target)
			if p != null and p.color == by_color and p.type == ChessTypes.PieceType.PAWN:
				return true
				
	# Check Diagonal Sliding attacks (Bishop, Queen)
	var diags = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	if _check_sliders(board, pos, by_color, diags, [ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.QUEEN]):
		return true
		
	# Check Orthogonal Sliding attacks (Rook, Queen)
	var orths = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	if _check_sliders(board, pos, by_color, orths, [ChessTypes.PieceType.ROOK, ChessTypes.PieceType.QUEEN]):
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
				break # Line of sight is blocked by a piece (friendly or enemy)
			current += dir
	return false

# Generates purely legal moves by filtering pseudo-legal moves against King safety
func generate_legal_moves(board: BoardState, pos: Vector2i) -> Array[ChessMove]:
	var legal_moves: Array[ChessMove] = []
	var piece = board.get_piece(pos)
	if piece == null:
		return legal_moves
		
	var pseudo_moves = move_generator.generate_moves(board, pos)
	for move in pseudo_moves:
		# Simulate move
		var record = move_executor.simulate_move(board, move)
		# Validate King safety
		var in_check = is_in_check(board, piece.color)
		# Restore original state
		move_executor.restore_move(board, record)
		
		# If our king is safe, the move is legal
		if not in_check:
			legal_moves.append(move)
			
	return legal_moves
