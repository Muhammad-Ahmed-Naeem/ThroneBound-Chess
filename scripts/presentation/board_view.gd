class_name BoardView
extends Node3D

const SQUARE_SIZE: float = 2.0

var _game: ChessGame
var _visualizer: MoveVisualizer

var _selected_pos: Vector2i = Vector2i(-1, -1)
var _legal_moves_cache: Array[ChessMove] = []
var _pieces: Dictionary = {} # Maps Vector2i -> PieceController

var _is_animating: bool = false
var _animations_pending: int = 0

func _ready() -> void:
	_game = ChessGame.new()
	_game.move_executed.connect(_on_move_executed)
	_game.start_new_game()
	
	_visualizer = MoveVisualizer.new()
	add_child(_visualizer)
	
	_generate_board()
	_generate_pieces()

func _generate_board() -> void:
	for file in range(8):
		for rank in range(8):
			var mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(SQUARE_SIZE, 0.2, SQUARE_SIZE)
			mesh.mesh = box
			mesh.position = chess_to_world(Vector2i(file, rank))
			mesh.position.y -= 0.1 # flush top to y=0
			
			var mat = StandardMaterial3D.new()
			if (file + rank) % 2 != 0:
				mat.albedo_color = Color(0.8, 0.8, 0.8) # Light
			else:
				mat.albedo_color = Color(0.3, 0.3, 0.3) # Dark
				
			mesh.material_override = mat
			add_child(mesh)

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
	
	var old_pieces = _pieces.values()
	_pieces.clear()
	_animations_pending = 0
	
	for pc in old_pieces:
		if current_logical_pieces.has(pc.logical_piece):
			var new_world = chess_to_world(pc.logical_piece.position)
			# We check flat distance to avoid float precision issues with Y offsets
			var flat_old = Vector2(pc.position.x, pc.position.z)
			var flat_new = Vector2(new_world.x, new_world.z)
			if flat_old.distance_to(flat_new) > 0.1:
				_animations_pending += 1
				pc.move_completed.connect(_on_piece_animation_done, CONNECT_ONE_SHOT)
				pc.move_to(pc.logical_piece.position, SQUARE_SIZE)
			else:
				pc.update_visuals(SQUARE_SIZE)
				
			_pieces[pc.logical_piece.position] = pc
		else:
			_animations_pending += 1
			pc.capture_completed.connect(_on_piece_animation_done, CONNECT_ONE_SHOT)
			pc.animate_capture()
			
	if _animations_pending == 0:
		_on_piece_animation_done()

func _on_piece_animation_done() -> void:
	if _animations_pending > 0:
		_animations_pending -= 1
	if _animations_pending == 0:
		_is_animating = false
		if _game.is_game_over():
			print("Game Over! Result: ", _game.get_game_result())

func _unhandled_input(event: InputEvent) -> void:
	if _is_animating: return
	
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
			# For prototype, default promotion to QUEEN
			var prom = ChessTypes.PieceType.QUEEN if target_move.move_type == ChessMove.MoveType.PROMOTION else -1
			var res = _game.try_move(_selected_pos, pos, prom)
			if res == ChessTypes.MoveResult.SUCCESS:
				return # _on_move_executed handles visual sync
				
		_clear_selection()
	
	# Select our own piece
	var clicked_piece = _game.get_board().get_piece(pos)
	if clicked_piece != null and clicked_piece.color == _game.get_current_turn():
		_selected_pos = pos
		if _pieces.has(pos):
			_pieces[pos].set_selected(true)
		_legal_moves_cache = _game.get_legal_moves_for_square(pos)
		_visualizer.show_legal_moves(_legal_moves_cache, SQUARE_SIZE)

func _clear_selection() -> void:
	if _selected_pos != Vector2i(-1, -1) and _pieces.has(_selected_pos):
		_pieces[_selected_pos].set_selected(false)
		
	_selected_pos = Vector2i(-1, -1)
	_legal_moves_cache.clear()
	_visualizer.clear_visuals()

# Coordinate Helpers
func chess_to_world(pos: Vector2i) -> Vector3:
	return Vector3(pos.x * SQUARE_SIZE, 0, pos.y * SQUARE_SIZE)

func world_to_chess(pos: Vector3) -> Vector2i:
	var x = round(pos.x / SQUARE_SIZE)
	var z = round(pos.z / SQUARE_SIZE)
	return Vector2i(x, z)
