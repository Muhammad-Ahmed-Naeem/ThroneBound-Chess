## ProjectileController — Reusable visual-only projectile for Bishop and Rook captures.
## No physics body. No collision. No chess-rules impact.
## Purely a presentation node that interpolates position, faces its travel direction,
## fires an impact callback on arrival, then cleans itself up.
class_name ProjectileController
extends Node3D

enum ProjectileType {
	MAGICAL,        # Glowing arcane orb — Bishop
	PHYSICAL_ARROW  # Narrow bolt/arrow — Rook
}

# How long the node waits after impact before queue_free (allows VFX to linger)
const CLEANUP_DELAY: float = 1.0

var _type: ProjectileType
var _mesh: MeshInstance3D
var _trail_particles: GPUParticles3D
var _glow_light: OmniLight3D
var _impact_callback: Callable
var _vfx: VFXController
var _audio: AudioController
var _is_launched: bool = false


## Build and launch a projectile.
## parent_node    — the scene node to attach this projectile to (typically BoardView)
## start          — world-space origin
## target         — world-space destination (defender position)
## duration       — travel time in seconds
## ptype          — MAGICAL or PHYSICAL_ARROW
## impact_cb      — called the moment the projectile reaches the target
## arc_height     — Y-axis bulge for curved flight (0 = straight)
## vfx / audio    — optional for impact events
static func launch(
	parent_node: Node3D,
	start: Vector3,
	target: Vector3,
	duration: float,
	ptype: ProjectileType,
	impact_cb: Callable,
	arc_height: float = 0.0,
	vfx: VFXController = null,
	audio: AudioController = null
) -> ProjectileController:
	var proj = ProjectileController.new()
	proj._type = ptype
	proj._impact_callback = impact_cb
	proj._vfx = vfx
	proj._audio = audio
	proj.position = start
	parent_node.add_child(proj)
	proj._build_visuals()
	proj._begin_flight(start, target, duration, arc_height)
	return proj


func _build_visuals() -> void:
	match _type:
		ProjectileType.MAGICAL:
			_build_magical()
		ProjectileType.PHYSICAL_ARROW:
			_build_arrow()


# ─── MAGICAL ORB ─────────────────────────────────────────────────────────────

func _build_magical() -> void:
	# Core emissive orb
	_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.20
	sphere.height = 0.40
	_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.8, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0)
	mat.emission_energy_multiplier = 6.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mesh.material_override = mat
	add_child(_mesh)

	# Outer halo (slightly larger, more transparent)
	var halo = MeshInstance3D.new()
	var halo_sphere = SphereMesh.new()
	halo_sphere.radius = 0.32
	halo_sphere.height = 0.64
	halo.mesh = halo_sphere
	var halo_mat = StandardMaterial3D.new()
	halo_mat.albedo_color = Color(0.2, 0.5, 1.0, 0.35)
	halo_mat.emission_enabled = true
	halo_mat.emission = Color(0.1, 0.3, 0.8)
	halo_mat.emission_energy_multiplier = 3.0
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material_override = halo_mat
	add_child(halo)

	# Glow point light
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = Color(0.4, 0.7, 1.0)
	_glow_light.light_energy = 3.5
	_glow_light.omni_range = 6.0
	add_child(_glow_light)

	# Trail particles
	_trail_particles = _make_trail_particles_magical()
	add_child(_trail_particles)

	# Pulse animation on the orb
	var pulse = create_tween().set_loops()
	pulse.tween_property(_mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.18).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_mesh, "scale", Vector3(0.85, 0.85, 0.85), 0.18).set_trans(Tween.TRANS_SINE)


func _make_trail_particles_magical() -> GPUParticles3D:
	var proc = ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 0, -1)  # will be rotated with node
	proc.spread = 25.0
	proc.initial_velocity_min = 0.5
	proc.initial_velocity_max = 1.2
	proc.gravity = Vector3(0, 0.4, 0)
	proc.scale_min = 0.08
	proc.scale_max = 0.18

	var grad = Gradient.new()
	grad.set_color(0, Color(0.4, 0.8, 1.0, 0.9))
	grad.set_color(1, Color(0.1, 0.2, 0.8, 0.0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	proc.color_ramp = gtex

	var qmesh = QuadMesh.new()
	qmesh.size = Vector2(0.14, 0.14)
	var tmat = StandardMaterial3D.new()
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	tmat.vertex_color_use_as_albedo = true
	qmesh.material = tmat

	var ps = GPUParticles3D.new()
	ps.process_material = proc
	ps.draw_pass_1 = qmesh
	ps.amount = 20
	ps.lifetime = 0.35
	ps.explosiveness = 0.0
	ps.emitting = true
	return ps


# ─── PHYSICAL ARROW / BOLT ────────────────────────────────────────────────────

func _build_arrow() -> void:
	# Arrow shaft — narrow capsule oriented along local Z
	_mesh = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.045
	cap.height = 0.80
	_mesh.mesh = cap
	# Rotate capsule 90° so its long axis aligns with local Z (travel direction)
	_mesh.rotation.x = PI / 2.0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.20, 0.12)  # dark wood
	mat.roughness = 0.85
	mat.metallic = 0.1
	_mesh.material_override = mat
	add_child(_mesh)

	# Arrowhead — small cone, attached at front
	var tip = MeshInstance3D.new()
	# Use a small sphere as the tip for simplicity (no CylinderMesh cone top available simply)
	var tip_mesh = SphereMesh.new()
	tip_mesh.radius = 0.07
	tip_mesh.height = 0.18
	tip.mesh = tip_mesh
	var tip_mat = StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.55, 0.55, 0.60)  # dark iron
	tip_mat.metallic = 0.8
	tip_mat.roughness = 0.3
	tip.material_override = tip_mat
	tip.position = Vector3(0, 0, -0.44)  # front of the shaft
	add_child(tip)

	# Subtle directional trail for readability
	_trail_particles = _make_trail_particles_arrow()
	add_child(_trail_particles)


func _make_trail_particles_arrow() -> GPUParticles3D:
	var proc = ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 0, 1)  # behind arrow
	proc.spread = 8.0
	proc.initial_velocity_min = 0.3
	proc.initial_velocity_max = 0.8
	proc.gravity = Vector3(0, -2.0, 0)
	proc.scale_min = 0.05
	proc.scale_max = 0.12

	var grad = Gradient.new()
	grad.set_color(0, Color(0.9, 0.75, 0.4, 0.7))
	grad.set_color(1, Color(0.3, 0.2, 0.1, 0.0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	proc.color_ramp = gtex

	var qmesh = QuadMesh.new()
	qmesh.size = Vector2(0.09, 0.09)
	var tmat = StandardMaterial3D.new()
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	tmat.vertex_color_use_as_albedo = true
	qmesh.material = tmat

	var ps = GPUParticles3D.new()
	ps.process_material = proc
	ps.draw_pass_1 = qmesh
	ps.amount = 12
	ps.lifetime = 0.25
	ps.explosiveness = 0.0
	ps.emitting = true
	return ps


# ─── FLIGHT ──────────────────────────────────────────────────────────────────

func _begin_flight(start: Vector3, target: Vector3, duration: float, arc_height: float) -> void:
	if _is_launched:
		return
	_is_launched = true

	# Face direction of travel immediately
	_orient_to_direction(target - start)

	if arc_height > 0.001:
		_fly_arc(start, target, duration, arc_height)
	else:
		_fly_straight(start, target, duration)


func _fly_straight(start: Vector3, target: Vector3, duration: float) -> void:
	var t = create_tween()
	t.tween_method(func(p: float):
		var pos = start.lerp(target, p)
		global_position = pos
		_orient_to_direction(target - start)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(_on_impact)


func _fly_arc(start: Vector3, target: Vector3, duration: float, arc_h: float) -> void:
	# Simple parabolic arc via tween_method sampling a bezier-style quadratic curve.
	# mid_point is the apex of the arc.
	var mid = start.lerp(target, 0.5)
	mid.y += arc_h

	var t = create_tween()
	t.tween_method(func(p: float):
		# Quadratic bezier: B(t) = (1-t)^2*P0 + 2(1-t)t*P1 + t^2*P2
		var q = (1.0 - p) * (1.0 - p) * start + 2.0 * (1.0 - p) * p * mid + p * p * target
		var prev = global_position
		global_position = q
		var travel_dir = global_position - prev
		if travel_dir.length_squared() > 0.0001:
			_orient_to_direction(travel_dir)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	t.tween_callback(_on_impact)


func _orient_to_direction(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var look_dir = dir.normalized()
	# Look toward target — projectile's -Z should point toward travel direction
	var basis = Basis.looking_at(look_dir, Vector3.UP)
	global_basis = basis


# ─── IMPACT ──────────────────────────────────────────────────────────────────

func _on_impact() -> void:
	# Stop trail particles
	if is_instance_valid(_trail_particles):
		_trail_particles.emitting = false

	# Fade out glow
	if is_instance_valid(_glow_light):
		var t = create_tween()
		t.tween_property(_glow_light, "light_energy", 0.0, 0.15)

	# Hide mesh immediately
	if is_instance_valid(_mesh):
		_mesh.visible = false

	# Fire the impact callback
	if _impact_callback.is_valid():
		_impact_callback.call()

	# Schedule cleanup
	if is_instance_valid(self):
		get_tree().create_timer(CLEANUP_DELAY).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)
