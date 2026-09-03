## KnightCaptureChoreography — Explosive mounted charge.
## Identity: Mounted warrior. The existing knight is a stylized chess-horse mesh.
## Identity is communicated through explosive arc movement, a rearing back motion,
## a high-speed curved charge, and a heavy landing impact.
##
## Total duration: ~1.1 seconds
## Sequence:
##   1. Face target
##   2. Rear-up: slight vertical rise + backward lean (0.16s) — "horse rears"
##   3. Charge: arc-trajectory toward defender with live directional rotation (0.40s)
##   4. Impact at defender: heavy VFX + dust + sound + defender launch
##   5. Brief hold / overshoot (0.08s)
##   6. Settle onto target_world + reset (0.18s)
##   7. Complete
class_name KnightCaptureChoreography
extends CaptureChoreographyBase

var _profile: CaptureProfile = CaptureProfile.knight()


func _execute_impl(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	var mesh := attacker.get_mesh_instance()

	# 1. Face target
	_face_target(attacker, ctx.defender_world)

	var t := attacker.get_tree().create_tween()

	# 2. Rear-up: rise + lean back (communicates gathering momentum)
	t.set_parallel(true)
	t.tween_property(attacker, "position:y", 0.65, _profile.anticipation_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", -0.30, _profile.anticipation_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	t.chain()

	# 3. Charge: arc trajectory. We use tween_method to do a smooth arc while rotating
	#    to face the direction of travel each step.
	var origin := attacker.position
	var target := ctx.defender_world
	var arc_h := 1.2  # Knight jumps high during the charge arc

	t.tween_method(func(p: float):
		if not is_instance_valid(attacker):
			return
		# Quadratic arc
		var mid := origin.lerp(target, 0.5)
		mid.y += arc_h
		var pos := (1.0 - p) * (1.0 - p) * origin + 2.0 * (1.0 - p) * p * mid + p * p * target
		attacker.position = pos

		# Rotate mesh to face travel direction during charge
		if is_instance_valid(mesh):
			var travel_dir := (target - origin)
			travel_dir.y = 0.0
			if travel_dir.length_squared() > 0.001:
				mesh.rotation.y = atan2(travel_dir.x, travel_dir.z)
			# Lean forward as speed increases, pull back as landing
			var lean := -0.30 * (1.0 - p) + 0.20 * p  # from lean-back to lean-forward
			mesh.rotation.x = lean
	, 0.0, 1.0, _profile.approach_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Audio: horse charge during movement
	t.tween_callback(func():
		if ctx.audio != null and ctx.audio.has_method("play_horse_charge"):
			ctx.audio.play_horse_charge(ctx.defender_world)
	)

	# 4. Impact
	t.tween_callback(func():
		attacker.trigger_impact_shake()
		_impact_vfx(ctx, ctx.defender_world)
		_camera_shake(ctx, _profile.camera_shake_strength)

		if ctx.audio != null:
			ctx.audio.play_capture_impact(ctx.defender_world)

		DefenderReaction.react(
			ctx.defender,
			DefenderReaction.ReactionType.PHYSICAL_MELEE,
			ctx.graveyard_target
		)
		if ctx.audio != null:
			ctx.audio.play_graveyard_tumble(ctx.graveyard_target)
	)

	# 5. Hold (brief — knight "lands" heavily)
	t.tween_interval(_profile.impact_hold)

	# 6. Settle: land firmly on target_world, reset orientation
	t.tween_property(attacker, "position", ctx.target_world, _profile.settle_duration
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# 7. Complete
	t.tween_callback(func():
		if is_instance_valid(attacker):
			attacker.reset_visual_transform()
		if ctx.on_complete.is_valid():
			ctx.on_complete.call()
	)
