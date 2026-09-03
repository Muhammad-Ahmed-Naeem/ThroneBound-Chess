## QueenCaptureChoreography — Elegant, fast sword attack.
## Identity: Warrior Queen. Fast, controlled, powerful, graceful.
## The Queen approaches quickly, performs a sweeping slash via body rotation,
## and settles with authority. Should feel distinctly faster/lighter than the King,
## yet more refined than the Pawn.
##
## Total duration: ~0.95 seconds
## Sequence:
##   1. Face target (snap)
##   2. Fast approach to just before the defender (0.18s) — fast EASE_IN
##   3. Anticipation: slight rotation and body bob (0.08s)
##   4. Slash sweep: fast body rotation + lunge to target (0.08s) — "sword arc"
##   5. Impact: physical VFX + sword sound + defender reaction
##   6. Brief hold (0.04s)
##   7. Elegant settle: slight backstep + rotation reset (0.20s)
##   8. Complete
class_name QueenCaptureChoreography
extends CaptureChoreographyBase

var _profile: CaptureProfile = CaptureProfile.queen()


func _execute_impl(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	var mesh := attacker.get_mesh_instance()

	# 1. Face target
	_face_target(attacker, ctx.defender_world)

	# Pre-calculate approach position (just before defender)
	var approach_stop := ctx.defender_world - ctx.attack_dir * 0.75

	var t := attacker.get_tree().create_tween()

	# 2. Fast elegant approach
	t.tween_property(attacker, "position", approach_stop, _profile.approach_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 3. Anticipation: subtle diagonal body lean ("coiling before the strike")
	t.set_parallel(true)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", -0.14, _profile.anticipation_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Slight side-step rotation — "drawing for a slash"
		t.tween_property(mesh, "rotation:z", -0.12, _profile.anticipation_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.chain()

	# 4. Slash + lunge — simultaneous fast movement + sweep rotation
	t.set_parallel(true)
	t.tween_property(attacker, "position", ctx.defender_world, _profile.attack_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	if is_instance_valid(mesh):
		# Wide sweeping arc rotation — the "sword slash"
		t.tween_property(mesh, "rotation:z", 0.28, _profile.attack_duration
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		t.tween_property(mesh, "rotation:x", 0.10, _profile.attack_duration
		).set_trans(Tween.TRANS_EXPO)

	t.chain()

	# 5. Impact
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

		DefenderReaction.react(
			ctx.defender,
			DefenderReaction.ReactionType.PHYSICAL_MELEE,
			ctx.graveyard_target
		)
		if ctx.audio != null:
			ctx.audio.play_graveyard_tumble(ctx.graveyard_target)
	)

	# 6. Hold
	t.tween_interval(_profile.impact_hold)

	# 7. Elegant settle — brief backstep to target center, rotation reset
	t.set_parallel(true)
	t.tween_property(attacker, "position", ctx.target_world, _profile.settle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "rotation:x", 0.0, _profile.settle_duration).set_trans(Tween.TRANS_SINE)
		t.tween_property(mesh, "rotation:z", 0.0, _profile.settle_duration).set_trans(Tween.TRANS_SINE)

	t.chain()

	# 8. Complete
	t.tween_callback(func():
		if is_instance_valid(attacker):
			attacker.reset_visual_transform()
		if ctx.on_complete.is_valid():
			ctx.on_complete.call()
	)
