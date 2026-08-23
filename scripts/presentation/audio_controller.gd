class_name AudioController
extends Node

var _sfx_movement: AudioStream
var _sfx_capture: AudioStream
var _sfx_graveyard: AudioStream

func _ready() -> void:
	_sfx_movement = _safe_load("res://assets/audio/movement.wav")
	_sfx_capture = _safe_load("res://assets/audio/capture_impact.wav")
	_sfx_graveyard = _safe_load("res://assets/audio/graveyard_tumble.wav")

func _safe_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	push_warning("Audio file not found or not imported yet: ", path)
	return null

func play_movement(pos: Vector3) -> void:
	_play_3d(_sfx_movement, pos, "Movement", 8.0) # Boosted volume

func play_capture_impact(pos: Vector3) -> void:
	_play_3d(_sfx_capture, pos, "Capture Impact")

func play_graveyard_tumble(pos: Vector3) -> void:
	_play_3d(_sfx_graveyard, pos, "Graveyard Tumble")

func _play_3d(stream: AudioStream, pos: Vector3, event_name: String, volume_db: float = 0.0) -> void:
	if stream == null:
		print("[AudioController] Missing stream for event: ", event_name, " at ", pos)
		return
		
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.position = pos
	player.autoplay = true
	
	# AAA audio design: slight pitch randomization prevents ear fatigue
	player.pitch_scale = randf_range(0.85, 1.1)
	
	# Add some spatial tuning so it sounds good
	player.max_distance = 50.0
	player.unit_size = 5.0
	player.bus = "Master"
	
	add_child(player)
	
	player.finished.connect(func():
		player.queue_free()
	)
