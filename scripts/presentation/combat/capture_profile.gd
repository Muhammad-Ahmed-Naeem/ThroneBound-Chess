## CaptureProfile — Data container for per-piece timing and configuration.
## Centralises all magic-number timing so they can be tuned without touching choreography logic.
class_name CaptureProfile
extends RefCounted

enum AttackType {
	MELEE,    # Attacker moves toward defender (Pawn, Knight, Queen, King)
	RANGED    # Attacker stays near origin and fires a projectile (Bishop, Rook)
}

enum ProjectileType {
	MAGICAL,        # Glowing orb — Bishop
	PHYSICAL_ARROW  # Narrow bolt/arrow — Rook
}

# Whether the attacker remains on its origin square during the strike phase
var stay_on_origin: bool = false

var attack_type: AttackType = AttackType.MELEE
var projectile_type: ProjectileType = ProjectileType.MAGICAL

# --- Timing (seconds) ---
var approach_duration: float = 0.22      # travel from origin toward defender
var anticipation_duration: float = 0.10  # wind-up / lean / bob
var attack_duration: float = 0.10        # strike / snap / thrust / cast
var projectile_duration: float = 0.50    # time for projectile to travel (ranged only)
var impact_hold: float = 0.05            # brief pause at moment of impact
var defender_reaction_duration: float = 0.55  # defender tumbles to graveyard
var settle_duration: float = 0.18        # attacker returns to neutral
var post_fire_move_duration: float = 0.25  # ranged: attacker slides to destination after projectile

# --- VFX / feel ---
var camera_shake_strength: float = 0.3
var projectile_arc_height: float = 0.0   # 0 = straight; >0 = arc

# --- Convenience total ---
func total_duration() -> float:
	if stay_on_origin:
		return anticipation_duration + attack_duration + projectile_duration + impact_hold + post_fire_move_duration + settle_duration
	return approach_duration + anticipation_duration + attack_duration + impact_hold + settle_duration

# --- Factory helpers ---

static func pawn() -> CaptureProfile:
	var p = CaptureProfile.new()
	p.attack_type = AttackType.MELEE
	p.stay_on_origin = false
	p.approach_duration = 0.22
	p.anticipation_duration = 0.09
	p.attack_duration = 0.09
	p.impact_hold = 0.05
	p.settle_duration = 0.16
	p.camera_shake_strength = 0.25
	return p

static func knight() -> CaptureProfile:
	var p = CaptureProfile.new()
	p.attack_type = AttackType.MELEE
	p.stay_on_origin = false
	p.approach_duration = 0.40  # longer — arc charge
	p.anticipation_duration = 0.16
	p.attack_duration = 0.10
	p.impact_hold = 0.08
	p.settle_duration = 0.18
	p.camera_shake_strength = 0.45
	return p

static func bishop() -> CaptureProfile:
	var p = CaptureProfile.new()
	p.attack_type = AttackType.RANGED
	p.projectile_type = ProjectileType.MAGICAL
	p.stay_on_origin = true
	p.anticipation_duration = 0.18
	p.attack_duration = 0.08
	p.projectile_duration = 0.48
	p.impact_hold = 0.06
	p.post_fire_move_duration = 0.25
	p.settle_duration = 0.10
	p.camera_shake_strength = 0.20
	p.projectile_arc_height = 0.8
	return p

static func rook() -> CaptureProfile:
	var p = CaptureProfile.new()
	p.attack_type = AttackType.RANGED
	p.projectile_type = ProjectileType.PHYSICAL_ARROW
	p.stay_on_origin = true
	p.anticipation_duration = 0.18
	p.attack_duration = 0.05
	p.projectile_duration = 0.40
	p.impact_hold = 0.04
	p.post_fire_move_duration = 0.28
	p.settle_duration = 0.08
	p.camera_shake_strength = 0.35
	p.projectile_arc_height = 0.0
	return p

static func queen() -> CaptureProfile:
	var p = CaptureProfile.new()
	p.attack_type = AttackType.MELEE
	p.stay_on_origin = false
	p.approach_duration = 0.18
	p.anticipation_duration = 0.08
	p.attack_duration = 0.08
	p.impact_hold = 0.04
	p.settle_duration = 0.20
	p.camera_shake_strength = 0.28
	return p

static func king() -> CaptureProfile:
	var p = CaptureProfile.new()
	p.attack_type = AttackType.MELEE
	p.stay_on_origin = false
	p.approach_duration = 0.28   # slower, heavier
	p.anticipation_duration = 0.14
	p.attack_duration = 0.13
	p.impact_hold = 0.14         # king holds pose longer
	p.settle_duration = 0.24
	p.camera_shake_strength = 0.55
	return p
