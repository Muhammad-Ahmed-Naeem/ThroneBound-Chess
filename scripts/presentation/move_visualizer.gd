class_name MoveVisualizer
extends Node3D

var _highlights: Array[Node3D] = []
var _last_move_highlights: Array[Node3D] = []

func show_legal_moves(moves: Array[ChessMove], square_size: float) -> void:
	clear_visuals()
	
	for move in moves:
		var highlight = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(square_size * 0.9, square_size * 0.9)
		highlight.mesh = plane
		
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		if move.is_capture():
			mat.albedo_color = Color(1.0, 0.2, 0.2, 0.6) # Red for capture
		else:
			mat.albedo_color = Color(0.2, 1.0, 0.2, 0.6) # Green for normal
			
		highlight.material_override = mat
		
		# Slightly elevated to avoid Z-fighting
		highlight.position = Vector3(move.to_position.x * square_size, 0.1, move.to_position.y * square_size)
		
		add_child(highlight)
		_highlights.append(highlight)

func clear_visuals() -> void:
	for h in _highlights:
		h.queue_free()
	_highlights.clear()

func show_last_move(move: ChessMove, square_size: float) -> void:
	for h in _last_move_highlights:
		h.queue_free()
	_last_move_highlights.clear()
	
	for pos in [move.from_position, move.to_position]:
		var highlight = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(square_size, square_size)
		highlight.mesh = plane
		
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1.0, 1.0, 0.2, 0.3) # Subtle yellow
		highlight.material_override = mat
		highlight.position = Vector3(pos.x * square_size, 0.05, pos.y * square_size)
		
		add_child(highlight)
		_last_move_highlights.append(highlight)
