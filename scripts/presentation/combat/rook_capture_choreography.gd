## RookCaptureChoreography — Siege tower physical projectile attack.
## Identity: The Rook is a fortified tower / siege engine.
## The Rook does NOT run toward the defender. It activates its siege mechanism,
## fires a physical bolt/arrow, then deliberately advances to the captured square.
##
## Total duration: ~0.85 seconds
## Sequence:
##   1. Stay on origin — power-up scale pulse + light flash (0.18s)
##   2. Short launch pause (0.05s)
##   3. Arrow/bolt launches from tower top
##   4. Projectile travels straight to target (0.40s)
##   5. Impact: physical sparks + audio + defender reaction
##   6. Brief hold (0.04s)
##   7. Rook advances to destination square (0.28s)
##   8. Settle + complete (0.08s)
class_name RookCaptureChoreography
extends CaptureChoreographyBase

var _profile: CaptureProfile = CaptureProfile.rook()


func _execute_impl(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	var mesh := attacker.get_mesh_instance()

	# 1. Face target
	_face_target(attacker, ctx.defender_world)

	var t := attacker.get_tree().create_tween()

	# 2. Power-up activation: subtle scale pulse (tower "charges")
	t.set_parallel(true)
	if is_instance_valid(mesh):
		var orig_scale := mesh.scale
		t.tween_property(mesh, "scale", orig_scale * 1.05, _profile.anticipation_duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(mesh, "scale", orig_scale, _profile.anticipation_duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(_profile.anticipation_duration * 0.5)

	# Brief light flash at tower position
	t.tween_callback(func():
		if ctx.vfx != null and ctx.vfx.has_method("play_power_up_flash"):
			ctx.vfx.play_power_up_flash(attacker.global_position + Vector3(0, 1.5, 0))
	)

	t.chain()

	# 3. Short hold before firing
	t.tween_interval(_profile.attack_duration)

	# 4. Fire
	t.tween_callback(func():
		_launch_arrow(ctx)
	)


func _launch_arrow(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	if not is_instance_valid(attacker):
		_finish(ctx)
		return

	# Projectile spawns from the top of the tower mesh
	var spawn_pos := attacker.global_position + Vector3(0, 1.8, 0)

	# Audio: arrow launch
	if ctx.audio != null and ctx.audio.has_method("play_arrow_launch"):
		ctx.audio.play_arrow_launch(spawn_pos)

	# Launch the physical bolt
	ProjectileController.launch(
		attacker.get_parent(),
		spawn_pos,
		ctx.defender_world + Vector3(0, 0.5, 0),  # aim at lower center of defender
		_profile.projectile_duration,
		ProjectileController.ProjectileType.PHYSICAL_ARROW,
		func(): _on_projectile_impact(ctx),
		_profile.projectile_arc_height,  # 0 = straight
		ctx.vfx,
		ctx.audio
	)


func _on_projectile_impact(ctx: CaptureContext) -> void:
	# Physical impact VFX at defender position
	_physical_impact_vfx(ctx, ctx.defender_world)
	_camera_shake(ctx, _profile.camera_shake_strength)

	# Audio: arrow/bolt impact
	if ctx.audio != null and ctx.audio.has_method("play_arrow_impact"):
		ctx.audio.play_arrow_impact(ctx.defender_world)

	# Trigger defender reaction (ranged — stronger upward burst)
	DefenderReaction.react(
		ctx.defender,
		DefenderReaction.ReactionType.RANGED_IMPACT,
		ctx.graveyard_target
	)

	if ctx.audio != null:
		ctx.audio.play_graveyard_tumble(ctx.graveyard_target)

	# Brief hold then advance tower to destination
	var attacker := ctx.attacker
	if not is_instance_valid(attacker):
		_finish(ctx)
		return

	var t := attacker.get_tree().create_tween()
	t.tween_interval(_profile.impact_hold)
	t.tween_callback(func(): _advance_to_destination(ctx))


func _advance_to_destination(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	if not is_instance_valid(attacker):
		_finish(ctx)
		return

	# Rook deliberately advances to the captured square
	_face_target(attacker, ctx.target_world)

	var t := attacker.get_tree().create_tween()
	t.tween_property(attacker, "position", ctx.target_world, _profile.post_fire_move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	t.tween_interval(_profile.settle_duration)

	t.tween_callback(func():
		if is_instance_valid(attacker):
			attacker.reset_visual_transform()
		_finish(ctx)
	)


func _finish(ctx: CaptureContext) -> void:
	if ctx.on_complete.is_valid():
		ctx.on_complete.call()
