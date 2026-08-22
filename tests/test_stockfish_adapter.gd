extends SceneTree

const StockfishAdapterClass = preload("res://scripts/ai/stockfish_adapter.gd")

var passed = 0
var failed = 0

func _init():
	print("Running UCI parsing tests...")
	
	test_parse_e2e4()
	test_parse_promotion()
	test_parse_castling()
	test_parse_invalid()
	
	if failed == 0:
		print("All UCI parsing tests passed successfully!")
	else:
		print("FAILED %d UCI parsing tests." % failed)
		
	quit(1 if failed > 0 else 0)

func assert_eq(actual, expected, test_name: String):
	if typeof(actual) == typeof(expected) and str(actual) == str(expected):
		passed += 1
	else:
		failed += 1
		printerr("TEST FAILED: %s\n  Expected: %s\n  Actual:   %s" % [test_name, expected, actual])

func test_parse_e2e4():
	var res = StockfishAdapterClass.parse_uci_move("e2e4")
	assert_eq(res["from"], Vector2i(4, 1), "e2 from")
	assert_eq(res["to"], Vector2i(4, 3), "e4 to")
	assert_eq(res["promotion"], -1, "e2e4 promotion")

func test_parse_promotion():
	var res = StockfishAdapterClass.parse_uci_move("e7e8q")
	assert_eq(res["from"], Vector2i(4, 6), "e7 from")
	assert_eq(res["to"], Vector2i(4, 7), "e8 to")
	# 4 is QUEEN in PieceType enum
	assert_eq(res["promotion"], 4, "e7e8q promotion queen")
	
	var res2 = StockfishAdapterClass.parse_uci_move("a2a1n")
	assert_eq(res2["promotion"], 1, "a2a1n promotion knight")

func test_parse_castling():
	var res = StockfishAdapterClass.parse_uci_move("e1g1")
	assert_eq(res["from"], Vector2i(4, 0), "e1 from")
	assert_eq(res["to"], Vector2i(6, 0), "g1 to")
	assert_eq(res["promotion"], -1, "castling promotion")

func test_parse_invalid():
	var res = StockfishAdapterClass.parse_uci_move("e2")
	assert_eq(res.is_empty(), true, "invalid short string")
