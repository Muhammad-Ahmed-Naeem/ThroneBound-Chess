class_name AudioController
extends Node

var _sfx_movement: AudioStream
var _sfx_capture: AudioStream
var _sfx_graveyard: AudioStream

func _ready() -> void:
	_sfx_movement = _safe_load("res://assets/audio/movement.wav")
	_sfx_capture = _safe_load("res://assets/audio/capture_impact.wav")
	_sfx_graveyard = _safe_load("res://assets/audio/graveyard_tumble.wav")
	_ready_combat()

func _safe_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	push_warning("Audio file not found or not imported yet: ", path)
	return null

func play_movement(pos: Vector3) -> void:
	_play_3d(_sfx_movement, pos, "Movement", 8.0) # Boosted volume

func play_capture_impact(pos: Vector3) -> void:
	pass # Removed explosion sound as requested

func play_graveyard_tumble(pos: Vector3) -> void:
	pass # Removed explosion-like sounds

func _play_3d(stream: AudioStream, pos: Vector3, event_name: String, volume_db: float = 0.0) -> void:
	if stream == null:
		print("[AudioController] Missing stream for event: ", event_name, " at ", pos)
		return
		
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.position = pos
	player.autoplay = true
	
	# AAA audio design: slight pitch randomization prevents ear fatigue
	player.pitch_scale = randf_range(0.85, 1.1)
	
	# Add some spatial tuning so it sounds good
	player.max_distance = 50.0
	player.unit_size = 5.0
	player.bus = "Master"
	
	add_child(player)
	
	player.finished.connect(func():
		player.queue_free()
	)

# --- Milestone 12: Signature Combat Audio Events ---
# All methods gracefully fall back to an existing sound or silence if the specific
# audio file is not present. A missing audio file must never break the capture sequence.

var _sfx_spell_cast: AudioStream
var _sfx_spell_impact: AudioStream
var _sfx_arrow_launch: AudioStream
var _sfx_arrow_impact: AudioStream
var _sfx_sword_swing: AudioStream
var _sfx_sword_impact: AudioStream
var _sfx_spear_thrust: AudioStream
var _sfx_horse_charge: AudioStream
var _sfx_defeat_clash: AudioStream

func _load_combat_sounds() -> void:
	_sfx_spell_cast   = _safe_load("res://assets/audio/spell_cast.ogg")
	_sfx_spell_impact = _safe_load("res://assets/audio/spell_impact.ogg")
	_sfx_arrow_launch = _safe_load("res://assets/audio/arrow_launch.ogg")
	_sfx_arrow_impact = _safe_load("res://assets/audio/arrow_impact.ogg")
	_sfx_sword_swing  = _safe_load("res://assets/audio/sword_swing.ogg")
	_sfx_sword_impact = _safe_load("res://assets/audio/sword_impact.ogg")
	_sfx_spear_thrust = _safe_load("res://assets/audio/spear_thrust.ogg")
	_sfx_horse_charge = _safe_load("res://assets/audio/horse_charge.ogg")
	_sfx_defeat_clash = _safe_load("res://assets/audio/defeat_clash.ogg")

# Called from _ready() to register combat sounds alongside existing sounds
func _ready_combat() -> void:
	_load_combat_sounds()

# Bishop — magical cast sound (at spell origin)
func play_spell_cast(pos: Vector3) -> void:
	var stream = _sfx_spell_cast
	if stream != null:
		_play_3d(stream, pos, "SpellCast", -4.0)

# Bishop — magical impact on defender
func play_spell_impact(pos: Vector3) -> void:
	var stream = _sfx_spell_impact
	if stream != null:
		_play_3d(stream, pos, "SpellImpact")

# Rook — arrow/bolt launch from tower
func play_arrow_launch(pos: Vector3) -> void:
	var stream = _sfx_arrow_launch if _sfx_arrow_launch != null else _sfx_movement
	if stream != null:
		_play_3d(stream, pos, "ArrowLaunch", 4.0)

# Rook — arrow/bolt physical impact on defender
func play_arrow_impact(pos: Vector3) -> void:
	var stream = _sfx_arrow_impact
	if stream != null:
		_play_3d(stream, pos, "ArrowImpact")

# Queen / King — sword swing during attack
func play_sword_swing(pos: Vector3) -> void:
	var stream = _sfx_sword_swing
	if stream != null:
		_play_3d(stream, pos, "SwordSwing", 2.0)

# Queen / King — sword impact on contact
func play_sword_impact(pos: Vector3) -> void:
	var stream = _sfx_sword_impact
	if stream != null:
		_play_3d(stream, pos, "SwordImpact")

# Pawn — spear/thrust sound on contact
func play_spear_thrust(pos: Vector3) -> void:
	var stream = _sfx_spear_thrust
	if stream != null:
		_play_3d(stream, pos, "SpearThrust")

# Generic defeat clash (played when any piece is beaten)
func play_defeat_clash(pos: Vector3) -> void:
	var stream = _sfx_defeat_clash
	if stream != null:
		_play_3d(stream, pos, "DefeatClash")

# Knight — horse charge / heavy movement sound
func play_horse_charge(pos: Vector3) -> void:
	var stream = _sfx_horse_charge if _sfx_horse_charge != null else _sfx_movement
	if stream != null:
		_play_3d(stream, pos, "HorseCharge", 6.0)
