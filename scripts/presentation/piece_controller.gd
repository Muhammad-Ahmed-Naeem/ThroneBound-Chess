class_name PieceController
extends Node3D

signal move_completed
signal capture_completed

var logical_piece: ChessPiece
var _mesh_instance: MeshInstance3D
var _last_known_type: int = -1
var _is_selected: bool = false
var _base_y: float = 0.0

func setup(p: ChessPiece, square_size: float) -> void:
	logical_piece = p
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	
	_update_mesh()
	position = Vector3(logical_piece.position.x * square_size, 0, logical_piece.position.y * square_size)

func update_visuals(_square_size: float) -> void:
	if _last_known_type != logical_piece.type:
		_update_mesh()

func set_selected(selected: bool) -> void:
	if _is_selected == selected: return
	_is_selected = selected
	var t = get_tree().create_tween()
	if _is_selected:
		t.tween_property(_mesh_instance, "position:y", _base_y + 0.5, 0.15)
	else:
		t.tween_property(_mesh_instance, "position:y", _base_y, 0.15)

func move_to(target_pos: Vector2i, square_size: float) -> Tween:
	var target_world = Vector3(target_pos.x * square_size, 0, target_pos.y * square_size)
	var t = get_tree().create_tween()
	t.tween_property(self, "position", target_world, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func(): move_completed.emit())
	return t

# -- Capture Presentation API --

func get_mesh_instance() -> MeshInstance3D:
	return _mesh_instance

func get_base_rotation() -> Vector3:
	var is_white = (logical_piece.color == ChessTypes.PieceColor.WHITE)
	if logical_piece.type == ChessTypes.PieceType.KNIGHT:
		return Vector3(0, PI/2.0 if is_white else -PI/2.0, 0)
	return Vector3.ZERO

func reset_visual_transform() -> void:
	_mesh_instance.rotation = get_base_rotation()
	_mesh_instance.scale = Vector3(_mesh_instance.scale.x, _mesh_instance.scale.y, _mesh_instance.scale.z) # Keep calibrated scale

# --- Milestone 12: Combat Presentation Helpers ---

## World-space center of this piece. Convenience wrapper over global_position.
func get_world_position() -> Vector3:
	return global_position

## Suggested world-space origin for projectile spawning — slightly above piece center.
## Choreographies should use this rather than hardcoding Y offsets.
func get_projectile_origin() -> Vector3:
	return global_position + Vector3(0.0, 1.1, 0.0)

## Instantly rotate mesh to face a world-space direction (Y-axis only).
## Preserves existing X/Z rotation of the mesh (calibrated base offsets).
func face_direction(world_dir: Vector3) -> void:
	world_dir.y = 0.0
	if world_dir.length_squared() < 0.0001:
		return
	_mesh_instance.rotation.y = atan2(world_dir.x, world_dir.z)

func trigger_impact_shake() -> Tween:
	var t = get_tree().create_tween()
	var original_scale = _mesh_instance.scale
	t.tween_property(_mesh_instance, "scale", original_scale * 1.2, 0.05)
	t.tween_property(_mesh_instance, "scale", original_scale, 0.1)
	return t

func animate_capture(target_pos: Vector3) -> Tween:
	var t = get_tree().create_tween()
	t.set_parallel(true)
	
	# Slide to the graveyard X/Z
	t.tween_property(self, "position:x", target_pos.x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:z", target_pos.z, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Hop up in an arc (Y axis)
	t.tween_property(self, "position:y", 3.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.25)
	
	# Tumble wildly
	t.tween_property(_mesh_instance, "rotation", Vector3(PI*2, PI*2, 0), 0.5)
	
	# Finish and reset rotation
	t.chain().tween_callback(func():
		var is_white = (logical_piece.color == ChessTypes.PieceColor.WHITE)
		if logical_piece.type == ChessTypes.PieceType.KNIGHT:
			_mesh_instance.rotation = Vector3(0, PI/2.0 if is_white else -PI/2.0, 0)
		else:
			_mesh_instance.rotation = Vector3.ZERO
		capture_completed.emit()
	)
	
	return t

static var _mesh_cache_white: Dictionary = {}
static var _mesh_cache_black: Dictionary = {}

static func _load_meshes() -> void:
	if not _mesh_cache_white.is_empty(): return
	var scene = preload("res://assets/models/pieces/scene.gltf").instantiate()
	var names = {
		ChessTypes.PieceType.PAWN: "pawn",
		ChessTypes.PieceType.ROOK: "rook",
		ChessTypes.PieceType.KNIGHT: "knight",
		ChessTypes.PieceType.BISHOP: "bishop",
		ChessTypes.PieceType.QUEEN: "queen",
		ChessTypes.PieceType.KING: "king"
	}
	for type in names:
		var w_name = names[type] + "_white_low"
		var b_name = names[type] + "_black"
		
		var w_node = _find_child_recursive(scene, w_name)
		var b_node = _find_child_recursive(scene, b_name)
		
		if w_node: _mesh_cache_white[type] = _get_mesh(w_node)
		if b_node: _mesh_cache_black[type] = _get_mesh(b_node)

static func _find_child_recursive(node: Node, prefix: String) -> Node:
	if node.name.to_lower().begins_with(prefix.to_lower()): return node
	for c in node.get_children():
		var res = _find_child_recursive(c, prefix)
		if res: return res
	return null

static func _get_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D: return node.mesh
	for c in node.get_children():
		if c is MeshInstance3D: return c.mesh
	return null

func _update_mesh() -> void:
	_last_known_type = logical_piece.type
	PieceController._load_meshes()
	
	var is_white = (logical_piece.color == ChessTypes.PieceColor.WHITE)
	var cache = _mesh_cache_white if is_white else _mesh_cache_black
	
	if cache.has(logical_piece.type) and cache[logical_piece.type] != null:
		var mesh = cache[logical_piece.type]
		_mesh_instance.mesh = mesh
		
		var aabb = mesh.get_aabb()
		var piece_width = max(aabb.size.x, aabb.size.z)
		if piece_width > 0.001:
			var scale_factor = 1.1 / piece_width # Calibrated scale
			_mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
			
			var center_x = aabb.position.x + aabb.size.x / 2.0
			var center_z = aabb.position.z + aabb.size.z / 2.0
			_mesh_instance.position.x = -center_x * scale_factor
			_mesh_instance.position.z = -center_z * scale_factor
			_base_y = -aabb.position.y * scale_factor
			
			# Orient Knights to face forward
			if logical_piece.type == ChessTypes.PieceType.KNIGHT:
				# Mesh might be facing X or -X originally. Rotate by 90 degrees to face Z.
				# We'll try 90 degrees for white and -90 for black.
				_mesh_instance.rotation.y = PI/2.0 if is_white else -PI/2.0
			else:
				_mesh_instance.rotation.y = 0.0
		else:
			_mesh_instance.scale = Vector3(1, 1, 1)
			_base_y = 0.0
			
		_mesh_instance.material_override = null
	else:
		print("Failed to find mesh for type: ", logical_piece.type)
		_base_y = 0.0
		
	if not _is_selected:
		_mesh_instance.position.y = _base_y
