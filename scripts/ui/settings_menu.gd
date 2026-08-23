extends Control

@onready var panel = $PanelContainer
@onready var master_slider = %MasterSlider
@onready var music_slider = %MusicSlider
@onready var back_button = %BackBtn

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

func _ready() -> void:
	var diamond_tex = load("res://assets/textures/ui/diamond_grabber.png")
	master_slider.add_theme_icon_override("grabber", diamond_tex)
	master_slider.add_theme_icon_override("grabber_highlight", diamond_tex)
	music_slider.add_theme_icon_override("grabber", diamond_tex)
	music_slider.add_theme_icon_override("grabber_highlight", diamond_tex)

	back_button.pressed.connect(_on_back_pressed)
	
	var interactables = [master_slider, music_slider, back_button, %WinOption, %VsyncCheck]
	_hook_audio(interactables)
	
	_play_intro()

func _hook_audio(nodes: Array) -> void:
	for node in nodes:
		if node is BaseButton:
			node.mouse_entered.connect(func(): audio_hover.play())
			node.pressed.connect(func(): audio_click.play())
		elif node is Slider:
			node.mouse_entered.connect(func(): audio_hover.play())
			node.drag_started.connect(func(): audio_click.play())

func _play_intro() -> void:
	modulate.a = 0.0
	panel.position.y += 60
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(panel, "position:y", panel.position.y - 60, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_back_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
