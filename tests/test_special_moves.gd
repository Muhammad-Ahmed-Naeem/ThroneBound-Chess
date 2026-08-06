extends SceneTree

func _init():
	print("Running Special Moves tests...")
	
	test_castling()
	test_castling_safety()
	test_castling_rights_revocation()
	test_en_passant()
	test_promotion()
	
	print("All Special Moves tests passed successfully!")
	quit()

func _find_move_by_type(moves: Array[ChessMove], to: Vector2i, type: int) -> ChessMove:
	for m in moves:
		if m.to_position == to and m.move_type == type:
			return m
	return null

func test_castling():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0))
	var wr_k = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(7, 0))
	var wr_q = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(0, 0))
	board.set_piece(wk.position, wk)
	board.set_piece(wr_k.position, wr_k)
	board.set_piece(wr_q.position, wr_q)
	
	var moves = rules.generate_legal_moves(board, wk.position, history)
	assert(_find_move_by_type(moves, Vector2i(6, 0), ChessMove.MoveType.CASTLE_KINGSIDE) != null, "White Kingside castling generated")
	assert(_find_move_by_type(moves, Vector2i(2, 0), ChessMove.MoveType.CASTLE_QUEENSIDE) != null, "White Queenside castling generated")

func test_castling_safety():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0))
	var wr_k = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(7, 0))
	var br = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(5, 7)) # Attacks f1
	
	board.set_piece(wk.position, wk)
	board.set_piece(wr_k.position, wr_k)
	board.set_piece(br.position, br)
	
	var moves = rules.generate_legal_moves(board, wk.position, history)
	assert(_find_move_by_type(moves, Vector2i(6, 0), ChessMove.MoveType.CASTLE_KINGSIDE) == null, "Cannot castle through check (f1 attacked)")

func test_castling_rights_revocation():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	var exec = MoveExecutor.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0))
	board.set_piece(wk.position, wk)
	
	var move = ChessMove.new(Vector2i(4, 0), Vector2i(4, 1), wk)
	exec.execute_move(board, move, history)
	
	assert(history.white_can_castle_kingside == false, "King move revokes kingside")
	assert(history.white_can_castle_queenside == false, "King move revokes queenside")

func test_en_passant():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	var exec = MoveExecutor.new()
	
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(4, 4)) # e5
	var bp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(3, 6)) # d7
	board.set_piece(wp.position, wp)
	board.set_piece(bp.position, bp)
	
	# Black double steps
	var m1 = ChessMove.new(Vector2i(3, 6), Vector2i(3, 4), bp)
	exec.execute_move(board, m1, history)
	
	assert(history.en_passant_target == Vector2i(3, 5), "En passant target set at d6")
	
	var moves = rules.generate_legal_moves(board, wp.position, history)
	var ep = _find_move_by_type(moves, Vector2i(3, 5), ChessMove.MoveType.EN_PASSANT)
	assert(ep != null, "En passant capture generated")
	
	exec.execute_move(board, ep, history)
	assert(board.get_piece(Vector2i(3, 5)) == wp, "White pawn arrived at d6")
	assert(board.get_piece(Vector2i(3, 4)) == null, "Black pawn on d5 was removed")

func test_promotion():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	var exec = MoveExecutor.new()
	
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(0, 6)) # a7
	board.set_piece(wp.position, wp)
	
	var moves = rules.generate_legal_moves(board, wp.position, history)
	var has_queen = false
	var has_knight = false
	for m in moves:
		if m.move_type == ChessMove.MoveType.PROMOTION:
			if m.promotion_type == ChessTypes.PieceType.QUEEN: has_queen = true
			if m.promotion_type == ChessTypes.PieceType.KNIGHT: has_knight = true
	assert(has_queen and has_knight, "Promotion moves generated for multiple pieces")
	
	var prom = ChessMove.new(Vector2i(0, 6), Vector2i(0, 7), wp, null, ChessMove.MoveType.PROMOTION, ChessTypes.PieceType.QUEEN)
	exec.execute_move(board, prom, history)
	
	var p = board.get_piece(Vector2i(0, 7))
	assert(p != null and p.type == ChessTypes.PieceType.QUEEN, "Pawn correctly promoted to Queen")
