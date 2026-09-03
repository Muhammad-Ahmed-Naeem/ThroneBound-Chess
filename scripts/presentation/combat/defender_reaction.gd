## DefenderReaction — Reusable system for animating the defeated piece off the board.
## Triggered at the moment of impact. Handles both melee and ranged hit styles.
## Works with the existing graveyard system — it simply puppets the existing defender PieceController
## rather than spawning any new node.
class_name DefenderReaction
extends RefCounted

enum ReactionType {
	PHYSICAL_MELEE,  # Strong but ground-level hit — tumble + arc
	RANGED_IMPACT    # Upward burst from projectile — launch + arc
}

## Trigger defender reaction at the moment of visual impact.
## attacker_type: used to choose the reaction variant
## on_graveyard_arrive: called when the piece settles in the graveyard (optional)
static func react(
	defender: PieceController,
	reaction_type: ReactionType,
	graveyard_target: Vector3,
	on_graveyard_arrive: Callable = Callable()
) -> void:
	if not is_instance_valid(defender):
		if on_graveyard_arrive.is_valid():
			on_graveyard_arrive.call()
		return

	var mesh = defender.get_mesh_instance()
	if not is_instance_valid(mesh):
		_simple_slide(defender, graveyard_target, on_graveyard_arrive)
		return

	match reaction_type:
		ReactionType.PHYSICAL_MELEE:
			_melee_reaction(defender, mesh, graveyard_target, on_graveyard_arrive)
		ReactionType.RANGED_IMPACT:
			_ranged_reaction(defender, mesh, graveyard_target, on_graveyard_arrive)
		_:
			_simple_slide(defender, graveyard_target, on_graveyard_arrive)

# --- Melee reaction: knocked backward, tumbles to graveyard ---
static func _melee_reaction(
	defender: PieceController,
	mesh: MeshInstance3D,
	graveyard_target: Vector3,
	on_arrive: Callable
) -> void:
	var t = defender.get_tree().create_tween()
	t.set_parallel(true)

	# XZ slide to graveyard
	t.tween_property(defender, "position:x", graveyard_target.x, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(defender, "position:z", graveyard_target.z, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Upward arc and back down
	t.tween_property(defender, "position:y", 2.8, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(defender, "position:y", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.24)

	# Tumble rotation
	t.tween_property(mesh, "rotation", Vector3(PI * 2.0, PI * 1.5, 0.3), 0.50)

	t.chain().tween_callback(func():
		_reset_defender_rotation(defender)
		if on_arrive.is_valid():
			on_arrive.call()
	)

# --- Ranged reaction: hit by projectile — upward burst, stronger launch ---
static func _ranged_reaction(
	defender: PieceController,
	mesh: MeshInstance3D,
	graveyard_target: Vector3,
	on_arrive: Callable
) -> void:
	var t = defender.get_tree().create_tween()
	t.set_parallel(true)

	# XZ slide to graveyard
	t.tween_property(defender, "position:x", graveyard_target.x, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(defender, "position:z", graveyard_target.z, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Stronger upward burst from projectile hit
	t.tween_property(defender, "position:y", 3.6, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(defender, "position:y", 0.0, 0.33).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.22)

	# Wild tumble
	t.tween_property(mesh, "rotation", Vector3(PI * 2.5, PI * 2.0, PI * 0.5), 0.55)

	t.chain().tween_callback(func():
		_reset_defender_rotation(defender)
		if on_arrive.is_valid():
			on_arrive.call()
	)

# --- Fallback: simple slide (no tumble) ---
static func _simple_slide(
	defender: PieceController,
	graveyard_target: Vector3,
	on_arrive: Callable
) -> void:
	var t = defender.get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(defender, "position:x", graveyard_target.x, 0.45)
	t.tween_property(defender, "position:z", graveyard_target.z, 0.45)
	t.chain().tween_callback(func():
		if on_arrive.is_valid():
			on_arrive.call()
	)

# Restore rotation to the correct rest orientation for this piece type
static func _reset_defender_rotation(defender: PieceController) -> void:
	if not is_instance_valid(defender):
		return
	var mesh = defender.get_mesh_instance()
	if not is_instance_valid(mesh):
		return
	var is_white = (defender.logical_piece.color == ChessTypes.PieceColor.WHITE)
	if defender.logical_piece.type == ChessTypes.PieceType.KNIGHT:
		mesh.rotation = Vector3(0, PI / 2.0 if is_white else -PI / 2.0, 0)
	else:
		mesh.rotation = Vector3.ZERO
