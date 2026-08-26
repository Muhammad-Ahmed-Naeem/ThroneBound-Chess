extends Control

@onready var panel = $PanelContainer
@onready var local_btn = %LocalBtn
@onready var ai_btn = %AiBtn
@onready var ai_options = %AiOptions
@onready var color_options = %ColorOptions
@onready var diff_options = %DiffOptions
@onready var back_btn = %BackBtn
@onready var start_btn = %StartBtn

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

var _config = GameConfiguration.new()

var style_normal: StyleBox
var style_active: StyleBox
var style_hover_normal: StyleBox
var style_hover_active: StyleBox

var color_dark = Color(0.05, 0.02, 0.01, 1)
var color_light = Color(0.95, 0.9, 0.8, 1)

func _ready() -> void:
	style_normal = ai_btn.get_theme_stylebox("normal")
	style_hover_normal = ai_btn.get_theme_stylebox("hover")
	style_active = local_btn.get_theme_stylebox("normal")
	style_hover_active = local_btn.get_theme_stylebox("hover")
	
	local_btn.pressed.connect(_on_local_pressed)
	ai_btn.pressed.connect(_on_ai_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	
	color_options.add_item("Play as White", GameConfiguration.PlayerColor.WHITE)
	color_options.add_item("Play as Black", GameConfiguration.PlayerColor.BLACK)
	
	diff_options.add_item("Easy", GameConfiguration.AIDifficulty.EASY)
	diff_options.add_item("Medium", GameConfiguration.AIDifficulty.MEDIUM)
	diff_options.add_item("Hard", GameConfiguration.AIDifficulty.HARD)
	diff_options.select(1) # Medium
	
	_hook_audio([local_btn, ai_btn, back_btn, start_btn, color_options, diff_options])
	
	_play_intro()

func _hook_audio(nodes: Array) -> void:
	for node in nodes:
		if node is BaseButton:
			node.mouse_entered.connect(func(): audio_hover.play())
			node.pressed.connect(func(): audio_click.play())

func _play_intro() -> void:
	modulate.a = 0.0
	panel.position.y += 60
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(panel, "position:y", panel.position.y - 60, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_button_active(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", style_active)
		btn.add_theme_stylebox_override("hover", style_hover_active)
		btn.add_theme_stylebox_override("pressed", style_active)
		btn.add_theme_stylebox_override("focus", style_hover_active)
		btn.add_theme_color_override("font_color", color_light)
		btn.add_theme_color_override("font_hover_color", color_light)
		btn.add_theme_color_override("font_pressed_color", color_light)
		btn.add_theme_color_override("font_focus_color", color_light)
	else:
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover_normal)
		btn.add_theme_stylebox_override("pressed", style_hover_normal)
		btn.add_theme_stylebox_override("focus", style_hover_normal)
		btn.add_theme_color_override("font_color", color_dark)
		btn.add_theme_color_override("font_hover_color", color_dark)
		btn.add_theme_color_override("font_pressed_color", color_dark)
		btn.add_theme_color_override("font_focus_color", color_dark)

func _on_local_pressed() -> void:
	_config.game_mode = GameConfiguration.GameMode.LOCAL_2_PLAYER
	ai_options.visible = false
	_set_button_active(local_btn, true)
	_set_button_active(ai_btn, false)

func _on_ai_pressed() -> void:
	_config.game_mode = GameConfiguration.GameMode.VS_AI
	ai_options.visible = true
	_set_button_active(ai_btn, true)
	_set_button_active(local_btn, false)

func _on_back_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _on_start_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	if _config.game_mode == GameConfiguration.GameMode.VS_AI:
		_config.player_color = color_options.get_selected_id()
		_config.ai_difficulty = diff_options.get_selected_id()
	SceneTransition.start_match(_config)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
