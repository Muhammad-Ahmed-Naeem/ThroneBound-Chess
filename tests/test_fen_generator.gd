extends SceneTree

const FenGeneratorClass = preload("res://scripts/ai/fen_generator.gd")

var passed = 0
var failed = 0

func _init():
	print("Running FEN Generator tests...")
	
	test_starting_position()
	test_after_e4()
	test_after_e4_e5()
	test_castling_invalidation()
	test_en_passant_target()
	test_halfmove_clock()
	
	if failed == 0:
		print("All FEN Generator tests passed successfully!")
	else:
		print("FAILED %d FEN Generator tests." % failed)
		
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, test_name: String):
	if actual == expected:
		passed += 1
	else:
		failed += 1
		printerr("TEST FAILED: %s\n  Expected: %s\n  Actual:   %s" % [test_name, expected, actual])

func test_starting_position():
	var game = ChessGame.new()
	game.start_new_game()
	
	var expected = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
	var actual = FenGeneratorClass.generate_fen(game)
	assert_eq(actual, expected, "Starting position")

func test_after_e4():
	var game = ChessGame.new()
	game.start_new_game()
	
	game.try_move(Vector2i(4, 1), Vector2i(4, 3)) # e2-e4
	
	var expected = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
	var actual = FenGeneratorClass.generate_fen(game)
	assert_eq(actual, expected, "After e4")

func test_after_e4_e5():
	var game = ChessGame.new()
	game.start_new_game()
	
	game.try_move(Vector2i(4, 1), Vector2i(4, 3)) # e2-e4
	game.try_move(Vector2i(4, 6), Vector2i(4, 4)) # e7-e5
	
	var expected = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
	var actual = FenGeneratorClass.generate_fen(game)
	assert_eq(actual, expected, "After e4 e5")

func test_castling_invalidation():
	var game = ChessGame.new()
	game.start_new_game()
	
	# Move e-pawns and h-pawn
	game.try_move(Vector2i(4, 1), Vector2i(4, 3)) # e4
	game.try_move(Vector2i(7, 6), Vector2i(7, 4)) # h5
	
	# Move White King up
	game.try_move(Vector2i(4, 0), Vector2i(4, 1)) # Ke2
	
	# Castling for white should be lost
	var fen = FenGeneratorClass.generate_fen(game)
	var expected = "rnbqkbnr/ppppppp1/8/7p/4P3/8/PPPPKPPP/RNBQ1BNR b kq - 1 2"
	assert_eq(fen, expected, "White king moved, lost KQ")
	
	# Move Black Rook on h8
	game.try_move(Vector2i(7, 7), Vector2i(7, 5)) # Rh6
	fen = FenGeneratorClass.generate_fen(game)
	# Now castling is just "q" because black lost kingside (k)
	assert_eq(fen, "rnbqkbn1/ppppppp1/7r/7p/4P3/8/PPPPKPPP/RNBQ1BNR w q - 2 3", "Black h8 rook moved, lost k")

func test_en_passant_target():
	var game = ChessGame.new()
	game.start_new_game()
	
	game.try_move(Vector2i(0, 1), Vector2i(0, 3)) # a2-a4
	var fen = FenGeneratorClass.generate_fen(game)
	assert_eq(fen, "rnbqkbnr/pppppppp/8/8/P7/8/1PPPPPPP/RNBQKBNR b KQkq a3 0 1", "EP target after a4")
	
	# Next move clears EP target
	game.try_move(Vector2i(1, 6), Vector2i(1, 5)) # b7-b6
	fen = FenGeneratorClass.generate_fen(game)
	assert_eq(fen, "rnbqkbnr/p1pppppp/1p6/8/P7/8/1PPPPPPP/RNBQKBNR w KQkq - 0 2", "EP target cleared")

func test_halfmove_clock():
	var game = ChessGame.new()
	game.start_new_game()
	
	# Knight move increments clock
	game.try_move(Vector2i(1, 0), Vector2i(2, 2)) # Nb1-c3
	assert_eq(FenGeneratorClass.generate_fen(game).split(" ")[4], "1", "Halfmove 1")
	
	game.try_move(Vector2i(1, 7), Vector2i(2, 5)) # Nb8-c6
	assert_eq(FenGeneratorClass.generate_fen(game).split(" ")[4], "2", "Halfmove 2")
	
	# Pawn move resets clock
	game.try_move(Vector2i(0, 1), Vector2i(0, 2)) # a2-a3
	assert_eq(FenGeneratorClass.generate_fen(game).split(" ")[4], "0", "Halfmove reset")
