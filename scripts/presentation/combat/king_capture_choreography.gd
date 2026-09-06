## KingCaptureChoreography — Heavy, deliberate, dignified sword strike.
## Identity: Emperor. Weight, authority, restraint.
## The King moves more slowly than every other melee piece, strikes once with
## absolute conviction, holds the moment, then settles with gravitas.
## Should feel measurably heavier and more deliberate than the Queen.
##
## Total duration: ~1.15 seconds
## Sequence:
##   1. Face target
##   2. Deliberate approach (0.28s, slower EASE_IN_OUT — heavier gait)
##   3. Heavy anticipation: rise + strong backward lean (0.14s)
##   4. Single powerful downward strike to target (0.13s)
##   5. Impact: strong VFX + heavy sound + defender reaction
##   6. HOLD POSE (0.14s) — the King "owns the moment"
##   7. Dignified settle to target_world center (0.24s, slow ease)
##   8. Complete
class_name KingCaptureChoreography
extends CaptureChoreographyBase

var _profile: CaptureProfile = CaptureProfile.king()


func _execute_impl(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	var mesh := attacker.get_mesh_instance()

	# 1. Face target
	_face_target(attacker, ctx.defender_world)

	# Approach stop: slightly further back than other melee pieces (king is restrained)
	var approach_stop := ctx.defender_world - ctx.attack_dir * 1.0

	var t := attacker.get_tree().create_tween()

	# 2. Deliberate approach — heavier, EASE_IN_OUT gives weight
	t.tween_property(attacker, "position", approach_stop, _profile.approach_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3. Heavy anticipation: rise upward + strong backward lean
	t.set_parallel(true)
	t.tween_property(attacker, "position:y", 0.70, _profile.anticipation_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", -0.38, _profile.anticipation_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	t.chain()

	# 4. Single powerful downward strike — attacker slams to target
	t.set_parallel(true)
	t.tween_property(attacker, "position", ctx.defender_world, _profile.attack_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.tween_property(attacker, "position:y", 0.0, _profile.attack_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	if is_instance_valid(mesh):
		# Forward slam rotation — heavy downward arc
		t.tween_property(mesh, "rotation:x", 0.32, _profile.attack_duration
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	t.chain()

	# 5. Impact — strong hit
	t.tween_callback(func():
		attacker.trigger_impact_shake()
		_impact_vfx(ctx, ctx.defender_world)
		_camera_shake(ctx, _profile.camera_shake_strength)

		if ctx.audio != null and ctx.audio.has_method("play_sword_swing"):
			ctx.audio.play_sword_swing(ctx.defender_world)
		if ctx.audio != null and ctx.audio.has_method("play_sword_impact"):
			ctx.audio.play_sword_impact(ctx.defender_world)
		elif ctx.audio != null:
			ctx.audio.play_capture_impact(ctx.defender_world)

		if ctx.audio != null:
			ctx.audio.play_defeat_clash(ctx.defender_world)
		DefenderReaction.react(
			ctx.defender,
			DefenderReaction.ReactionType.PHYSICAL_MELEE,
			ctx.graveyard_target
		)
		if ctx.audio != null:
			ctx.audio.play_graveyard_tumble(ctx.graveyard_target)
	)

	# 6. HOLD — the king holds his pose. This is the most distinctive timing element.
	t.tween_interval(_profile.impact_hold)

	# 7. Dignified settle — slow, measured return to proper position
	t.set_parallel(true)
	t.tween_property(attacker, "position", ctx.target_world, _profile.settle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", 0.0, _profile.settle_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	t.chain()

	# 8. Complete
	t.tween_callback(func():
		if is_instance_valid(attacker):
			attacker.reset_visual_transform()
		if ctx.on_complete.is_valid():
			ctx.on_complete.call()
	)
