extends Control

@onready var title = $CenterContainer/VBoxContainer/Title
@onready var buttons_container = $CenterContainer/VBoxContainer/ButtonsContainer
@onready var play_button = $CenterContainer/VBoxContainer/ButtonsContainer/PlayButton
@onready var settings_button = $CenterContainer/VBoxContainer/ButtonsContainer/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/ButtonsContainer/QuitButton

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

var _buttons: Array[Button] = []

func _ready() -> void:
	# Hide (debug) from window title if it was present
	DisplayServer.window_set_title("Thronebound Chess")
	
	_buttons = [play_button, settings_button, quit_button]
	
	for btn in _buttons:
		btn.pressed.connect(_on_button_pressed.bind(btn))
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.button_down.connect(_on_button_down.bind(btn))
		btn.button_up.connect(_on_button_up.bind(btn))
		
		# Set initial pivot for scaling to center
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		# Initially transparent for animation
		btn.modulate.a = 0.0
	
	title.modulate.a = 0.0
	
	_play_intro_animation()

func _play_intro_animation() -> void:
	var tween = create_tween().set_parallel(false)
	
	# Fade in title slowly
	tween.tween_property(title, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Slight pause
	tween.tween_interval(0.3)
	
	# Fade in buttons sequentially
	var parallel_tween = create_tween().set_parallel(true)
	var delay = 0.0
	for btn in _buttons:
		parallel_tween.tween_property(btn, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)
		delay += 0.2
		
	tween.chain().tween_callback(func(): play_button.grab_focus())

func _on_button_hover(btn: Button) -> void:
	audio_hover.play()
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_unhover(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_down(btn: Button) -> void:
	audio_click.play()
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_SINE)
	
func _on_button_up(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_pressed(btn: Button) -> void:
	# Add a tiny delay to hear the click sound and see animation
	await get_tree().create_timer(0.2).timeout
	
	if btn == play_button:
		SceneTransition.change_scene("res://scenes/ui/game_setup.tscn")
	elif btn == settings_button:
		SceneTransition.change_scene("res://scenes/ui/settings_menu.tscn")
	elif btn == quit_button:
		get_tree().quit()
