class_name VFXController
extends Node3D

var _spark_mesh: QuadMesh
var _proc_mat: ParticleProcessMaterial
var _spark_texture: Texture2D
var _sw_mat: StandardMaterial3D
var _sw_mesh: TorusMesh

func _ready() -> void:
	_init_resources()
	_prewarm_shaders()

func _init_resources() -> void:
	# Load CC0 textures
	var tex_path = "res://assets/vfx/spark_01.png"
	if ResourceLoader.exists(tex_path):
		_spark_texture = load(tex_path)
	elif FileAccess.file_exists("res://assets/vfx/spark_01.png"):
		var img = Image.load_from_file("res://assets/vfx/spark_01.png")
		if img != null:
			_spark_texture = ImageTexture.create_from_image(img)
	
	# Cached Materials
	var spark_mat = StandardMaterial3D.new()
	if _spark_texture != null:
		spark_mat.albedo_texture = _spark_texture
	spark_mat.albedo_color = Color(1.0, 0.9, 0.4)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.6, 0.2)
	spark_mat.emission_energy_multiplier = 3.0
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_mat.billboard_keep_scale = true
	
	_spark_mesh = QuadMesh.new()
	_spark_mesh.size = Vector2(0.5, 1.0) # Larger size to show off the spark texture
	_spark_mesh.material = spark_mat
	
	_proc_mat = ParticleProcessMaterial.new()
	_proc_mat.direction = Vector3(0, 1, 0)
	_proc_mat.spread = 180.0
	_proc_mat.initial_velocity_min = 6.0
	_proc_mat.initial_velocity_max = 12.0
	_proc_mat.gravity = Vector3(0, -5.0, 0)
	_proc_mat.scale_curve = _create_scale_curve()
	_proc_mat.particle_flag_align_y = true
	
	_sw_mesh = TorusMesh.new()
	_sw_mesh.inner_radius = 0.8
	_sw_mesh.outer_radius = 1.0
	_sw_mesh.rings = 32
	_sw_mesh.ring_segments = 16
	
	_sw_mat = StandardMaterial3D.new()
	_sw_mat.albedo_color = Color(1.0, 0.9, 0.5, 0.8)
	_sw_mat.emission_enabled = true
	_sw_mat.emission = Color(1.0, 0.8, 0.3)
	_sw_mat.emission_energy_multiplier = 2.0
	_sw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_sw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _prewarm_shaders() -> void:
	# Spawn a hidden effect off-screen to force shader compilation
	var particles = GPUParticles3D.new()
	particles.position = Vector3(0, -100, 0)
	particles.process_material = _proc_mat
	particles.draw_pass_1 = _spark_mesh
	particles.emitting = true
	particles.one_shot = true
	add_child(particles)
	
	var shockwave = MeshInstance3D.new()
	shockwave.mesh = _sw_mesh
	shockwave.material_override = _sw_mat
	shockwave.position = Vector3(0, -100, 0)
	add_child(shockwave)
	
	# Cleanup
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(particles): particles.queue_free()
		if is_instance_valid(shockwave): shockwave.queue_free()
	)

func play_impact_vfx(pos: Vector3) -> void:
	var flash = OmniLight3D.new()
	flash.position = pos
	flash.light_color = Color(1.0, 0.8, 0.3)
	flash.light_energy = 5.0
	flash.omni_range = 10.0
	add_child(flash)
	
	var shockwave = MeshInstance3D.new()
	shockwave.mesh = _sw_mesh
	
	# Duplicate the material so we can tween its alpha independently
	var dynamic_sw_mat = _sw_mat.duplicate()
	shockwave.material_override = dynamic_sw_mat
	shockwave.position = pos
	add_child(shockwave)
	
	var particles = GPUParticles3D.new()
	particles.position = pos
	particles.process_material = _proc_mat
	particles.draw_pass_1 = _spark_mesh
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	particles.amount = 20
	add_child(particles)
	
	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(flash, "light_energy", 0.0, 0.2)
	t.tween_property(shockwave, "scale", Vector3(4.0, 0.1, 4.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(dynamic_sw_mat, "albedo_color:a", 0.0, 0.3)
	
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
