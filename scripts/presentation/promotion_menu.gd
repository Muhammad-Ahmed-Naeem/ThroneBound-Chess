class_name PromotionMenu
extends CanvasLayer

signal piece_selected(piece_type: int)

func _ready() -> void:
	layer = 100 # Ensure it appears on top of everything
	
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Dark semi-transparent background overlay
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	control.add_child(bg)
	
	# Center panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	control.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var label = Label.new()
	label.text = "Choose Promotion Piece"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Use a built-in theme override to make it slightly larger if desired, 
	# but default is fine for a procedural placeholder
	vbox.add_child(label)
	
	# Add the standard promotion options
	_add_button(vbox, "Queen", ChessTypes.PieceType.QUEEN)
	_add_button(vbox, "Rook", ChessTypes.PieceType.ROOK)
	_add_button(vbox, "Bishop", ChessTypes.PieceType.BISHOP)
	_add_button(vbox, "Knight", ChessTypes.PieceType.KNIGHT)

func _add_button(parent: Node, text: String, type: int) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 50)
	btn.pressed.connect(func():
		piece_selected.emit(type)
		queue_free()
	)
	parent.add_child(btn)
