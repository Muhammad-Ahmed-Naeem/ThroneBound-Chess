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

	# Audio: arrow launch (play once for the volley)
	var spawn_pos_center := attacker.global_position + Vector3(0, 1.8, 0)
	if ctx.audio != null and ctx.audio.has_method("play_arrow_launch"):
		ctx.audio.play_arrow_launch(spawn_pos_center)

	# Calculate perpendicular offset for the spread
	var right_dir := Vector3(-ctx.attack_dir.z, 0, ctx.attack_dir.x).normalized()
	
	# Fire a volley of 3 arrows (left, center, right)
	var offsets = [-0.4, 0.0, 0.4]
	var delays = [0.0, 0.05, 0.1] # Slight staggering for AAA feel

	for i in range(3):
		var offset = right_dir * offsets[i]
		var spawn_pos = spawn_pos_center + offset
		var target_pos = ctx.defender_world + Vector3(0, 0.5, 0) + (offset * 0.5) # slightly spread out on target too
		
		# We only want the first arrow to trigger the main sequence advancement
		var is_first = (i == 0)
		var impact_callback = func(): _on_projectile_impact(ctx, is_first, target_pos)

		var t = attacker.get_tree().create_tween()
		t.tween_interval(delays[i])
		t.tween_callback(func():
			ProjectileController.launch(
				attacker.get_parent(),
				spawn_pos,
				target_pos,
				_profile.projectile_duration,
				ProjectileController.ProjectileType.PHYSICAL_ARROW,
				impact_callback,
				_profile.projectile_arc_height,
				ctx.vfx,
				ctx.audio
			)
		)


func _on_projectile_impact(ctx: CaptureContext, is_main: bool, hit_pos: Vector3) -> void:
	# Physical impact VFX at the specific hit position
	_physical_impact_vfx(ctx, hit_pos)
	_camera_shake(ctx, _profile.camera_shake_strength * (1.0 if is_main else 0.5))

	# Audio: arrow/bolt impact
	if ctx.audio != null and ctx.audio.has_method("play_arrow_impact"):
		ctx.audio.play_arrow_impact(hit_pos)

	if is_main:
		# Trigger defender reaction (ranged — stronger upward burst) only on the first main hit
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
