## CaptureChoreographyBase — Abstract base for all six piece-specific capture choreographies.
## Subclasses override _execute_impl() to define the visual sequence.
## All choreographies must eventually call ctx.on_complete.call() — this is the contract.
class_name CaptureChoreographyBase
extends RefCounted

# Execute this choreography using the given context.
# Subclasses must call ctx.on_complete.call() when their full sequence is finished.
# They must NOT modify ChessGame, BoardState, or any chess logic.
func execute(ctx: CaptureContext) -> void:
	if not _validate_context(ctx):
		# Safety fallback: run the generic sequence and complete
		_generic_fallback(ctx)
		return
	_execute_impl(ctx)


# Override in subclasses. Guaranteed: ctx.attacker and ctx.defender are valid.
func _execute_impl(ctx: CaptureContext) -> void:
	# Default: generic fallback (should never be called on properly-instantiated subclass)
	_generic_fallback(ctx)


# ─── SHARED HELPERS ──────────────────────────────────────────────────────────

## Rotate attacker mesh to face world-space direction.
## Uses the mesh's existing Y offset so orientation doesn't shift the piece's visual baseline.
func _face_target(attacker: PieceController, target_pos: Vector3) -> void:
	var dir = target_pos - attacker.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var mesh = attacker.get_mesh_instance()
	if not is_instance_valid(mesh):
		return
	var angle = atan2(dir.x, dir.z)
	# Preserve existing mesh rotation on X/Z from the base calibration
	mesh.rotation.y = angle


## Smoothly tween attacker mesh rotation toward target direction.
func _face_target_smooth(attacker: PieceController, target_pos: Vector3, duration: float) -> void:
	var dir = target_pos - attacker.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var angle = atan2(dir.x, dir.z)
	var mesh = attacker.get_mesh_instance()
	if not is_instance_valid(mesh):
		return
	var t = attacker.get_tree().create_tween()
	t.tween_property(mesh, "rotation:y", angle, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Move attacker to a world position, optionally with a Y arc (for Knight).
func _move_attacker(
	attacker: PieceController,
	to: Vector3,
	duration: float,
	arc_y: float = 0.0,
	trans: Tween.TransitionType = Tween.TRANS_SINE,
	ease: Tween.EaseType = Tween.EASE_IN_OUT
) -> Tween:
	var t = attacker.get_tree().create_tween()
	if arc_y > 0.0:
		t.set_parallel(true)
		t.tween_property(attacker, "position:x", to.x, duration).set_trans(trans).set_ease(ease)
		t.tween_property(attacker, "position:z", to.z, duration).set_trans(trans).set_ease(ease)
		# Y arc: up then down
		t.tween_property(attacker, "position:y", arc_y, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(attacker, "position:y", to.y, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(duration * 0.45)
	else:
		t.tween_property(attacker, "position", to, duration).set_trans(trans).set_ease(ease)
	return t


## Shake the camera briefly through the VFXController if available.
## The actual camera shake lives in VFXController to avoid touching BoardView.
func _camera_shake(ctx: CaptureContext, strength: float) -> void:
	if ctx.vfx != null and ctx.vfx.has_method("play_camera_shake"):
		ctx.vfx.play_camera_shake(strength)


## Trigger a generic physical impact VFX at position.
func _impact_vfx(ctx: CaptureContext, pos: Vector3) -> void:
	if ctx.vfx == null:
		return
	ctx.vfx.play_impact_vfx(pos + Vector3(0, 0.8, 0))


## Trigger a magical impact VFX variant.
func _magical_impact_vfx(ctx: CaptureContext, pos: Vector3) -> void:
	if ctx.vfx == null:
		return
	if ctx.vfx.has_method("play_magical_impact_vfx"):
		ctx.vfx.play_magical_impact_vfx(pos + Vector3(0, 0.8, 0))
	else:
		ctx.vfx.play_impact_vfx(pos + Vector3(0, 0.8, 0))


## Trigger a physical (arrow/siege) impact VFX variant.
func _physical_impact_vfx(ctx: CaptureContext, pos: Vector3) -> void:
	if ctx.vfx == null:
		return
	if ctx.vfx.has_method("play_physical_impact_vfx"):
		ctx.vfx.play_physical_impact_vfx(pos + Vector3(0, 0.6, 0))
	else:
		ctx.vfx.play_impact_vfx(pos + Vector3(0, 0.6, 0))


# ─── VALIDATION AND FALLBACK ─────────────────────────────────────────────────

func _validate_context(ctx: CaptureContext) -> bool:
	if not is_instance_valid(ctx.attacker):
		push_warning("[Combat] Choreography aborted: attacker PieceController invalid.")
		return false
	if not is_instance_valid(ctx.defender):
		push_warning("[Combat] Choreography aborted: defender PieceController invalid.")
		return false
	return true


## Generic fallback — the old Hop-and-Smash, used if a specific choreography fails.
func _generic_fallback(ctx: CaptureContext) -> void:
	push_warning("[Combat] Using generic fallback choreography.")
	if not is_instance_valid(ctx.attacker) or not is_instance_valid(ctx.defender):
		if ctx.on_complete.is_valid():
			ctx.on_complete.call()
		return

	var attack_dir_xz = ctx.attack_dir
	var approach_pos = ctx.target_world - (attack_dir_xz * 0.8)
	var t = ctx.attacker.get_tree().create_tween()

	t.tween_property(ctx.attacker, "position", approach_pos, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(ctx.attacker, "position:y", 0.4, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ctx.attacker, "position", ctx.target_world, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		ctx.attacker.trigger_impact_shake()
		_impact_vfx(ctx, ctx.target_world)
		DefenderReaction.react(ctx.defender, DefenderReaction.ReactionType.PHYSICAL_MELEE, ctx.graveyard_target)
		if ctx.audio:
			ctx.audio.play_capture_impact(ctx.target_world)
			ctx.audio.play_graveyard_tumble(ctx.graveyard_target)
	)
	t.tween_interval(0.20)
	t.tween_callback(func():
		if is_instance_valid(ctx.attacker):
			ctx.attacker.reset_visual_transform()
		if ctx.on_complete.is_valid():
			ctx.on_complete.call()
	)
