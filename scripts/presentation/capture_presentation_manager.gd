class_name CapturePresentationManager
extends Node

signal capture_presentation_finished

var _is_busy: bool = false

# Starts the choreography for a capture.
# When finished, emits capture_presentation_finished.
func play_capture_sequence(attacker: PieceController, defender: PieceController, move: ChessMove, square_size: float, graveyard_target: Vector3, vfx: VFXController = null, audio: AudioController = null) -> void:
	if _is_busy:
		push_warning("CapturePresentationManager is already busy.")
		return
		
	_is_busy = true
	
	# Determine logical target world position (destination square)
	var target_world = Vector3(move.to_position.x * square_size, 0, move.to_position.y * square_size)
	
	# Calculate directional approach offset (slightly in front of the defender)
	var attack_dir = (target_world - attacker.position).normalized()
	# Stop 0.8 units before the center of the defender's square
	var approach_pos = target_world - (attack_dir * 0.8)
	
	var t = get_tree().create_tween()
	
	# Phase A: Approach (0.25s)
	t.tween_property(attacker, "position", approach_pos, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Phase B: Anticipation (0.15s)
	# Tilt backward slightly (Deferred for now, we just tween position up slightly for wind-up)
	
	# We can tween the mesh's basis/rotation, but for simplicity we'll just tween position up slightly for wind-up
	t.tween_property(attacker, "position:y", 0.5, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Phase C: Strike (0.1s)
	t.tween_property(attacker, "position", target_world, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Phase D: Impact
	t.tween_callback(func():
		attacker.trigger_impact_shake()
		defender.animate_capture(graveyard_target)
		
		if vfx:
			vfx.play_impact_vfx(target_world + Vector3(0, 1.0, 0)) # Slight elevation for impact burst
		if audio:
			audio.play_capture_impact(target_world)
			audio.play_graveyard_tumble(graveyard_target)
	)
	
	# Phase F: Settle (0.2s delay for visual breathing room)
	t.tween_interval(0.2)
	
	t.tween_callback(func():
		attacker.reset_visual_transform()
		_is_busy = false
		capture_presentation_finished.emit()
	)
