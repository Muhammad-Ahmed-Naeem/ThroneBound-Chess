extends SceneTree

func _init():
	print("Running ChessGame tests...")
	
	test_initialization()
	test_invalid_requests()
	test_normal_play()
	test_capture()
	test_castling()
	test_en_passant()
	test_promotion()
	test_check()
	test_checkmate()
	test_stalemate()
	test_draw()
	
	print("All ChessGame tests passed successfully!")
	quit()

func test_initialization():
	var game = ChessGame.new()
	game.start_new_game()
	
	assert(game.get_current_turn() == ChessTypes.PieceColor.WHITE, "White moves first")
	assert(game.get_game_result() == ChessTypes.GameResult.ONGOING, "Game is ONGOING")
	assert(game._move_history.size() == 0, "No move history initially")
	assert(game.get_board().get_piece(Vector2i(0, 0)) != null, "Standard board is initialized")

func test_invalid_requests():
	var game = ChessGame.new()
	game.start_new_game()
	
	# Empty source
	assert(game.try_move(Vector2i(4, 4), Vector2i(4, 5)) == ChessTypes.MoveResult.INVALID_SOURCE, "Cannot move from empty square")
	
	# Wrong turn
	assert(game.try_move(Vector2i(4, 6), Vector2i(4, 5)) == ChessTypes.MoveResult.WRONG_TURN, "Black cannot move on White's turn")
	
	# Illegal destination
	assert(game.try_move(Vector2i(4, 1), Vector2i(4, 4)) == ChessTypes.MoveResult.ILLEGAL_MOVE, "Pawn cannot jump 3 squares")
	
	# Blocked movement
	assert(game.try_move(Vector2i(0, 0), Vector2i(0, 2)) == ChessTypes.MoveResult.ILLEGAL_MOVE, "Rook cannot jump over pawn")
	
	assert(game.get_current_turn() == ChessTypes.PieceColor.WHITE, "Turn remains unchanged")
	assert(game._move_history.size() == 0, "Move history remains unchanged")

func test_normal_play():
	var game = ChessGame.new()
	game.start_new_game()
	
	# e2-e4
	assert(game.try_move(Vector2i(4, 1), Vector2i(4, 3)) == ChessTypes.MoveResult.SUCCESS)
	assert(game.get_current_turn() == ChessTypes.PieceColor.BLACK)
	
	# e7-e5
	assert(game.try_move(Vector2i(4, 6), Vector2i(4, 4)) == ChessTypes.MoveResult.SUCCESS)
	assert(game.get_current_turn() == ChessTypes.PieceColor.WHITE)
	
	# g1-f3
	assert(game.try_move(Vector2i(6, 0), Vector2i(5, 2)) == ChessTypes.MoveResult.SUCCESS)
	
	assert(game._move_history.size() == 3, "Move history grew")
	assert(game.get_game_result() == ChessTypes.GameResult.ONGOING, "Game remains ONGOING")

func test_capture():
	var game = ChessGame.new()
	game.start_new_game()
	
	# Scandinavian Defense: e4, d5, exd5
	game.try_move(Vector2i(4, 1), Vector2i(4, 3)) # e4
	game.try_move(Vector2i(3, 6), Vector2i(3, 4)) # d5
	
	assert(game.try_move(Vector2i(4, 3), Vector2i(3, 4)) == ChessTypes.MoveResult.SUCCESS, "White captures on d5")
	var p = game.get_board().get_piece(Vector2i(3, 4))
	assert(p != null and p.color == ChessTypes.PieceColor.WHITE, "White pawn arrived at d5")
	assert(game._move_history.back().is_capture(), "Move history recorded capture")
	assert(game.get_current_turn() == ChessTypes.PieceColor.BLACK, "Turn changed to Black")

func test_castling():
	var game = ChessGame.new()
	# Constructing a minimal position for castling
	var b = game.get_board()
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(4, 0))
	var wr = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(7, 0))
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(4, 7))
	b.set_piece(wk.position, wk)
	b.set_piece(wr.position, wr)
	b.set_piece(bk.position, bk)
	
	# Fake history for castling rights
	game._history.record_position(b, ChessTypes.PieceColor.WHITE)
	
	assert(game.try_move(Vector2i(4, 0), Vector2i(6, 0)) == ChessTypes.MoveResult.SUCCESS, "Kingside castling executed")
	assert(b.get_piece(Vector2i(6, 0)) == wk, "King moved to g1")
	assert(b.get_piece(Vector2i(5, 0)) == wr, "Rook moved to f1")
	assert(game._move_history.back().move_type == ChessMove.MoveType.CASTLE_KINGSIDE, "Castling recorded")

func test_en_passant():
	var game = ChessGame.new()
	var b = game.get_board()
	
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(4, 4)) # e5
	var bp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(3, 6)) # d7
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(0, 7))
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(7, 0))
	
	b.set_piece(wp.position, wp)
	b.set_piece(bp.position, bp)
	b.set_piece(bk.position, bk)
	b.set_piece(wk.position, wk)
	
	game._turn_manager.current_turn = ChessTypes.PieceColor.BLACK # Force Black turn
	
	# Black plays d7-d5
	assert(game.try_move(Vector2i(3, 6), Vector2i(3, 4)) == ChessTypes.MoveResult.SUCCESS)
	
	# White plays exd6
	assert(game.try_move(Vector2i(4, 4), Vector2i(3, 5)) == ChessTypes.MoveResult.SUCCESS)
	
	assert(b.get_piece(Vector2i(3, 5)) == wp, "White pawn is on d6")
	assert(b.get_piece(Vector2i(3, 4)) == null, "Black pawn on d5 removed")
	assert(game._move_history.back().move_type == ChessMove.MoveType.EN_PASSANT)

func test_promotion():
	var game = ChessGame.new()
	var b = game.get_board()
	
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(0, 6)) # a7
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(7, 7))
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(7, 0))
	b.set_piece(wp.position, wp)
	b.set_piece(bk.position, bk)
	b.set_piece(wk.position, wk)
	
	# Missing promotion selection
	assert(game.try_move(Vector2i(0, 6), Vector2i(0, 7)) == ChessTypes.MoveResult.INVALID_PROMOTION, "Fails without specifying promotion type")
	
	# Valid promotion
	assert(game.try_move(Vector2i(0, 6), Vector2i(0, 7), ChessTypes.PieceType.QUEEN) == ChessTypes.MoveResult.SUCCESS, "Queen promotion succeeds")
	
	var promoted_piece = b.get_piece(Vector2i(0, 7))
	assert(promoted_piece.type == ChessTypes.PieceType.QUEEN, "Piece type changed to Queen")

func test_check():
	var game = ChessGame.new()
	var b = game.get_board()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0))
	var br = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(7, 7))
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(2, 2))
	b.set_piece(wk.position, wk)
	b.set_piece(br.position, br)
	b.set_piece(bk.position, bk)
	
	game._turn_manager.current_turn = ChessTypes.PieceColor.BLACK # Force Black turn
	
	# Black plays Rh1+
	assert(game.try_move(Vector2i(7, 7), Vector2i(7, 0)) == ChessTypes.MoveResult.SUCCESS)
	
	assert(game.is_current_player_in_check() == true, "White is in check")
	assert(game.get_game_result() == ChessTypes.GameResult.ONGOING, "Game is ONGOING (King can move)")
	assert(game.get_all_legal_moves(ChessTypes.PieceColor.WHITE).size() == 1, "White has exactly 1 legal move (Kb1)")

func test_checkmate():
	var game = ChessGame.new()
	# Fool's mate setup
	game.start_new_game()
	
	game.try_move(Vector2i(5, 1), Vector2i(5, 2)) # f3
	game.try_move(Vector2i(4, 6), Vector2i(4, 4)) # e5
	game.try_move(Vector2i(6, 1), Vector2i(6, 3)) # g4
	
	assert(game.get_game_result() == ChessTypes.GameResult.ONGOING)
	
	# Qh4#
	assert(game.try_move(Vector2i(3, 7), Vector2i(7, 3)) == ChessTypes.MoveResult.SUCCESS)
	
	assert(game.is_current_player_in_check() == true, "White is in check")
	assert(game.get_game_result() == ChessTypes.GameResult.CHECKMATE, "Checkmate detected")
	assert(game.try_move(Vector2i(0, 1), Vector2i(0, 2)) == ChessTypes.MoveResult.GAME_OVER, "Further moves rejected")

func test_stalemate():
	var game = ChessGame.new()
	var b = game.get_board()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0)) # a1
	var bq = ChessPiece.new(ChessTypes.PieceType.QUEEN, ChessTypes.PieceColor.BLACK, Vector2i(1, 2)) # b3
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(7, 7)) # h8
	
	b.set_piece(wk.position, wk)
	b.set_piece(bq.position, bq)
	b.set_piece(bk.position, bk)
	
	game._turn_manager.current_turn = ChessTypes.PieceColor.BLACK # Force Black turn
	
	# Black plays Qc2
	assert(game.try_move(Vector2i(1, 2), Vector2i(2, 1)) == ChessTypes.MoveResult.SUCCESS)
	
	assert(game.is_current_player_in_check() == false, "White is not in check")
	assert(game.get_game_result() == ChessTypes.GameResult.STALEMATE, "Stalemate detected")

func test_draw():
	var game = ChessGame.new()
	var b = game.get_board()
	
	var wk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0))
	var bk = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(7, 7))
	b.set_piece(wk.position, wk)
	b.set_piece(bk.position, bk)
	
	# Evaluate via fake move to trigger state check
	game._history.record_position(b, ChessTypes.PieceColor.BLACK) # Seed position
	assert(game.try_move(Vector2i(0, 0), Vector2i(1, 0)) == ChessTypes.MoveResult.SUCCESS)
	
	assert(game.get_game_result() == ChessTypes.GameResult.DRAW_INSUFFICIENT_MATERIAL, "Insufficient material detected automatically")
