class_name AudioController
extends Node

func play_movement(pos: Vector3) -> void:
	_play_3d(null, pos, "Movement")

func play_capture_impact(pos: Vector3) -> void:
	_play_3d(null, pos, "Capture Impact")

func play_graveyard_tumble(pos: Vector3) -> void:
	_play_3d(null, pos, "Graveyard Tumble")

func _play_3d(stream: AudioStream, pos: Vector3, event_name: String) -> void:
	if stream == null:
		# Acceptable debug message as per requirements for missing local audio
		# print("[AudioController] Triggered event: ", event_name, " at ", pos)
		return
		
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.position = pos
	player.autoplay = true
	add_child(player)
	
	player.finished.connect(func():
		player.queue_free()
	)
