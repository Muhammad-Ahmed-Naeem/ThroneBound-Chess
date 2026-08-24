extends Control

const PIECE_VALUES = {
	ChessTypes.PieceType.PAWN: 1,
	ChessTypes.PieceType.KNIGHT: 3,
	ChessTypes.PieceType.BISHOP: 3,
	ChessTypes.PieceType.ROOK: 5,
	ChessTypes.PieceType.QUEEN: 9,
	ChessTypes.PieceType.KING: 0
}

const PIECE_NAMES = {
	ChessTypes.PieceType.PAWN: "Pawn",
	ChessTypes.PieceType.KNIGHT: "Knight",
	ChessTypes.PieceType.BISHOP: "Bishop",
	ChessTypes.PieceType.ROOK: "Rook",
	ChessTypes.PieceType.QUEEN: "Queen",
	ChessTypes.PieceType.KING: "King"
}

const PIECE_ICON_PATHS = {
	ChessTypes.PieceType.PAWN: "res://assets/ui/pawn_icon.svg",
	ChessTypes.PieceType.KNIGHT: "res://assets/ui/knight_icon.svg",
	ChessTypes.PieceType.BISHOP: "res://assets/ui/bishop_icon.svg",
	ChessTypes.PieceType.ROOK: "res://assets/ui/rook_icon.svg",
	ChessTypes.PieceType.QUEEN: "res://assets/ui/queen_icon.svg"
}

const PIECE_ORDER = [
	ChessTypes.PieceType.PAWN,
	ChessTypes.PieceType.KNIGHT,
	ChessTypes.PieceType.BISHOP,
	ChessTypes.PieceType.ROOK,
	ChessTypes.PieceType.QUEEN
]

@onready var turn_label = $TopMarginContainer/VBoxContainer/TurnLabel
@onready var check_label = $TopMarginContainer/VBoxContainer/CheckLabel

@onready var white_icons_container = %WhiteIconsHBox
@onready var white_advantage_label = %WhiteAdvantageLabel

@onready var black_icons_container = %BlackIconsHBox
@onready var black_advantage_label = %BlackAdvantageLabel

# Dictionary: PieceType -> count
var _captured_by_white: Dictionary = {}
var _captured_by_black: Dictionary = {}

var _piece_textures: Dictionary = {}

func _ready() -> void:
	_get_nodes()
	_preload_textures()
	reset_hud()

func _get_nodes() -> void:
	if white_icons_container == null and has_node("%WhiteIconsHBox"):
		white_icons_container = get_node("%WhiteIconsHBox")
	if white_advantage_label == null and has_node("%WhiteAdvantageLabel"):
		white_advantage_label = get_node("%WhiteAdvantageLabel")
	if black_icons_container == null and has_node("%BlackIconsHBox"):
		black_icons_container = get_node("%BlackIconsHBox")
	if black_advantage_label == null and has_node("%BlackAdvantageLabel"):
		black_advantage_label = get_node("%BlackAdvantageLabel")

func _preload_textures() -> void:
	for p_type in PIECE_ICON_PATHS:
		var path = PIECE_ICON_PATHS[p_type]
		if ResourceLoader.exists(path):
			_piece_textures[p_type] = load(path)

func update_hud(current_turn: int, is_in_check: bool) -> void:
	_get_nodes()
	if turn_label:
		if current_turn == ChessTypes.PieceColor.WHITE:
			turn_label.text = "WHITE TO MOVE"
		else:
			turn_label.text = "BLACK TO MOVE"
	
	if check_label:
		check_label.visible = is_in_check

func reset_hud() -> void:
	_get_nodes()
	_captured_by_white.clear()
	_captured_by_black.clear()
	
	if is_instance_valid(white_icons_container):
		for child in white_icons_container.get_children():
			child.queue_free()
			
	if is_instance_valid(black_icons_container):
		for child in black_icons_container.get_children():
			child.queue_free()
			
	if is_instance_valid(white_advantage_label):
		white_advantage_label.visible = false
		
	if is_instance_valid(black_advantage_label):
		black_advantage_label.visible = false

# Authoritative capture handler called when a piece is captured
func record_capture(captured_piece: ChessPiece, capturing_color: int) -> void:
	_get_nodes()
	if captured_piece == null or captured_piece.type == ChessTypes.PieceType.KING:
		return
		
	var target_dict = _captured_by_white if capturing_color == ChessTypes.PieceColor.WHITE else _captured_by_black
	var piece_type = captured_piece.type
	
	var is_new_entry = not target_dict.has(piece_type) or target_dict[piece_type] == 0
	target_dict[piece_type] = target_dict.get(piece_type, 0) + 1
	
	_render_trophies(capturing_color, piece_type, is_new_entry)
	_update_material_advantage()

func _render_trophies(capturing_color: int, just_updated_type: int, is_new_entry: bool) -> void:
	_get_nodes()
	var container = white_icons_container if capturing_color == ChessTypes.PieceColor.WHITE else black_icons_container
	var dict = _captured_by_white if capturing_color == ChessTypes.PieceColor.WHITE else _captured_by_black
	var piece_modulate = Color(0.25, 0.25, 0.3, 0.95) if capturing_color == ChessTypes.PieceColor.WHITE else Color(0.95, 0.95, 0.9, 0.95)
	
	if not is_instance_valid(container): return
	
	# Find or create entry for each piece type in canonical order
	for p_type in PIECE_ORDER:
		if dict.has(p_type) and dict[p_type] > 0:
			var count = dict[p_type]
			var node_name = "Trophy_" + str(p_type)
			var entry: Control = container.get_node_or_null(node_name) as Control
			
			if entry == null:
				entry = _create_trophy_entry(node_name, p_type, piece_modulate)
				container.add_child(entry)
				
				# Enforce order in container
				var target_index = 0
				for check_type in PIECE_ORDER:
					if check_type == p_type: break
					if dict.has(check_type) and dict[check_type] > 0:
						target_index += 1
				container.move_child(entry, target_index)
				
			_update_trophy_entry_count(entry, count, p_type)
			
			# Animate entrance / count update
			if p_type == just_updated_type:
				_animate_trophy_entry(entry, is_new_entry)

func _create_trophy_entry(node_name: String, piece_type: int, modulate_color: Color) -> Control:
	var hbox = HBoxContainer.new()
	hbox.name = node_name
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 2)
	
	var font_res = load("res://assets/fonts/Cinzel.ttf")
	
	var tex_rect = TextureRect.new()
	tex_rect.name = "Icon"
	tex_rect.custom_minimum_size = Vector2(26, 26)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.modulate = modulate_color
	
	if _piece_textures.has(piece_type):
		tex_rect.texture = _piece_textures[piece_type]
		
	hbox.add_child(tex_rect)
	
	var count_lbl = Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	count_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	count_lbl.add_theme_constant_override("outline_size", 2)
	if font_res:
		count_lbl.add_theme_font_override("font", font_res)
	count_lbl.add_theme_font_size_override("font_size", 14)
	count_lbl.visible = false
	hbox.add_child(count_lbl)
	
	# Tooltip
	var p_name = PIECE_NAMES.get(piece_type, "Piece")
	var val = PIECE_VALUES.get(piece_type, 0)
	hbox.tooltip_text = "%s (Value: %d)" % [p_name, val]
	
	return hbox

func _update_trophy_entry_count(entry: Control, count: int, piece_type: int) -> void:
	var count_lbl = entry.get_node_or_null("CountLabel") as Label
	if count_lbl:
		if count > 1:
			count_lbl.text = "×" + str(count)
			count_lbl.visible = true
		else:
			count_lbl.visible = false
			
	var p_name = PIECE_NAMES.get(piece_type, "Piece")
	var val = PIECE_VALUES.get(piece_type, 0)
	entry.tooltip_text = "%s ×%d (Value: %d)" % [p_name, count, val * count]

func _animate_trophy_entry(entry: Control, is_new: bool) -> void:
	entry.pivot_offset = entry.size / 2.0
	
	var t = create_tween()
	if is_new:
		entry.scale = Vector2(0.3, 0.3)
		entry.modulate.a = 0.0
		t.tween_property(entry, "modulate:a", 1.0, 0.2)
		t.parallel().tween_property(entry, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(entry, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		entry.scale = Vector2(1.0, 1.0)
		t.tween_property(entry, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(entry, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _update_material_advantage() -> void:
	_get_nodes()
	var white_score: int = 0
	for p_type in _captured_by_white:
		white_score += PIECE_VALUES.get(p_type, 0) * _captured_by_white[p_type]
		
	var black_score: int = 0
	for p_type in _captured_by_black:
		black_score += PIECE_VALUES.get(p_type, 0) * _captured_by_black[p_type]
		
	var diff = white_score - black_score
	
	if diff > 0:
		if is_instance_valid(white_advantage_label):
			white_advantage_label.text = "+" + str(diff)
			white_advantage_label.visible = true
		if is_instance_valid(black_advantage_label):
			black_advantage_label.visible = false
	elif diff < 0:
		if is_instance_valid(black_advantage_label):
			black_advantage_label.text = "+" + str(-diff)
			black_advantage_label.visible = true
		if is_instance_valid(white_advantage_label):
			white_advantage_label.visible = false
	else:
		if is_instance_valid(white_advantage_label):
			white_advantage_label.visible = false
		if is_instance_valid(black_advantage_label):
			black_advantage_label.visible = false
