extends SceneTree

const HUDScene = preload("res://scenes/ui/game_hud.tscn")

func _init():
	print("Running Captured HUD tests...")
	
	test_hud_capture_recording()
	test_material_advantage_calculation()
	test_hud_reset()
	test_king_ignored()
	
	print("All Captured HUD tests passed successfully!")
	quit()

func test_hud_capture_recording():
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	
	var black_pawn = ChessPiece.new(ChessTypes.PieceType.PAWN, ChessTypes.PieceColor.BLACK, Vector2i(3, 4))
	var black_knight = ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.BLACK, Vector2i(2, 2))
	
	hud.record_capture(black_pawn, ChessTypes.PieceColor.WHITE)
	assert(hud._captured_by_white[ChessTypes.PieceType.PAWN] == 1, "White recorded 1 Black pawn captured")
	
	hud.record_capture(black_pawn, ChessTypes.PieceColor.WHITE)
	assert(hud._captured_by_white[ChessTypes.PieceType.PAWN] == 2, "White recorded 2 Black pawns captured")
	
	hud.record_capture(black_knight, ChessTypes.PieceColor.WHITE)
	assert(hud._captured_by_white[ChessTypes.PieceType.KNIGHT] == 1, "White recorded 1 Black knight captured")
	
	hud.queue_free()

func test_material_advantage_calculation():
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	
	# White captures Black Rook (5) and Black Knight (3) -> 8 pts
	var black_rook = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.BLACK, Vector2i(0, 0))
	var black_knight = ChessPiece.new(ChessTypes.PieceType.KNIGHT, ChessTypes.PieceColor.BLACK, Vector2i(1, 0))
	hud.record_capture(black_rook, ChessTypes.PieceColor.WHITE)
	hud.record_capture(black_knight, ChessTypes.PieceColor.WHITE)
	
	# Black captures White Bishop (3) -> 3 pts
	var white_bishop = ChessPiece.new(ChessTypes.PieceType.BISHOP, ChessTypes.PieceColor.WHITE, Vector2i(2, 7))
	hud.record_capture(white_bishop, ChessTypes.PieceColor.BLACK)
	
	# White lead = 8 - 3 = +5
	assert(hud.white_advantage_label.text == "+5", "White has +5 material advantage")
	assert(hud.white_advantage_label.visible == true, "White advantage label is visible")
	assert(hud.black_advantage_label.visible == false, "Black advantage label is hidden")
	
	# Black captures White Rook (5) -> Total Black = 8 pts
	var white_rook = ChessPiece.new(ChessTypes.PieceType.ROOK, ChessTypes.PieceColor.WHITE, Vector2i(0, 7))
	hud.record_capture(white_rook, ChessTypes.PieceColor.BLACK)
	
	# Equal material 8 vs 8 -> both labels hidden
	assert(hud.white_advantage_label.visible == false, "Equal material hides White advantage")
	assert(hud.black_advantage_label.visible == false, "Equal material hides Black advantage")
	
	# Black captures White Queen (9) -> Total Black = 17 pts, Total White = 8 pts -> Black lead = +9
	var white_queen = ChessPiece.new(ChessTypes.PieceType.QUEEN, ChessTypes.PieceColor.WHITE, Vector2i(3, 7))
	hud.record_capture(white_queen, ChessTypes.PieceColor.BLACK)
	
	assert(hud.black_advantage_label.text == "+9", "Black has +9 material advantage")
	assert(hud.black_advantage_label.visible == true, "Black advantage label is visible")
	assert(hud.white_advantage_label.visible == false, "White advantage label is hidden")
	
	hud.queue_free()

func test_hud_reset():
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	
	var black_queen = ChessPiece.new(ChessTypes.PieceType.QUEEN, ChessTypes.PieceColor.BLACK, Vector2i(3, 3))
	hud.record_capture(black_queen, ChessTypes.PieceColor.WHITE)
	
	assert(hud._captured_by_white.size() > 0, "Captures exist before reset")
	
	hud.reset_hud()
	
	assert(hud._captured_by_white.size() == 0, "White captures cleared after reset")
	assert(hud._captured_by_black.size() == 0, "Black captures cleared after reset")
	assert(hud.white_advantage_label.visible == false, "White advantage label hidden after reset")
	assert(hud.black_advantage_label.visible == false, "Black advantage label hidden after reset")
	
	hud.queue_free()

func test_king_ignored():
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	
	var black_king = ChessPiece.new(ChessTypes.PieceType.KING, ChessTypes.PieceColor.BLACK, Vector2i(4, 7))
	hud.record_capture(black_king, ChessTypes.PieceColor.WHITE)
	
	assert(hud._captured_by_white.size() == 0, "King capture is ignored")
	
	hud.queue_free()
