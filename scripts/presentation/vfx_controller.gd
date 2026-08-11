class_name VFXController
extends Node3D

func play_impact_vfx(pos: Vector3) -> void:
	# 1. Flash Light
	var flash = OmniLight3D.new()
	flash.position = pos
	flash.light_color = Color(1.0, 0.8, 0.3)
	flash.light_energy = 5.0
	flash.omni_range = 10.0
	add_child(flash)
	
	# 2. Shockwave Ring (Torus)
	var shockwave = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 16
	shockwave.mesh = torus
	shockwave.position = pos
	
	var sw_mat = StandardMaterial3D.new()
	sw_mat.albedo_color = Color(1.0, 0.9, 0.5, 0.8)
	sw_mat.emission_enabled = true
	sw_mat.emission = Color(1.0, 0.8, 0.3)
	sw_mat.emission_energy_multiplier = 2.0
	sw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shockwave.material_override = sw_mat
	add_child(shockwave)
	
	# 3. High-Velocity Sparks
	var particles = GPUParticles3D.new()
	particles.position = pos
	
	var spark_mat = StandardMaterial3D.new()
	spark_mat.albedo_color = Color(1.0, 0.9, 0.4)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.5, 0.1)
	spark_mat.emission_energy_multiplier = 4.0
	# Align to velocity to make them look like sharp streaks instead of dots
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_mat.billboard_keep_scale = true
	
	var spark_mesh = QuadMesh.new()
	spark_mesh.size = Vector2(0.05, 0.4) # Thin and long
	spark_mesh.material = spark_mat
	particles.draw_pass_1 = spark_mesh
	
	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.direction = Vector3(0, 1, 0)
	proc_mat.spread = 180.0
	proc_mat.initial_velocity_min = 8.0
	proc_mat.initial_velocity_max = 15.0
	proc_mat.gravity = Vector3(0, -15.0, 0)
	proc_mat.scale_curve = _create_scale_curve()
	# Aligning particles to their velocity vector in Godot 4:
	proc_mat.particle_flag_align_y = true 
	
	particles.process_material = proc_mat
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	particles.amount = 20
	add_child(particles)
	
	# Animate the flash and shockwave
	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(flash, "light_energy", 0.0, 0.2)
	t.tween_property(shockwave, "scale", Vector3(4.0, 0.1, 4.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sw_mat, "albedo_color:a", 0.0, 0.3)
	
	# Cleanup everything
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(flash): flash.queue_free()
		if is_instance_valid(shockwave): shockwave.queue_free()
		if is_instance_valid(particles): particles.queue_free()
	)

func _create_scale_curve() -> CurveTexture:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var tex = CurveTexture.new()
	tex.curve = curve
	return tex
