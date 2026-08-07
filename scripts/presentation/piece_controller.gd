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

func update_visuals(square_size: float) -> void:
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

func animate_capture() -> Tween:
	var t = get_tree().create_tween()
	t.tween_property(_mesh_instance, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		capture_completed.emit()
		queue_free()
	)
	return t

func _update_mesh() -> void:
	_last_known_type = logical_piece.type
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0) if logical_piece.color == ChessTypes.PieceColor.WHITE else Color(0.1, 0.1, 0.1)
	
	_mesh_instance.material_override = mat
	
	match logical_piece.type:
		ChessTypes.PieceType.PAWN:
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.3
			mesh.bottom_radius = 0.4
			mesh.height = 1.0
			_mesh_instance.mesh = mesh
			_base_y = 0.5
		ChessTypes.PieceType.KNIGHT:
			var mesh = BoxMesh.new()
			mesh.size = Vector3(0.7, 1.2, 0.7)
			_mesh_instance.mesh = mesh
			_base_y = 0.6
		ChessTypes.PieceType.BISHOP:
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.1
			mesh.bottom_radius = 0.4
			mesh.height = 1.5
			_mesh_instance.mesh = mesh
			_base_y = 0.75
		ChessTypes.PieceType.ROOK:
			var mesh = BoxMesh.new()
			mesh.size = Vector3(0.8, 1.0, 0.8)
			_mesh_instance.mesh = mesh
			_base_y = 0.5
		ChessTypes.PieceType.QUEEN:
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.4
			mesh.bottom_radius = 0.5
			mesh.height = 1.8
			_mesh_instance.mesh = mesh
			_base_y = 0.9
		ChessTypes.PieceType.KING:
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.5
			mesh.bottom_radius = 0.6
			mesh.height = 2.0
			_mesh_instance.mesh = mesh
			_base_y = 1.0
			
	if not _is_selected:
		_mesh_instance.position.y = _base_y
