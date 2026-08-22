class_name StockfishAdapter
extends Node

const GameConfig = preload("res://scripts/ui/game_configuration.gd")
const FenGeneratorClass = preload("res://scripts/ai/fen_generator.gd")
const StockfishEngineClass = preload("res://scripts/ai/stockfish_engine.gd")

var _engine: StockfishEngineClass
var _current_game: ChessGame
var _pending_request: bool = false
var _pending_fen: String = ""
var _pending_difficulty: int = 1

func _ready() -> void:
	_engine = StockfishEngineClass.new()
	add_child(_engine)
	_engine.engine_ready.connect(_on_engine_ready)
	_engine.bestmove_received.connect(_on_bestmove_received)
	_engine.engine_error.connect(_on_engine_error)
	
	_engine.start_engine()

func request_move(game: ChessGame, difficulty: int) -> void:
	_current_game = game
	_pending_fen = FenGeneratorClass.generate_fen(game)
	_pending_difficulty = difficulty
	
	if _engine._is_ready:
		_send_search_command()
	else:
		_pending_request = true
		
func stop_search() -> void:
	if _engine._running:
		_engine.send_command("stop")
		
func _on_engine_ready() -> void:
	if _pending_request:
		_pending_request = false
		_send_search_command()

func _send_search_command() -> void:
	var depth = 5
	var movetime = 500
	
	match _pending_difficulty:
		GameConfig.AIDifficulty.EASY:
			depth = 1
			movetime = 100
		GameConfig.AIDifficulty.MEDIUM:
			depth = 5
			movetime = 500
		GameConfig.AIDifficulty.HARD:
			depth = 12
			movetime = 1500
			
	_engine.send_command("position fen " + _pending_fen)
	_engine.send_command("go depth %d movetime %d" % [depth, movetime])

func _on_bestmove_received(uci_move: String) -> void:
	if _current_game == null or _current_game.is_game_over():
		return
		
	var parsed = parse_uci_move(uci_move)
	if parsed.is_empty():
		printerr("Invalid UCI move length: ", uci_move)
		return
		
	var res = _current_game.try_move(parsed["from"], parsed["to"], parsed["promotion"])
	if res != ChessTypes.MoveResult.SUCCESS:
		printerr("Stockfish returned illegal move: ", uci_move, " result: ", res)

func _on_engine_error(msg: String) -> void:
	pass

static func parse_uci_move(uci_move: String) -> Dictionary:
	if uci_move.length() < 4: return {}
	
	var file_from = uci_move.unicode_at(0) - "a".unicode_at(0)
	var rank_from = uci_move.unicode_at(1) - "1".unicode_at(0)
	var file_to = uci_move.unicode_at(2) - "a".unicode_at(0)
	var rank_to = uci_move.unicode_at(3) - "1".unicode_at(0)
	
	var from_pos = Vector2i(file_from, rank_from)
	var to_pos = Vector2i(file_to, rank_to)
	
	var promotion = -1
	if uci_move.length() == 5:
		var p_char = uci_move.substr(4, 1)
		match p_char:
			"q": promotion = ChessTypes.PieceType.QUEEN
			"r": promotion = ChessTypes.PieceType.ROOK
			"b": promotion = ChessTypes.PieceType.BISHOP
			"n": promotion = ChessTypes.PieceType.KNIGHT
			
	return {
		"from": from_pos,
		"to": to_pos,
		"promotion": promotion
	}
