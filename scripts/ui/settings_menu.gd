extends Control

@onready var back_button = $CenterContainer/VBoxContainer/MarginContainer/BackButton
@onready var master_slider = $CenterContainer/VBoxContainer/GridContainer/MasterSlider
@onready var music_slider = $CenterContainer/VBoxContainer/GridContainer/MusicSlider
@onready var sfx_slider = $CenterContainer/VBoxContainer/GridContainer/SfxSlider
@onready var window_option = $CenterContainer/VBoxContainer/GridContainer/WindowOption

const CONFIG_PATH = "user://settings.cfg"
var config = ConfigFile.new()

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	master_slider.value_changed.connect(func(value): _on_volume_changed("Master", value))
	music_slider.value_changed.connect(func(value): _on_volume_changed("Music", value))
	sfx_slider.value_changed.connect(func(value): _on_volume_changed("SFX", value))
	
	window_option.item_selected.connect(_on_window_mode_selected)
	
	_load_settings()
	back_button.grab_focus()

func _load_settings() -> void:
	if config.load(CONFIG_PATH) != OK:
		config.set_value("audio", "Master", 0.8)
		config.set_value("audio", "Music", 0.8)
		config.set_value("audio", "SFX", 0.8)
		config.set_value("display", "window_mode", 0)
		config.save(CONFIG_PATH)
		
	var master_vol = config.get_value("audio", "Master", 0.8)
	var music_vol = config.get_value("audio", "Music", 0.8)
	var sfx_vol = config.get_value("audio", "SFX", 0.8)
	var window_mode = config.get_value("display", "window_mode", 0)
	
	master_slider.value = master_vol
	music_slider.value = music_vol
	sfx_slider.value = sfx_vol
	window_option.select(window_mode)
	
	_apply_volume("Master", master_vol)
	_apply_volume("Music", music_vol)
	_apply_volume("SFX", sfx_vol)
	_apply_window_mode(window_mode)

func _save_settings() -> void:
	config.save(CONFIG_PATH)

func _on_volume_changed(bus_name: String, value: float) -> void:
	_apply_volume(bus_name, value)
	config.set_value("audio", bus_name, value)
	_save_settings()

func _apply_volume(bus_name: String, value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
		AudioServer.set_bus_mute(bus_idx, value <= 0.01)

func _on_window_mode_selected(index: int) -> void:
	_apply_window_mode(index)
	config.set_value("display", "window_mode", index)
	_save_settings()

func _apply_window_mode(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_back_pressed() -> void:
	if get_parent() == get_tree().root:
		SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
	else:
		queue_free()
