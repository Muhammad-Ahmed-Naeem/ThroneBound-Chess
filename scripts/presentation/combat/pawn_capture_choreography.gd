## PawnCaptureChoreography — Grounded infantry spear-thrust attack.
## Identity: Foot soldier. Direct, compact, physical. Communicates "stab" through
## a short backward lean (anticipation) followed by a fast forward lunge.
##
## Total duration: ~0.82 seconds
## Sequence:
##   1. Face defender (instant)
##   2. Backward lean: mesh tilts back slightly (0.09s)
##   3. Lunge approach: pawn moves aggressively toward target (0.22s)
##   4. Thrust snap: short forward pop to contact point (0.09s)
##   5. Impact: physical VFX + spear sound + defender reaction
##   6. Brief hold (0.05s)
##   7. Settle: return to target_world position + reset rotation (0.16s)
##   8. Complete
class_name PawnCaptureChoreography
extends CaptureChoreographyBase

var _profile: CaptureProfile = CaptureProfile.pawn()


func _execute_impl(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	var mesh := attacker.get_mesh_instance()

	# 1. Face target
	_face_target(attacker, ctx.defender_world)

	# Pre-calculate approach stop point (just before defender)
	var approach_stop := ctx.defender_world - ctx.attack_dir * 0.9

	var t := attacker.get_tree().create_tween()

	# 2. Backward lean: slight rotation backward on X axis (communicates "drawing the spear back")
	if is_instance_valid(mesh):
		var lean_rotation := mesh.rotation
		lean_rotation.x = -0.22  # lean back
		t.tween_property(mesh, "rotation:x", -0.22, _profile.anticipation_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Lunge: move toward target aggressively
	t.tween_property(attacker, "position", approach_stop, _profile.approach_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 4. Thrust: forward snap to contact + return lean forward
	t.set_parallel(true)
	t.tween_property(attacker, "position", ctx.defender_world, _profile.attack_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", 0.18, _profile.attack_duration  # lean forward during thrust
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	t.chain()

	# 5. Impact
	t.tween_callback(func():
		attacker.trigger_impact_shake()
		_impact_vfx(ctx, ctx.defender_world)
		_camera_shake(ctx, _profile.camera_shake_strength)

		if ctx.audio != null and ctx.audio.has_method("play_spear_thrust"):
			ctx.audio.play_spear_thrust(ctx.defender_world)
		elif ctx.audio != null:
			ctx.audio.play_capture_impact(ctx.defender_world)

		DefenderReaction.react(
			ctx.defender,
			DefenderReaction.ReactionType.PHYSICAL_MELEE,
			ctx.graveyard_target
		)
		if ctx.audio != null:
			ctx.audio.play_graveyard_tumble(ctx.graveyard_target)
	)

	# 6. Hold briefly
	t.tween_interval(_profile.impact_hold)

	# 7. Settle: glide to proper target position, reset lean
	t.set_parallel(true)
	t.tween_property(attacker, "position", ctx.target_world, _profile.settle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", 0.0, _profile.settle_duration
		).set_trans(Tween.TRANS_SINE)

	t.chain()

	# 8. Complete
	t.tween_callback(func():
		if is_instance_valid(attacker):
			attacker.reset_visual_transform()
		if ctx.on_complete.is_valid():
			ctx.on_complete.call()
	)
