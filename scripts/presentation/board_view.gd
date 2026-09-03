class_name BoardView
extends Node3D

const SQUARE_SIZE: float = 2.0

var _game: ChessGame
var _visualizer: MoveVisualizer

var _selected_pos: Vector2i = Vector2i(-1, -1)
var _legal_moves_cache: Array[ChessMove] = []
var _pieces: Dictionary = {} # Maps Vector2i -> PieceController

var _is_animating: bool = false
var _is_waiting_for_promotion: bool = false
var _animations_pending: int = 0
var _graveyard_white: Array[PieceController] = []
var _graveyard_black: Array[PieceController] = []
const CaptureManager = preload("res://scripts/presentation/capture_presentation_manager.gd")
var _capture_manager: CaptureManager

var _env_manager: EnvironmentManager
var _vfx_controller: VFXController
var _audio_controller: AudioController
var _camera_pivot: Node3D

const StockfishAdapterClass = preload("res://scripts/ai/stockfish_adapter.gd")
var _stockfish: StockfishAdapterClass

@onready var game_hud = get_node_or_null("CanvasLayer/GameHUD")
@onready var pause_menu = get_node_or_null("CanvasLayer/PauseMenu")
@onready var result_screen = get_node_or_null("CanvasLayer/GameResultScreen")

func _ready() -> void:
	_game = ChessGame.new()
	_game.move_executed.connect(_on_move_executed)
	_game.start_new_game()
	
	_visualizer = MoveVisualizer.new()
	add_child(_visualizer)
	
	_capture_manager = CaptureManager.new()
	add_child(_capture_manager)
	
	_env_manager = EnvironmentManager.new()
	add_child(_env_manager)
	
	_vfx_controller = VFXController.new()
	add_child(_vfx_controller)
	
	_audio_controller = AudioController.new()
	add_child(_audio_controller)
	
	_stockfish = StockfishAdapterClass.new()
	add_child(_stockfish)
	
	_generate_board()
	
	# Position the camera for a better view using a pivot
	var camera = get_node_or_null("Camera3D")
	if camera:
		_camera_pivot = Node3D.new()
		_camera_pivot.position = Vector3(7.0, 0.0, 7.0)
		add_child(_camera_pivot)
		
		remove_child(camera)
		_camera_pivot.add_child(camera)
		
		camera.position = Vector3(0.0, 12.0, -9.0)
		camera.look_at(_camera_pivot.global_position, Vector3.UP)
		
		# Milestone 12: register pivot with VFXController for combat camera shake
		if _vfx_controller and _vfx_controller.has_method("set_camera_pivot"):
			_vfx_controller.set_camera_pivot(_camera_pivot)
	
	if pause_menu:
		pause_menu.restart_requested.connect(start_match)
		pause_menu.main_menu_requested.connect(func(): SceneTransition.change_scene("res://scenes/ui/main_menu.tscn"))
		pause_menu.visibility_changed.connect(_on_pause_menu_visibility_changed)
		
	if result_screen:
		result_screen.rematch_requested.connect(start_match)
		result_screen.main_menu_requested.connect(func(): SceneTransition.change_scene("res://scenes/ui/main_menu.tscn"))
		
	start_match()

func start_match() -> void:
	get_tree().paused = false
	
	_game.start_new_game()
	_clear_selection()
	
	for pc in _pieces.values():
		pc.queue_free()
	_pieces.clear()
	
	for pc in _graveyard_white:
		pc.queue_free()
	_graveyard_white.clear()
	
	for pc in _graveyard_black:
		pc.queue_free()
	_graveyard_black.clear()
	
	_generate_pieces()
	
	if game_hud:
		if game_hud.has_method("reset_hud"):
			game_hud.reset_hud()
		game_hud.update_hud(_game.get_current_turn(), _game.is_current_player_in_check())
		
	if result_screen:
		result_screen.hide_result()
		
	_update_camera_for_turn(_game.get_current_turn(), true)
	_check_ai_turn()

func _on_pause_menu_visibility_changed() -> void:
	if pause_menu.visible:
		_stockfish.stop_search()
	else:
		_check_ai_turn()

func _is_ai_turn() -> bool:
	if SceneTransition.current_config.game_mode != GameConfigClass.GameMode.VS_AI: return false
	var ai_color = ChessTypes.PieceColor.BLACK if SceneTransition.current_config.player_color == GameConfigClass.PlayerColor.WHITE else ChessTypes.PieceColor.WHITE
	return _game.get_current_turn() == ai_color

func _check_ai_turn() -> void:
	if _is_ai_turn() and not _game.is_game_over() and not get_tree().paused:
		# Update UI slightly to show AI is thinking
		if game_hud and game_hud.has_method("set_title"):
			pass # In future we can set 'AI THINKING...'
			
		# Add a short, human-like reaction delay before requesting the move
		await get_tree().create_timer(randf_range(0.5, 1.2)).timeout
		
		# Double check we are still valid after await
		if _game.is_game_over() or get_tree().paused or not _is_ai_turn():
			return
			
		_stockfish.request_move(_game, SceneTransition.current_config.ai_difficulty)

func _generate_board() -> void:
	var scene = preload("res://assets/models/pieces/scene.gltf").instantiate()
	var board_node = PieceController._find_child_recursive(scene, "board")
	
	if board_node:
		var mesh_instance = MeshInstance3D.new()
		var mesh = PieceController._get_mesh(board_node)
		mesh_instance.mesh = mesh
		
		# Apply calibrated scale
		var aabb = mesh.get_aabb()
		var scale_factor = 19.0 / max(aabb.size.x, aabb.size.z)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Center the board correctly at (7.0, 0, 7.0) with calibrated offset
		var center_offset = aabb.position + (aabb.size / 2.0)
		var target_pos = Vector3(7.0, 0.0, 7.2) # Includes Z offset of 0.2
		mesh_instance.position = target_pos - (center_offset * scale_factor)
		# Ensure the top of the board is slightly below Y=0
		mesh_instance.position.y -= (aabb.position.y + aabb.size.y) * scale_factor + 0.1
		
		add_child(mesh_instance)
	else:
		print("Failed to find board mesh in gltf")

func _generate_pieces() -> void:
	var all = _game.get_board().get_all_pieces()
	for p in all:
		var pc = PieceController.new()
		add_child(pc)
		pc.setup(p, SQUARE_SIZE)
		_pieces[p.position] = pc

func _on_move_executed(move: ChessMove) -> void:
	_is_animating = true
	_visualizer.show_last_move(move, SQUARE_SIZE)
	_clear_selection()
	
	var board_state = _game.get_board()
	var current_logical_pieces = board_state.get_all_pieces()
	
	var old_pieces_list = _pieces.values()
	_pieces.clear()
	_animations_pending = 0
	
	var attacker_pc: PieceController = null
	var defender_pc: PieceController = null
	
	if move.captured_piece != null:
		if game_hud and game_hud.has_method("record_capture"):
			game_hud.record_capture(move.captured_piece, move.moving_piece.color)
		# Find the exact nodes for attacker and defender by reference, NOT by position
		# (since MoveExecutor already changed moving_piece.position)
		for pc in old_pieces_list:
			if pc.logical_piece == move.moving_piece:
				attacker_pc = pc
			if pc.logical_piece == move.captured_piece:
				defender_pc = pc
				
	# Reconcile new logical state with visual pieces
	for new_logical in current_logical_pieces:
		var pc: PieceController = null
		
		if new_logical.position == move.to_position and attacker_pc != null:
			pc = attacker_pc
			pc.logical_piece = new_logical
		else:
			for old_pc in old_pieces_list:
				if old_pc.logical_piece == new_logical:
					pc = old_pc
					break
			# Handle non-capturing promotion (new logical piece on destination, old pawn on source)
			if pc == null and new_logical.position == move.to_position:
				for old_pc in old_pieces_list:
					if old_pc.logical_piece.position == move.from_position:
						pc = old_pc
						pc.logical_piece = new_logical
						break
						
		if pc == null:
			pc = PieceController.new()
			add_child(pc)
			pc.setup(new_logical, SQUARE_SIZE)
			
		_pieces[new_logical.position] = pc
		old_pieces_list.erase(pc)
		
		if pc == attacker_pc:
			continue # Handled by combat sequence
			
		var new_world = chess_to_world(new_logical.position)
		var flat_old = Vector2(pc.position.x, pc.position.z)
		var flat_new = Vector2(new_world.x, new_world.z)
		
		pc.update_visuals(SQUARE_SIZE)
		
		if flat_old.distance_to(flat_new) > 0.1:
			_animations_pending += 1
			pc.move_completed.connect(_on_piece_animation_done, CONNECT_ONE_SHOT)
			pc.move_to(new_logical.position, SQUARE_SIZE)
			_audio_controller.play_movement(new_world)
			
	for pc in old_pieces_list:
		if pc == defender_pc:
			continue # Handled by combat sequence
		pc.queue_free()
		
	if attacker_pc and defender_pc:
		_animations_pending += 1
		attacker_pc.update_visuals(SQUARE_SIZE) # Update immediately for promotion visuals
		
		var is_white = defender_pc.logical_piece.color == ChessTypes.PieceColor.WHITE
		var graveyard = _graveyard_white if is_white else _graveyard_black
		var count = graveyard.size()
		graveyard.append(defender_pc)
		
		var target_x = -4.0 if is_white else 18.0
		var target_z = float(count) * 1.2
		var target_world = Vector3(target_x, 0, target_z)
		
		_capture_manager.capture_presentation_finished.connect(_on_piece_animation_done, CONNECT_ONE_SHOT)
		_capture_manager.play_capture_sequence(attacker_pc, defender_pc, move, SQUARE_SIZE, target_world, _vfx_controller, _audio_controller)
			
	if _animations_pending == 0:
		_on_piece_animation_done()

func _on_piece_animation_done() -> void:
	if _animations_pending > 0:
		_animations_pending -= 1
	if _animations_pending == 0:
		_is_animating = false
		if game_hud:
			game_hud.update_hud(_game.get_current_turn(), _game.is_current_player_in_check())
			
		_update_camera_for_turn(_game.get_current_turn(), false)
		
		if _game.is_game_over():
			var winner = -1
			if _game.get_game_result() == ChessTypes.GameResult.CHECKMATE:
				winner = ChessTypes.PieceColor.WHITE if _game.get_current_turn() == ChessTypes.PieceColor.BLACK else ChessTypes.PieceColor.BLACK
			if result_screen:
				result_screen.display_result(_game.get_game_result(), winner)
		else:
			_check_ai_turn()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and pause_menu:
		if _game.is_game_over(): return
		if not get_tree().paused:
			pause_menu.open()
		return
		
	if _is_animating or _is_waiting_for_promotion or get_tree().paused or _game.is_game_over(): return
	if _is_ai_turn(): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera = get_viewport().get_camera_3d()
		if not camera: return
		
		var mouse_pos = event.position
		var origin = camera.project_ray_origin(mouse_pos)
		var normal = camera.project_ray_normal(mouse_pos)
		
		var plane = Plane(Vector3.UP, 0.0)
		var hit = plane.intersects_ray(origin, normal)
		if hit != null:
			var chess_pos = world_to_chess(hit)
			_handle_square_click(chess_pos)

func _handle_square_click(pos: Vector2i) -> void:
	if pos.x < 0 or pos.x > 7 or pos.y < 0 or pos.y > 7:
		_clear_selection()
		return
		
	# Try to execute move if a piece is currently selected
	if _selected_pos != Vector2i(-1, -1):
		var target_move: ChessMove = null
		for m in _legal_moves_cache:
			if m.to_position == pos:
				target_move = m
				break
				
		if target_move != null:
			if target_move.move_type == ChessMove.MoveType.PROMOTION:
				_show_promotion_menu(_selected_pos, pos)
				return
				
			var res = _game.try_move(_selected_pos, pos, -1)
			if res == ChessTypes.MoveResult.SUCCESS:
				return
				
		_clear_selection()
	
	var clicked_piece = _game.get_board().get_piece(pos)
	if clicked_piece != null and clicked_piece.color == _game.get_current_turn():
		_selected_pos = pos
		if _pieces.has(pos):
			_pieces[pos].set_selected(true)
		_legal_moves_cache = _game.get_legal_moves_for_square(pos)
		_visualizer.show_legal_moves(_legal_moves_cache, SQUARE_SIZE)

func _clear_selection() -> void:
	if _selected_pos != Vector2i(-1, -1):
		if _pieces.has(_selected_pos):
			_pieces[_selected_pos].set_selected(false)
		_selected_pos = Vector2i(-1, -1)
	_legal_moves_cache.clear()
	_visualizer.clear_visuals()

func _show_promotion_menu(from_pos: Vector2i, to_pos: Vector2i) -> void:
	_is_waiting_for_promotion = true
	var menu = PromotionMenu.new()
	menu.piece_selected.connect(func(piece_type: int):
		_on_promotion_selected(from_pos, to_pos, piece_type)
	)
	add_child(menu)

func _on_promotion_selected(from_pos: Vector2i, to_pos: Vector2i, piece_type: int) -> void:
	_is_waiting_for_promotion = false
	var res = _game.try_move(from_pos, to_pos, piece_type)
	if res == ChessTypes.MoveResult.SUCCESS:
		pass # Move handled by signal
	_clear_selection()

func chess_to_world(pos: Vector2i) -> Vector3:
	return Vector3(pos.x * SQUARE_SIZE, 0, pos.y * SQUARE_SIZE)

func world_to_chess(pos: Vector3) -> Vector2i:
	var x = round(pos.x / SQUARE_SIZE)
	var z = round(pos.z / SQUARE_SIZE)
	return Vector2i(x, z)

const GameConfigClass = preload("res://scripts/ui/game_configuration.gd")

func _update_camera_for_turn(turn: int, instant: bool = false) -> void:
	if not _camera_pivot: return
	
	if SceneTransition.current_config.game_mode == GameConfigClass.GameMode.LOCAL_2_PLAYER:
		var target_rotation_y = 0.0 if turn == ChessTypes.PieceColor.WHITE else PI
		
		if instant:
			_camera_pivot.rotation.y = target_rotation_y
		else:
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(_camera_pivot, "rotation:y", target_rotation_y, 0.8)
