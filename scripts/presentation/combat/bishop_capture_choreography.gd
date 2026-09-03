## BishopCaptureChoreography — Magical ranged spell attack.
## Identity: The Bishop is a battle-mage / magical priest.
## The Bishop does NOT approach the defender. It stays near its origin,
## performs a casting motion, fires a magical orb, and moves to the destination
## only AFTER the projectile has struck and the defender has reacted.
##
## Total duration: ~1.0 seconds
## Sequence:
##   1. Face target (instant)
##   2. Casting anticipation: body bob up + subtle scale pulse (0.18s)
##   3. Cast hold (0.08s)
##   4. Projectile launches from bishop's elevated position
##   5. Projectile travels to defender (0.48s arc)
##   6. Impact: magical VFX + audio + defender reaction
##   7. Bishop slides to destination square (0.25s)
##   8. Settle + complete (0.10s)
class_name BishopCaptureChoreography
extends CaptureChoreographyBase

var _profile: CaptureProfile = CaptureProfile.bishop()


func _execute_impl(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	var mesh := attacker.get_mesh_instance()

	# 1. Face target
	_face_target(attacker, ctx.defender_world)

	var t := attacker.get_tree().create_tween()

	# 2. Casting anticipation: gentle upward bob + scale pulse (communicates "gathering energy")
	t.set_parallel(true)
	t.tween_property(attacker, "position:y", 0.55, _profile.anticipation_duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "scale", mesh.scale * 1.08, _profile.anticipation_duration * 0.5).set_trans(Tween.TRANS_SINE)

	t.chain()

	# Return bob down
	t.set_parallel(true)
	t.tween_property(attacker, "position:y", 0.0, _profile.anticipation_duration * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(mesh):
		t.tween_property(mesh, "scale", mesh.scale, _profile.anticipation_duration * 0.4).set_trans(Tween.TRANS_SINE)

	t.chain()

	# 3. Cast hold — brief pause before the spell fires
	t.tween_interval(_profile.attack_duration)

	# 4. Launch projectile and wait for it to travel + hit
	t.tween_callback(func():
		_launch_spell(ctx)
	)

	# Wait for projectile travel + impact reaction + attacker movement — total controlled by callbacks


func _launch_spell(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	if not is_instance_valid(attacker):
		_finish(ctx)
		return

	# Spawn projectile from slightly above the bishop's center
	var spawn_pos := attacker.global_position + Vector3(0, 1.2, 0)

	# Subtle VFX flash at cast origin
	if ctx.vfx != null and ctx.vfx.has_method("play_power_up_flash"):
		ctx.vfx.play_power_up_flash(spawn_pos)

	# Audio: spell cast
	if ctx.audio != null and ctx.audio.has_method("play_spell_cast"):
		ctx.audio.play_spell_cast(spawn_pos)

	# Launch the projectile
	ProjectileController.launch(
		attacker.get_parent(),  # parent to the BoardView-level node
		spawn_pos,
		ctx.defender_world + Vector3(0, 0.8, 0),  # aim at center-of-mass of defender
		_profile.projectile_duration,
		ProjectileController.ProjectileType.MAGICAL,
		func(): _on_projectile_impact(ctx),
		_profile.projectile_arc_height,
		ctx.vfx,
		ctx.audio
	)


func _on_projectile_impact(ctx: CaptureContext) -> void:
	# Visual impact at defender position
	_magical_impact_vfx(ctx, ctx.defender_world)
	_camera_shake(ctx, _profile.camera_shake_strength)

	# Audio: spell impact
	if ctx.audio != null and ctx.audio.has_method("play_spell_impact"):
		ctx.audio.play_spell_impact(ctx.defender_world)

	# Trigger defender reaction
	DefenderReaction.react(
		ctx.defender,
		DefenderReaction.ReactionType.RANGED_IMPACT,
		ctx.graveyard_target
	)

	# Audio: graveyard tumble
	if ctx.audio != null:
		ctx.audio.play_graveyard_tumble(ctx.graveyard_target)

	# Impact hold pause, then move bishop to destination
	var attacker := ctx.attacker
	if not is_instance_valid(attacker):
		_finish(ctx)
		return

	var t := attacker.get_tree().create_tween()
	t.tween_interval(_profile.impact_hold)
	t.tween_callback(func(): _move_to_destination(ctx))


func _move_to_destination(ctx: CaptureContext) -> void:
	var attacker := ctx.attacker
	if not is_instance_valid(attacker):
		_finish(ctx)
		return

	# Face destination direction
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
