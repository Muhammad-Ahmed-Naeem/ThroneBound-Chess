extends Control

@onready var container = $CenterContainer
@onready var master_slider = $CenterContainer/PanelContainer/Margin/VBox/GridContainer/MasterSlider
@onready var music_slider = $CenterContainer/PanelContainer/Margin/VBox/GridContainer/MusicSlider
@onready var sfx_slider = $CenterContainer/PanelContainer/Margin/VBox/GridContainer/SfxSlider
@onready var window_option = $CenterContainer/PanelContainer/Margin/VBox/GridContainer/WindowOption
@onready var back_button = $CenterContainer/PanelContainer/Margin/VBox/BackBtn

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	_hook_audio([master_slider, music_slider, sfx_slider, window_option, back_button])
	
	_play_intro()

func _hook_audio(nodes: Array) -> void:
	for node in nodes:
		if node is BaseButton:
			node.mouse_entered.connect(func(): audio_hover.play())
			node.pressed.connect(func(): audio_click.play())
		elif node is Slider:
			node.mouse_entered.connect(func(): audio_hover.play())
			# Dragging a slider rapidly can spam audio, so we only play click on drag start if possible.
			# But drag_started is better.
			node.drag_started.connect(func(): audio_click.play())

func _play_intro() -> void:
	modulate.a = 0.0
	container.position.y += 50
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "position:y", container.position.y - 50, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_back_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
