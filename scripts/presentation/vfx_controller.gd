class_name VFXController
extends Node3D

func play_impact_vfx(pos: Vector3) -> void:
	var particles = GPUParticles3D.new()
	particles.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.emission_energy_multiplier = 2.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = mat
	particles.draw_pass_1 = mesh
	
	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.direction = Vector3(0, 1, 0)
	proc_mat.spread = 90.0
	proc_mat.initial_velocity_min = 3.0
	proc_mat.initial_velocity_max = 6.0
	proc_mat.gravity = Vector3(0, -9.8, 0)
	proc_mat.scale_curve = _create_scale_curve()
	
	particles.process_material = proc_mat
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.6
	
	add_child(particles)
	
	# Automatically clean up
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _create_scale_curve() -> CurveTexture:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var tex = CurveTexture.new()
	tex.curve = curve
	return tex
