extends SceneTree

func _init():
	print("Running MoveGenerator tests...")
	
	test_knight()
	test_bishop()
	test_rook()
	test_queen()
	test_king()
	test_pawn()
	test_initial_position()
	
	print("All MoveGenerator tests passed successfully!")
	quit()

func _find_move(moves: Array[ChessMove], to: Vector2i) -> ChessMove:
	for m in moves:
		if m.to_position == to:
			return m
	return null

func test_knight():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	
	var knight = ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.WHITE, Vector2i(3, 3))
	board.set_piece(knight.position, knight)
	
	var moves = generator.generate_moves(board, knight.position)
	assert(moves.size() == 8, "Center knight should have 8 moves on empty board")
	
	# Block one with friendly
	var friendly = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(4, 5))
	board.set_piece(friendly.position, friendly)
	
	moves = generator.generate_moves(board, knight.position)
	assert(moves.size() == 7, "Knight should have 7 moves when one is blocked by friendly")
	assert(_find_move(moves, Vector2i(4, 5)) == null, "Knight cannot move to friendly occupied square")
	
	# Capture enemy
	var enemy = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(5, 4))
	board.set_piece(enemy.position, enemy)
	
	moves = generator.generate_moves(board, knight.position)
	assert(moves.size() == 7, "Knight still has 7 valid destinations")
	var cap_move = _find_move(moves, Vector2i(5, 4))
	assert(cap_move != null and cap_move.is_capture(), "Knight should be able to capture enemy")

func test_bishop():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	
	var bishop = ChessPiece.new(ChessTypes.PieceType.BISHOP, ChessTypes.PieceColor.WHITE, Vector2i(3, 3))
	board.set_piece(bishop.position, bishop)
	
	# Block with friendly and enemy
	board.set_piece(Vector2i(5, 5), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(5, 5)))
	board.set_piece(Vector2i(1, 1), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(1, 1)))
	
	var moves = generator.generate_moves(board, bishop.position)
	
	assert(_find_move(moves, Vector2i(4, 4)) != null, "Bishop can move one up-right")
	assert(_find_move(moves, Vector2i(5, 5)) == null, "Bishop cannot move to friendly square")
	assert(_find_move(moves, Vector2i(6, 6)) == null, "Bishop cannot move past friendly square")
	
	assert(_find_move(moves, Vector2i(2, 2)) != null, "Bishop can move one down-left")
	var cap_move = _find_move(moves, Vector2i(1, 1))
	assert(cap_move != null and cap_move.is_capture(), "Bishop can capture enemy square")
	assert(_find_move(moves, Vector2i(0, 0)) == null, "Bishop cannot move past captured enemy square")

func test_rook():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	
	var rook = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(3, 3))
	board.set_piece(rook.position, rook)
	
	board.set_piece(Vector2i(3, 5), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(3, 5)))
	board.set_piece(Vector2i(1, 3), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(1, 3)))
	
	var moves = generator.generate_moves(board, rook.position)
	
	assert(_find_move(moves, Vector2i(3, 4)) != null, "Rook can move up")
	assert(_find_move(moves, Vector2i(3, 5)) == null, "Rook blocked by friendly")
	assert(_find_move(moves, Vector2i(3, 6)) == null, "Rook cannot move past friendly")
	
	assert(_find_move(moves, Vector2i(2, 3)) != null, "Rook can move left")
	var cap_move = _find_move(moves, Vector2i(1, 3))
	assert(cap_move != null and cap_move.is_capture(), "Rook can capture enemy")
	assert(_find_move(moves, Vector2i(0, 3)) == null, "Rook cannot move past enemy")

func test_queen():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	
	var queen = ChessPiece.new(ChessTypes.PieceType.QUEEN, ChessTypes.PieceColor.WHITE, Vector2i(3, 3))
	board.set_piece(queen.position, queen)
	var moves = generator.generate_moves(board, queen.position)
	assert(moves.size() == 27, "Center queen on empty board has 27 moves")

func test_king():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	
	var king = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.WHITE, Vector2i(0, 0))
	board.set_piece(king.position, king)
	var moves = generator.generate_moves(board, king.position)
	assert(moves.size() == 3, "Corner king has exactly 3 moves")
	
	# Verify lack of King safety checking (pseudo-legal move allows moving into attack)
	board.set_piece(Vector2i(0, 2), ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(0, 2)))
	moves = generator.generate_moves(board, king.position)
	assert(_find_move(moves, Vector2i(0, 1)) != null, "King should currently be able to move into attack (pseudo-legal)")

func test_pawn():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	
	# White Pawn
	var wp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(1, 1))
	board.set_piece(wp.position, wp)
	
	var moves = generator.generate_moves(board, wp.position)
	assert(moves.size() == 2, "White pawn on start rank has 2 forward moves")
	assert(_find_move(moves, Vector2i(1, 2)) != null, "Single step")
	assert(_find_move(moves, Vector2i(1, 3)) != null, "Double step")
	
	# Block double step
	board.set_piece(Vector2i(1, 3), ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.BLACK, Vector2i(1, 3)))
	moves = generator.generate_moves(board, wp.position)
	assert(moves.size() == 1, "White pawn blocked on double step")
	
	# Block single step (which also blocks double step)
	board.set_piece(Vector2i(1, 2), ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.BLACK, Vector2i(1, 2)))
	moves = generator.generate_moves(board, wp.position)
	assert(moves.size() == 0, "White pawn completely blocked")
	
	# Captures
	board.set_piece(Vector2i(0, 2), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(0, 2)))
	board.set_piece(Vector2i(2, 2), ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.WHITE, Vector2i(2, 2))) # friendly
	moves = generator.generate_moves(board, wp.position)
	assert(moves.size() == 1, "White pawn can only capture the enemy")
	assert(_find_move(moves, Vector2i(0, 2)) != null, "White pawn capturing enemy")
	assert(_find_move(moves, Vector2i(2, 2)) == null, "White pawn cannot capture friendly")
	
	# Black Pawn
	board.clear()
	var bp = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(6, 6))
	board.set_piece(bp.position, bp)
	moves = generator.generate_moves(board, bp.position)
	assert(moves.size() == 2, "Black pawn on start rank has 2 forward moves")
	assert(_find_move(moves, Vector2i(6, 5)) != null, "Single step black")
	assert(_find_move(moves, Vector2i(6, 4)) != null, "Double step black")
	
func test_initial_position():
	var board = BoardState.new()
	var generator = MoveGenerator.new()
	board.setup_initial_position()
	
	# White a2 Pawn
	var wp = board.get_piece(Vector2i(0, 1))
	var moves = generator.generate_moves(board, wp.position)
	assert(moves.size() == 2, "White a2 pawn has 2 moves")
	assert(_find_move(moves, Vector2i(0, 2)) != null, "a2 to a3")
	assert(_find_move(moves, Vector2i(0, 3)) != null, "a2 to a4")
	
	# White b1 Knight
	var wn = board.get_piece(Vector2i(1, 0))
	moves = generator.generate_moves(board, wn.position)
	assert(moves.size() == 2, "White b1 knight has 2 moves")
	assert(_find_move(moves, Vector2i(0, 2)) != null, "b1 to a3")
	assert(_find_move(moves, Vector2i(2, 2)) != null, "b1 to c3")
	
	# Blocked pieces
	var wr = board.get_piece(Vector2i(0, 0))
	assert(generator.generate_moves(board, wr.position).size() == 0, "White a1 rook is blocked")
	
	var wb = board.get_piece(Vector2i(2, 0))
	assert(generator.generate_moves(board, wb.position).size() == 0, "White c1 bishop is blocked")
	
	var wq = board.get_piece(Vector2i(3, 0))
	assert(generator.generate_moves(board, wq.position).size() == 0, "White d1 queen is blocked")
	
	var wk = board.get_piece(Vector2i(4, 0))
	assert(generator.generate_moves(board, wk.position).size() == 0, "White e1 king is blocked")
