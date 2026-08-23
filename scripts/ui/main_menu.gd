extends Control

@onready var background = $Background
@onready var play_btn = $Background/Hotspots/PlayBtn
@onready var settings_btn = $Background/Hotspots/SettingsBtn
@onready var quit_btn = $Background/Hotspots/QuitBtn

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

var _buttons: Array[Button] = []

func _ready() -> void:
	DisplayServer.window_set_title("Thronebound Chess")
	
	_buttons = [play_btn, settings_btn, quit_btn]
	
	for btn in _buttons:
		btn.pressed.connect(_on_button_pressed.bind(btn))
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.button_down.connect(_on_button_down.bind(btn))
		
		# Ensure glow is invisible initially
		var glow = btn.get_node("Glow")
		glow.modulate.a = 0.0
	
	# Start with background completely dark, then fade in
	background.modulate = Color(0, 0, 0, 1)
	_play_intro_animation()

func _play_intro_animation() -> void:
	var tween = create_tween()
	tween.tween_property(background, "modulate", Color(1, 1, 1, 1), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_button_hover(btn: Button) -> void:
	audio_hover.play()
	var glow = btn.get_node("Glow")
	var tween = create_tween()
	tween.tween_property(glow, "modulate:a", 0.6, 0.2).set_trans(Tween.TRANS_SINE)

func _on_button_unhover(btn: Button) -> void:
	var glow = btn.get_node("Glow")
	var tween = create_tween()
	tween.tween_property(glow, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)

func _on_button_down(btn: Button) -> void:
	audio_click.play()
	var glow = btn.get_node("Glow")
	var tween = create_tween()
	# Pulse brighter on click
	tween.tween_property(glow, "modulate:a", 1.0, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.6, 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_pressed(btn: Button) -> void:
	# Small delay to allow the pulse animation and sound to register
	await get_tree().create_timer(0.15).timeout
	
	if btn == play_btn:
		SceneTransition.change_scene("res://scenes/ui/game_setup.tscn")
	elif btn == settings_btn:
		SceneTransition.change_scene("res://scenes/ui/settings_menu.tscn")
	elif btn == quit_btn:
		get_tree().quit()
