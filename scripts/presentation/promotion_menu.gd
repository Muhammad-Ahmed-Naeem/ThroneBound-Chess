class_name PromotionMenu
extends CanvasLayer

signal piece_selected(piece_type: int)

var _panel: PanelContainer

func _ready() -> void:
	layer = 100 # Ensure it appears on top of everything
	
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Dark semi-transparent background overlay
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	control.add_child(bg)
	
	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	
	# Polished Frosted-Glass StyleBox
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 15
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", style)
	
	control.add_child(_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	_panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Choose Promotion"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Make text slightly more prominent
	label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	# Add horizontal texture buttons
	_add_texture_button(hbox, "queen_icon.svg", ChessTypes.PieceType.QUEEN)
	_add_texture_button(hbox, "rook_icon.svg", ChessTypes.PieceType.ROOK)
	_add_texture_button(hbox, "bishop_icon.svg", ChessTypes.PieceType.BISHOP)
	_add_texture_button(hbox, "knight_icon.svg", ChessTypes.PieceType.KNIGHT)
	
	# Defer the intro animation slightly so Godot calculates layout sizes first
	call_deferred("_play_intro_animation")

func _play_intro_animation() -> void:
	if not is_instance_valid(_panel): return
	
	# Set pivot to center for scaling
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ZERO
	
	# Elastic pop-in tween
	var t = create_tween()
	t.tween_property(_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _add_texture_button(parent: Node, icon_name: String, type: int) -> void:
	var btn = TextureButton.new()
	var path = "res://assets/ui/" + icon_name
	var tex: Texture2D
	
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img: tex = ImageTexture.create_from_image(img)
		
	if tex:
		btn.texture_normal = tex
		btn.ignore_texture_size = true
		btn.custom_minimum_size = Vector2(80, 80)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	parent.add_child(btn)
	
	btn.pressed.connect(func():
		piece_selected.emit(type)
		queue_free()
	)
	
	# Hover Scaling animations
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	
	btn.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
