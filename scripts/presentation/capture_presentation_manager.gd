## CapturePresentationManager — Central orchestrator for all capture presentations.
##
## PUBLIC API IS UNCHANGED from previous milestones:
##   play_capture_sequence(attacker, defender, move, square_size, graveyard_target, vfx, audio)
##   signal capture_presentation_finished
##   _is_busy: bool
##
## Internally this now routes to six distinct piece-specific choreographies rather than
## the previous generic "Hop and Smash" sequence. The chess engine (BoardView) is not
## aware of this internal change.
##
## Choreography selection is based on the ATTACKER'S PIECE TYPE AT MOVE INITIATION,
## snapshotted before any promotion mutation can change the piece type.
## This ensures a promoting pawn always plays Pawn choreography, not Queen.
class_name CapturePresentationManager
extends Node

signal capture_presentation_finished

var _is_busy: bool = false

# Lazy-instantiated choreography objects (one per piece type, reused across captures)
var _choreographies: Dictionary = {}

# Debug output — set to true during development to log capture identity
const DEBUG_COMBAT: bool = false


func _ready() -> void:
	_init_choreographies()


func _init_choreographies() -> void:
	_choreographies[ChessTypes.PieceType.PAWN]   = PawnCaptureChoreography.new()
	_choreographies[ChessTypes.PieceType.KNIGHT]  = KnightCaptureChoreography.new()
	_choreographies[ChessTypes.PieceType.BISHOP]  = BishopCaptureChoreography.new()
	_choreographies[ChessTypes.PieceType.ROOK]    = RookCaptureChoreography.new()
	_choreographies[ChessTypes.PieceType.QUEEN]   = QueenCaptureChoreography.new()
	_choreographies[ChessTypes.PieceType.KING]    = KingCaptureChoreography.new()


## Primary entry point — called by BoardView. Public API is identical to previous milestones.
## attacker: PieceController of the capturing piece (already at its pre-move visual position)
## defender: PieceController of the captured piece (still at its board position)
## move:     The ChessMove as executed by ChessGame (board state already updated)
## square_size: World units per chess square
## graveyard_target: World position the defender should travel to
## vfx / audio: Optional presentation systems (may be null)
func play_capture_sequence(
	attacker: PieceController,
	defender: PieceController,
	move: ChessMove,
	square_size: float,
	graveyard_target: Vector3,
	vfx: VFXController = null,
	audio: AudioController = null
) -> void:
	if _is_busy:
		push_warning("[CapturePresentationManager] Already busy — ignoring duplicate capture call.")
		return

	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		push_warning("[CapturePresentationManager] Invalid attacker or defender — emitting finished immediately.")
		capture_presentation_finished.emit()
		return

	_is_busy = true

	# --- CRITICAL: Snapshot attacker type BEFORE any promotion can mutate it ---
	# After ChessGame.try_move(), a promoting pawn's moving_piece.type may already be QUEEN.
	# We preserve the original pawn identity so choreography selection is correct.
	# The attacker PieceController's logical_piece.type may already reflect the promoted type,
	# but the visual piece type for combat selection must be the piece that INITIATED the move.
	var attacker_type := _determine_attacker_type(move)

	if DEBUG_COMBAT:
		var type_name = ChessTypes.PieceType.keys()[attacker_type]
		print("[Combat] %s -> %s | attacker_type: %s" % [
			_pos_str(move.from_position), _pos_str(move.to_position), type_name
		])

	# --- Build CaptureContext ---
	var ctx := CaptureContext.new(
		attacker,
		defender,
		move,
		attacker_type,
		square_size,
		graveyard_target,
		vfx,
		audio,
		func(): _on_sequence_complete()
	)

	# --- Select and execute choreography ---
	var choreography: CaptureChoreographyBase = _get_choreography(attacker_type)
	choreography.execute(ctx)


## Determine the attacker's piece type for choreography selection.
## Uses move.moving_piece.type but cross-checks for promotion:
## if the move was a PROMOTION, the original type must be PAWN regardless of current piece state.
func _determine_attacker_type(move: ChessMove) -> ChessTypes.PieceType:
	if move.move_type == ChessMove.MoveType.PROMOTION:
		# The attacker was definitively a Pawn before promotion
		return ChessTypes.PieceType.PAWN
	# For all other move types, the moving_piece.type is still the correct attacking type
	return move.moving_piece.type


func _get_choreography(piece_type: ChessTypes.PieceType) -> CaptureChoreographyBase:
	if _choreographies.has(piece_type):
		return _choreographies[piece_type]
	push_warning("[CapturePresentationManager] No choreography for type %d — using base fallback." % piece_type)
	return CaptureChoreographyBase.new()


func _on_sequence_complete() -> void:
	_is_busy = false
	capture_presentation_finished.emit()


# --- Debug helpers ---
func _pos_str(pos: Vector2i) -> String:
	var file_char = char(ord('a') + pos.x)
	return "%s%d" % [file_char, pos.y + 1]
