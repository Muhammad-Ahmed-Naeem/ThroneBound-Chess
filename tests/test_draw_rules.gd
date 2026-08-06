extends SceneTree

func _init():
	print("Running Draw Rules tests...")
	
	test_insufficient_material()
	test_halfmove_clock()
	test_threefold_repetition()
	
	print("All Draw Rules tests passed successfully!")
	quit()

func test_insufficient_material():
	var board = BoardState.new()
	var rules = ChessRules.new()
	
	# K vs K
	board.set_piece(Vector2i(0, 0), ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0)))
	board.set_piece(Vector2i(7, 7), ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(7, 7)))
	assert(rules.is_insufficient_material(board) == true, "King vs King is insufficient")
	
	# K + B vs K
	board.set_piece(Vector2i(1, 1), ChessPiece.new(ChessTypes.PieceType.BISHOP, ChessTypes.PieceColor.WHITE, Vector2i(1, 1)))
	assert(rules.is_insufficient_material(board) == true, "King + Bishop vs King is insufficient")
	
	# Change B to N
	board.remove_piece(Vector2i(1, 1))
	board.set_piece(Vector2i(1, 1), ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.WHITE, Vector2i(1, 1)))
	assert(rules.is_insufficient_material(board) == true, "King + Knight vs King is insufficient")
	
	# Change N to P
	board.remove_piece(Vector2i(1, 1))
	board.set_piece(Vector2i(1, 1), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(1, 1)))
	assert(rules.is_insufficient_material(board) == false, "King + Pawn vs King is NOT insufficient (can promote)")

func test_halfmove_clock():
	var board = BoardState.new()
	var history = GameHistory.new()
	var exec = MoveExecutor.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0))
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(0, 1))
	board.set_piece(wk.position, wk)
	board.set_piece(wp.position, wp)
	
	assert(history.halfmove_clock == 0, "Starts at 0")
	
	var m1 = ChessMove.new(Vector2i(0, 0), Vector2i(1, 0), wk)
	exec.execute_move(board, m1, history)
	assert(history.halfmove_clock == 1, "Quiet move increments clock")
	
	var m2 = ChessMove.new(Vector2i(0, 1), Vector2i(0, 2), wp)
	exec.execute_move(board, m2, history)
	assert(history.halfmove_clock == 0, "Pawn move resets clock")
	
	history.halfmove_clock = 99
	var m3 = ChessMove.new(Vector2i(1, 0), Vector2i(0, 0), wk)
	exec.execute_move(board, m3, history)
	assert(history.halfmove_clock == 100, "Reaches 100")
	assert(rules.is_draw_by_fifty_move_rule(history) == true, "50-move rule triggers at 100 halfmoves")

func test_threefold_repetition():
	var board = BoardState.new()
	var history = GameHistory.new()
	var exec = MoveExecutor.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0))
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(7, 7))
	board.set_piece(wk.position, wk)
	board.set_piece(bk.position, bk)
	
	# Initial
	history.record_position(board, ChessTypes.PieceColor.WHITE)
	assert(rules.is_draw_by_repetition(history) == false)
	
	# Move 1: W King a1->b1
	var m1 = ChessMove.new(Vector2i(0, 0), Vector2i(1, 0), wk)
	exec.execute_move(board, m1, history)
	history.record_position(board, ChessTypes.PieceColor.BLACK)
	
	# Move 2: B King h8->g8
	var m2 = ChessMove.new(Vector2i(7, 7), Vector2i(6, 7), bk)
	exec.execute_move(board, m2, history)
	history.record_position(board, ChessTypes.PieceColor.WHITE)
	
	# Move 3: W King b1->a1 (Position 2nd time)
	var m3 = ChessMove.new(Vector2i(1, 0), Vector2i(0, 0), wk)
	exec.execute_move(board, m3, history)
	history.record_position(board, ChessTypes.PieceColor.BLACK)
	assert(rules.is_draw_by_repetition(history) == false)
	
	# Move 4: B King g8->h8
	var m4 = ChessMove.new(Vector2i(6, 7), Vector2i(7, 7), bk)
	exec.execute_move(board, m4, history)
	history.record_position(board, ChessTypes.PieceColor.WHITE)
	assert(rules.is_draw_by_repetition(history) == false, "Needs to happen 3 times with the exact same side to move")
	
	# Move 5: W King a1->b1
	exec.execute_move(board, m1, history)
	history.record_position(board, ChessTypes.PieceColor.BLACK)
	
	# Move 6: B King h8->g8
	exec.execute_move(board, m2, history)
	history.record_position(board, ChessTypes.PieceColor.WHITE)
	
	# Move 7: W King b1->a1
	exec.execute_move(board, m3, history)
	history.record_position(board, ChessTypes.PieceColor.BLACK)
	
	# Move 8: B King g8->h8 (Position 3rd time for WHITE to move)
	exec.execute_move(board, m4, history)
	history.record_position(board, ChessTypes.PieceColor.WHITE)
	
	assert(rules.is_draw_by_repetition(history) == true, "3-fold repetition detected")
