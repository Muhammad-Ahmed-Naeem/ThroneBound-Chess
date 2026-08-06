extends SceneTree

func _init():
	print("Running Game Endings tests...")
	
	test_checkmate()
	test_stalemate()
	
	print("All Game Endings tests passed successfully!")
	quit()

func test_checkmate():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0)) # a1
	var bq = ChessPiece.new(ChessTypes.PieceType.QUEEN, ChessTypes.PieceColor.BLACK, Vector2i(1, 1)) # b2
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(2, 2)) # c3
	
	board.set_piece(wk.position, wk)
	board.set_piece(bq.position, bq)
	board.set_piece(bk.position, bk)
	
	assert(rules.is_in_check(board, ChessTypes.PieceColor.WHITE) == true, "White is in check")
	assert(rules.is_checkmate(board, history, ChessTypes.PieceColor.WHITE) == true, "White is in checkmate")
	assert(rules.is_stalemate(board, history, ChessTypes.PieceColor.WHITE) == false, "Checkmate is not stalemate")

func test_stalemate():
	var board = BoardState.new()
	var history = GameHistory.new()
	var rules = ChessRules.new()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0)) # a1
	var bq = ChessPiece.new(ChessTypes.PieceType.QUEEN, ChessTypes.PieceColor.BLACK, Vector2i(2, 1)) # c2
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(7, 7)) # h8 (far away)
	
	board.set_piece(wk.position, wk)
	board.set_piece(bq.position, bq)
	board.set_piece(bk.position, bk)
	
	# White king is not attacked on a1, but b1, a2, b2 are attacked by the queen.
	assert(rules.is_in_check(board, ChessTypes.PieceColor.WHITE) == false, "White is NOT in check")
	assert(rules.is_stalemate(board, history, ChessTypes.PieceColor.WHITE) == true, "White is in stalemate")
	assert(rules.is_checkmate(board, history, ChessTypes.PieceColor.WHITE) == false, "Stalemate is not checkmate")
