## CaptureContext — Internal data-transfer object passed to every choreography.
## Contains all information a choreography needs to execute a capture presentation.
## Must NOT contain chess rules, legal-move logic, or board state mutation.
class_name CaptureContext
extends RefCounted

# Visual piece controllers
var attacker: PieceController
var defender: PieceController

# The chess move as executed by the engine (already applied to board state)
var move: ChessMove

# The piece type of the attacker AT THE MOMENT THE MOVE WAS INITIATED.
# CRITICAL: must be snapshotted before any promotion mutation changes moving_piece.type.
# This ensures a promoting pawn always plays Pawn choreography, not Queen.
var attacker_type_snapshot: ChessTypes.PieceType

# World-space coordinates
var square_size: float
var origin_world: Vector3        # where attacker currently stands visually
var target_world: Vector3        # center of destination square
var defender_world: Vector3      # actual world position of the defender (differs from target_world on en passant)
var graveyard_target: Vector3    # where the defeated defender should be sent
var attack_dir: Vector3          # normalized direction from attacker to defender

# Shared presentation systems
var vfx: VFXController
var audio: AudioController

# Called by the choreography when the full visual sequence is complete.
# CapturePresentationManager binds this to emit capture_presentation_finished.
var on_complete: Callable

func _init(
	p_attacker: PieceController,
	p_defender: PieceController,
	p_move: ChessMove,
	p_attacker_type: ChessTypes.PieceType,
	p_square_size: float,
	p_graveyard_target: Vector3,
	p_vfx: VFXController,
	p_audio: AudioController,
	p_on_complete: Callable
) -> void:
	attacker = p_attacker
	defender = p_defender
	move = p_move
	attacker_type_snapshot = p_attacker_type
	square_size = p_square_size
	graveyard_target = p_graveyard_target
	vfx = p_vfx
	audio = p_audio
	on_complete = p_on_complete

	# Precompute world positions
	origin_world = attacker.global_position
	target_world = Vector3(move.to_position.x * p_square_size, 0.0, move.to_position.y * p_square_size)

	# En passant: the captured pawn is on a different square than the destination.
	# move.captured_piece.position holds the actual logical board position of the captured piece.
	if move.captured_piece != null:
		defender_world = Vector3(
			move.captured_piece.position.x * p_square_size,
			0.0,
			move.captured_piece.position.y * p_square_size
		)
	else:
		defender_world = target_world

	# Direction from attacker origin to the actual defender position
	var raw_dir = defender_world - origin_world
	if raw_dir.length_squared() > 0.0001:
		attack_dir = raw_dir.normalized()
	else:
		attack_dir = Vector3.FORWARD
