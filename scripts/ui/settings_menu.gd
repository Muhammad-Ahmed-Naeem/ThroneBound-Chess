extends Control

@onready var panel = $PanelContainer
@onready var master_slider = $PanelContainer/Margin/MainVBox/SettingsGrid/MasterSlider
@onready var music_slider = $PanelContainer/Margin/MainVBox/SettingsGrid/MusicSlider
@onready var sfx_slider = $PanelContainer/Margin/MainVBox/SettingsGrid/SfxSlider
@onready var window_option = $PanelContainer/Margin/MainVBox/SettingsGrid/WindowOption
@onready var back_button = $PanelContainer/Margin/MainVBox/BackBtn

@onready var audio_hover = $AudioHover
@onready var audio_click = $AudioClick

func _ready() -> void:
	# IMPORTANT: The default grabber icons have been disabled in the theme overrides via settings_menu.tscn.
	# You need to assign your custom 32x32 pixel `diamond_grabber.png` asset to the 
	# `theme_override_icons/grabber` and `theme_override_icons/grabber_highlight` 
	# properties on the HSlider nodes to complete the custom slider styling.
	
	# Or, since it's already in the assets folder, we can assign it via code here:
	var diamond_tex = load("res://assets/textures/ui/diamond_grabber.png")
	master_slider.add_theme_icon_override("grabber", diamond_tex)
	master_slider.add_theme_icon_override("grabber_highlight", diamond_tex)
	music_slider.add_theme_icon_override("grabber", diamond_tex)
	music_slider.add_theme_icon_override("grabber_highlight", diamond_tex)
	sfx_slider.add_theme_icon_override("grabber", diamond_tex)
	sfx_slider.add_theme_icon_override("grabber_highlight", diamond_tex)

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
