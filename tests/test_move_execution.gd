extends SceneTree

func _init():
	print("Running MoveExecution tests...")
	
	test_normal_move()
	test_capture_move()
	test_simulation()
	test_multiple_simulations()
	
	print("All MoveExecution tests passed successfully!")
	quit()

func test_normal_move():
	var board = BoardState.new()
	var executor = MoveExecutor.new()
	
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(0, 1))
	board.set_piece(wp.position, wp)
	
	var move = ChessMove.new(Vector2i(0, 1), Vector2i(0, 2), wp)
	executor.execute_move(board, move)
	
	assert(board.get_piece(Vector2i(0, 1)) == null, "Origin should be cleared")
	assert(board.get_piece(Vector2i(0, 2)) == wp, "Destination should be occupied by piece")
	assert(wp.position == Vector2i(0, 2), "Piece position should be synced")

func test_capture_move():
	var board = BoardState.new()
	var executor = MoveExecutor.new()
	
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(0, 1))
	board.set_piece(wp.position, wp)
	var bp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(1, 2))
	board.set_piece(bp.position, bp)
	
	var move = ChessMove.new(wp.position, bp.position, wp, bp)
	executor.execute_move(board, move)
	
	assert(board.get_piece(Vector2i(0, 1)) == null, "Origin cleared")
	assert(board.get_piece(Vector2i(1, 2)) == wp, "Destination occupied by attacker")
	var pieces = board.get_all_pieces()
	assert(pieces.size() == 1, "Captured piece should be removed from board completely")

func test_simulation():
	var board = BoardState.new()
	var executor = MoveExecutor.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0))
	var br = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(4, 7))
	board.set_piece(wk.position, wk)
	board.set_piece(br.position, br)
	
	# Hypothetical move: King takes Rook (even though it's illegal in real chess to do this from across board, it tests simulation perfectly)
	var move = ChessMove.new(wk.position, br.position, wk, br)
	var record = executor.simulate_move(board, move)
	
	assert(board.get_piece(Vector2i(4, 0)) == null, "King left e1")
	assert(board.get_piece(Vector2i(4, 7)) == wk, "King arrived at e8")
	
	executor.restore_move(board, record)
	
	assert(board.get_piece(Vector2i(4, 0)) == wk, "King restored to e1")
	assert(board.get_piece(Vector2i(4, 7)) == br, "Rook restored to e8")
	assert(wk.position == Vector2i(4, 0), "King pos synced")
	assert(br.position == Vector2i(4, 7), "Rook pos synced")

func test_multiple_simulations():
	var board = BoardState.new()
	var executor = MoveExecutor.new()
	board.setup_initial_position()
	
	var e2 = Vector2i(4, 1)
	var e4 = Vector2i(4, 3)
	var e2_pawn = board.get_piece(e2)
	
	var move = ChessMove.new(e2, e4, e2_pawn)
	for i in range(10):
		var record = executor.simulate_move(board, move)
		assert(board.get_piece(e2) == null, "Simulated execution cleared origin")
		assert(board.get_piece(e4) == e2_pawn, "Simulated execution filled destination")
		executor.restore_move(board, record)
		assert(board.get_piece(e2) == e2_pawn, "Restoration filled origin")
		assert(board.get_piece(e4) == null, "Restoration cleared destination")
