extends SceneTree

func _init():
	print("Running BoardState tests...")
	var board = BoardState.new()
	board.setup_initial_position()
	
	print("\nInitial Board:")
	print(board.get_debug_board_string())
	print("\n")
	
	# 1. Board dimensions
	assert(board._board.size() == 64, "Board must have 64 squares")
	
	# 2. Initial piece count
	var all_pieces = board.get_all_pieces()
	assert(all_pieces.size() == 32, "Initial position must have 32 pieces")
	
	var white_counts = {
		ChessTypes.PieceType.PAWN: 0, ChessTypes.PieceType.KNIGHT: 0, ChessTypes.PieceType.BISHOP: 0,
		ChessTypes.PieceType.ROOK: 0, ChessTypes.PieceType.QUEEN: 0, ChessTypes.PieceType.KING: 0
	}
	var black_counts = {
		ChessTypes.PieceType.PAWN: 0, ChessTypes.PieceType.KNIGHT: 0, ChessTypes.PieceType.BISHOP: 0,
		ChessTypes.PieceType.ROOK: 0, ChessTypes.PieceType.QUEEN: 0, ChessTypes.PieceType.KING: 0
	}
	
	var empty_squares = 0
	for file in range(8):
		for rank in range(8):
			var pos = Vector2i(file, rank)
			if not board.is_occupied(pos):
				empty_squares += 1
			else:
				var p = board.get_piece(pos)
				if p.color == ChessTypes.PieceColor.WHITE:
					white_counts[p.type] += 1
				else:
					black_counts[p.type] += 1
	
	assert(white_counts[ChessTypes.PieceType.PAWN] == 8, "8 White Pawns expected")
	assert(white_counts[ChessTypes.PieceType.KNIGHT] == 2, "2 White Knights expected")
	assert(white_counts[ChessTypes.PieceType.BISHOP] == 2, "2 White Bishops expected")
	assert(white_counts[ChessTypes.PieceType.ROOK] == 2, "2 White Rooks expected")
	assert(white_counts[ChessTypes.PieceType.QUEEN] == 1, "1 White Queen expected")
	assert(white_counts[ChessTypes.PieceType.KING] == 1, "1 White King expected")
	
	assert(black_counts[ChessTypes.PieceType.PAWN] == 8, "8 Black Pawns expected")
	assert(black_counts[ChessTypes.PieceType.KNIGHT] == 2, "2 Black Knights expected")
	assert(black_counts[ChessTypes.PieceType.BISHOP] == 2, "2 Black Bishops expected")
	assert(black_counts[ChessTypes.PieceType.ROOK] == 2, "2 Black Rooks expected")
	assert(black_counts[ChessTypes.PieceType.QUEEN] == 1, "1 Black Queen expected")
	assert(black_counts[ChessTypes.PieceType.KING] == 1, "1 Black King expected")
	
	assert(empty_squares == 32, "32 empty squares expected")
	
	# 3. Specific positions verification
	var a1 = board.get_piece(Vector2i(0, 0))
	assert(a1 != null and a1.color == ChessTypes.PieceColor.WHITE and a1.type == ChessTypes.PieceType.ROOK, "a1 is White Rook")
	
	var e1 = board.get_piece(Vector2i(4, 0))
	assert(e1 != null and e1.color == ChessTypes.PieceColor.WHITE and e1.type == ChessTypes.PieceType.KING, "e1 is White King")
	
	var d1 = board.get_piece(Vector2i(3, 0))
	assert(d1 != null and d1.color == ChessTypes.PieceColor.WHITE and d1.type == ChessTypes.PieceType.QUEEN, "d1 is White Queen")
	
	var e2 = board.get_piece(Vector2i(4, 1))
	assert(e2 != null and e2.color == ChessTypes.PieceColor.WHITE and e2.type == ChessTypes.PieceType.PAWN, "e2 is White Pawn")
	
	var a8 = board.get_piece(Vector2i(0, 7))
	assert(a8 != null and a8.color == ChessTypes.PieceColor.BLACK and a8.type == ChessTypes.PieceType.ROOK, "a8 is Black Rook")
	
	var e8 = board.get_piece(Vector2i(4, 7))
	assert(e8 != null and e8.color == ChessTypes.PieceColor.BLACK and e8.type == ChessTypes.PieceType.KING, "e8 is Black King")
	
	var d8 = board.get_piece(Vector2i(3, 7))
	assert(d8 != null and d8.color == ChessTypes.PieceColor.BLACK and d8.type == ChessTypes.PieceType.QUEEN, "d8 is Black Queen")
	
	var e7 = board.get_piece(Vector2i(4, 6))
	assert(e7 != null and e7.color == ChessTypes.PieceColor.BLACK and e7.type == ChessTypes.PieceType.PAWN, "e7 is Black Pawn")
	
	# 4. Invalid coordinates verification
	assert(board.is_occupied(Vector2i(-1, 0)) == false, "Invalid coordinate is not occupied")
	assert(board.get_piece(Vector2i(8, 8)) == null, "Invalid coordinate returns null")
	
	print("All BoardState tests passed successfully!")
	quit()
