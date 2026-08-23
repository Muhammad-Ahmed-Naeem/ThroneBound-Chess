extends Control

@onready var panel = $PanelContainer
@onready var master_slider = %MasterSlider
@onready var music_slider = %MusicSlider
@onready var master_percent = %MasterPercent
@onready var music_percent = %MusicPercent
@onready var back_button = %BackBtn

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

func _ready() -> void:
	var lion_tex = load("res://assets/textures/ui/lion_grabber.png")
	master_slider.add_theme_icon_override("grabber", lion_tex)
	master_slider.add_theme_icon_override("grabber_highlight", lion_tex)
	music_slider.add_theme_icon_override("grabber", lion_tex)
	music_slider.add_theme_icon_override("grabber_highlight", lion_tex)
	
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	
	_on_master_changed(master_slider.value)
	_on_music_changed(music_slider.value)

	back_button.pressed.connect(_on_back_pressed)
	
	var interactables = [master_slider, music_slider, back_button, %WinBtn, %FullBtn, %BordBtn, %VsyncSwitch]
	_hook_audio(interactables)
	
	_play_intro()

func _on_master_changed(val: float) -> void:
	master_percent.text = str(round(val * 100)) + "%"

func _on_music_changed(val: float) -> void:
	music_percent.text = str(round(val * 100)) + "%"

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
