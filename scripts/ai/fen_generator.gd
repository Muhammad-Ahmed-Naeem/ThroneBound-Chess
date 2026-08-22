class_name FenGenerator
extends RefCounted

static func generate_fen(game: ChessGame) -> String:
	var board = game.get_board()
	var history = game._history
	var current_turn = game.get_current_turn()
	var move_history = game._move_history
	
	var fen = ""
	
	# 1. Piece Placement (Rank 7 down to 0)
	for rank in range(7, -1, -1):
		var empty_count = 0
		for file in range(8):
			var pos = Vector2i(file, rank)
			var piece = board.get_piece(pos)
			
			if piece == null:
				empty_count += 1
			else:
				if empty_count > 0:
					fen += str(empty_count)
					empty_count = 0
				fen += piece.get_fen_char()
				
		if empty_count > 0:
			fen += str(empty_count)
			
		if rank > 0:
			fen += "/"
			
	# 2. Active Color
	fen += " w " if current_turn == ChessTypes.PieceColor.WHITE else " b "
	
	# 3. Castling Availability
	var castling = ""
	if history.white_can_castle_kingside: castling += "K"
	if history.white_can_castle_queenside: castling += "Q"
	if history.black_can_castle_kingside: castling += "k"
	if history.black_can_castle_queenside: castling += "q"
	
	if castling == "":
		fen += "- "
	else:
		fen += castling + " "
		
	# 4. En Passant Target
	if history.en_passant_target != null:
		fen += _pos_to_algebraic(history.en_passant_target) + " "
	else:
		fen += "- "
		
	# 5. Halfmove Clock
	fen += str(history.halfmove_clock) + " "
	
	# 6. Fullmove Number
	var fullmove = 1 + (move_history.size() / 2)
	fen += str(fullmove)
	
	return fen

static func _pos_to_algebraic(pos: Vector2i) -> String:
	var file = String.chr("a".unicode_at(0) + pos.x)
	var rank = str(pos.y + 1)
	return file + rank
