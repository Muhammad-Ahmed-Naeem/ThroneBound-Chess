class_name ChessGame
extends RefCounted

signal move_executed(move: ChessMove)

var _board: BoardState
var _history: GameHistory
var _turn_manager: TurnManager
var _rules: ChessRules
var _executor: MoveExecutor

var _move_history: Array[ChessMove] = []
var _current_result: ChessTypes.GameResult = ChessTypes.GameResult.ONGOING

func _init():
	_board = BoardState.new()
	_history = GameHistory.new()
	_turn_manager = TurnManager.new()
	_rules = ChessRules.new()
	_executor = MoveExecutor.new()

func start_new_game() -> void:
	_board.clear()
	_board.setup_initial_position()
	
	# Reset history and turn manager for clean state
	_history = GameHistory.new()
	_turn_manager = TurnManager.new()
	
	_move_history.clear()
	_current_result = ChessTypes.GameResult.ONGOING
	
	_history.record_position(_board, _turn_manager.current_turn)

func get_current_turn() -> ChessTypes.PieceColor:
	return _turn_manager.current_turn

func get_board() -> BoardState:
	return _board

func is_game_over() -> bool:
	return _current_result != ChessTypes.GameResult.ONGOING

func get_game_result() -> ChessTypes.GameResult:
	return _current_result

func is_current_player_in_check() -> bool:
	return _rules.is_in_check(_board, _turn_manager.current_turn)

func get_legal_moves_for_square(pos: Vector2i) -> Array[ChessMove]:
	return _rules.generate_legal_moves(_board, pos, _history)

func get_all_legal_moves(color: ChessTypes.PieceColor) -> Array[ChessMove]:
	return _rules.get_all_legal_moves(_board, _history, color)

func try_move(from: Vector2i, to: Vector2i, promotion_type: int = -1) -> ChessTypes.MoveResult:
	if is_game_over():
		return ChessTypes.MoveResult.GAME_OVER
		
	var source_piece = _board.get_piece(from)
	if source_piece == null:
		return ChessTypes.MoveResult.INVALID_SOURCE
		
	if source_piece.color != _turn_manager.current_turn:
		return ChessTypes.MoveResult.WRONG_TURN
		
	var legal_moves = get_legal_moves_for_square(from)
	var matched_move: ChessMove = null
	
	for move in legal_moves:
		if move.to_position == to:
			if move.move_type == ChessMove.MoveType.PROMOTION:
				if promotion_type != -1 and move.promotion_type == promotion_type:
					matched_move = move
					break
			else:
				if promotion_type != -1:
					return ChessTypes.MoveResult.INVALID_PROMOTION
				matched_move = move
				break
				
	if matched_move == null:
		# If we failed to find a match but the destination is valid for promotion, it means 
		# the user requested a move without specifying a valid promotion type.
		for move in legal_moves:
			if move.to_position == to and move.move_type == ChessMove.MoveType.PROMOTION:
				return ChessTypes.MoveResult.INVALID_PROMOTION
		return ChessTypes.MoveResult.ILLEGAL_MOVE
		
	# Execute
	_executor.execute_move(_board, matched_move, _history)
	_move_history.append(matched_move)
	_turn_manager.switch_turn()
	_history.record_position(_board, _turn_manager.current_turn)
	
	_evaluate_terminal_state()
	
	move_executed.emit(matched_move)
	return ChessTypes.MoveResult.SUCCESS

func _evaluate_terminal_state() -> void:
	var turn = _turn_manager.current_turn
	var has_moves = get_all_legal_moves(turn).size() > 0
	var in_check = _rules.is_in_check(_board, turn)
	
	if not has_moves:
		if in_check:
			_current_result = ChessTypes.GameResult.CHECKMATE
		else:
			_current_result = ChessTypes.GameResult.STALEMATE
		return
		
	if _rules.is_insufficient_material(_board):
		_current_result = ChessTypes.GameResult.DRAW_INSUFFICIENT_MATERIAL
		return
		
	if _rules.is_draw_by_fifty_move_rule(_history):
		_current_result = ChessTypes.GameResult.DRAW_FIFTY_MOVE
		return
		
	if _rules.is_draw_by_repetition(_history):
		_current_result = ChessTypes.GameResult.DRAW_THREEFOLD_REPETITION
		return
		
	_current_result = ChessTypes.GameResult.ONGOING
