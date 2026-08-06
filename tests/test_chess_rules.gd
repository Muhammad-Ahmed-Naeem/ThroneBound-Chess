extends SceneTree

func _init():
	print("Running ChessRules tests...")
	
	test_attack_detection()
	test_check_detection()
	test_legal_move_filtering()
	test_pawn_attacks()
	
	print("All ChessRules tests passed successfully!")
	quit()

func test_attack_detection():
	var board = BoardState.new()
	var rules = ChessRules.new()
	
	# Setup
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0)) # e1
	var br = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(4, 7)) # e8
	board.set_piece(wk.position, wk)
	board.set_piece(br.position, br)
	
	assert(rules.is_square_attacked(board, Vector2i(4, 0), ChessTypes.PieceColor.BLACK) == true, "e1 is attacked by e8 Rook")
	assert(rules.is_square_attacked(board, Vector2i(0, 0), ChessTypes.PieceColor.BLACK) == false, "a1 is not attacked by e8 Rook")
	
	# Block the attack
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(4, 1)) # e2
	board.set_piece(wp.position, wp)
	
	assert(rules.is_square_attacked(board, Vector2i(4, 0), ChessTypes.PieceColor.BLACK) == false, "e1 is no longer attacked because of blocking e2 Pawn")
	
func test_check_detection():
	var board = BoardState.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0)) # e1
	board.set_piece(wk.position, wk)
	
	assert(rules.is_in_check(board, ChessTypes.PieceColor.WHITE) == false, "King is safe")
	
	var bn = ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.BLACK, Vector2i(3, 2)) # d3
	board.set_piece(bn.position, bn)
	
	assert(rules.is_in_check(board, ChessTypes.PieceColor.WHITE) == true, "King is in check by d3 Knight")
	
	var bb = ChessPiece.new(ChessTypes.PieceType.BISHOP, ChessTypes.PieceColor.BLACK, Vector2i(0, 4)) # a5
	board.set_piece(bb.position, bb)
	assert(rules.is_in_check(board, ChessTypes.PieceColor.WHITE) == true, "King is in check by a5 Bishop (diagonal)")
	
	board.remove_piece(bn.position)
	assert(rules.is_in_check(board, ChessTypes.PieceColor.WHITE) == true, "King is still in check by a5 Bishop")

func test_legal_move_filtering():
	var board = BoardState.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0)) # e1
	var wr = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(4, 1)) # e2
	var br = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(4, 7)) # e8
	board.set_piece(wk.position, wk)
	board.set_piece(wr.position, wr)
	board.set_piece(br.position, br)
	
	var legal_moves = rules.generate_legal_moves(board, wr.position)
	
	# The white rook on e2 is pinned to the king on e1 by the black rook on e8.
	# It can only move along the e-file (to capture or block), but not off it.
	for move in legal_moves:
		assert(move.to_position.x == 4, "Pinned rook can only move along the pin ray")
	
	var pseudo_moves = rules.move_generator.generate_moves(board, wr.position)
	var pseudo_has_off_ray = false
	for move in pseudo_moves:
		if move.to_position.x != 4:
			pseudo_has_off_ray = true
	assert(pseudo_has_off_ray == true, "Pseudo generator produces illegal off-ray moves")
	
	# King cannot move into check
	var king_moves = rules.generate_legal_moves(board, wk.position)
	for move in king_moves:
		assert(move.to_position.x != 3 and move.to_position.x != 5, "King moves to d1 or f1 should be safe, e.g. not e-file if it was attacked")
		assert(rules.is_square_attacked(board, move.to_position, ChessTypes.PieceColor.BLACK) == false, "King cannot move into check")

func test_pawn_attacks():
	var board = BoardState.new()
	var rules = ChessRules.new()
	
	# White pawn on d4 (x:3, y:3)
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(3, 3))
	board.set_piece(wp.position, wp)
	
	# White pawns attack up-left and up-right (+1 y direction)
	assert(rules.is_square_attacked(board, Vector2i(2, 4), ChessTypes.PieceColor.WHITE) == true, "c5 is attacked by d4 white pawn")
	assert(rules.is_square_attacked(board, Vector2i(4, 4), ChessTypes.PieceColor.WHITE) == true, "e5 is attacked by d4 white pawn")
	assert(rules.is_square_attacked(board, Vector2i(3, 4), ChessTypes.PieceColor.WHITE) == false, "d5 is NOT attacked by d4 white pawn")
	
	# Black pawn on f5 (x:5, y:4)
	var bp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(5, 4))
	board.set_piece(bp.position, bp)
	
	# Black pawns attack down-left and down-right (-1 y direction)
	assert(rules.is_square_attacked(board, Vector2i(4, 3), ChessTypes.PieceColor.BLACK) == true, "e4 is attacked by f5 black pawn")
	assert(rules.is_square_attacked(board, Vector2i(6, 3), ChessTypes.PieceColor.BLACK) == true, "g4 is attacked by f5 black pawn")
	assert(rules.is_square_attacked(board, Vector2i(5, 3), ChessTypes.PieceColor.BLACK) == false, "f4 is NOT attacked by f5 black pawn")
