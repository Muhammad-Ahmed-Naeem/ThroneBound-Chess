class_name VFXController
extends Node3D

var _spark_mesh: QuadMesh
var _proc_mat: ParticleProcessMaterial

var _smoke_mesh: QuadMesh
var _smoke_proc: ParticleProcessMaterial

var _star_texture: Texture2D
var _star_mat: StandardMaterial3D

func _ready() -> void:
	_init_resources()
	_prewarm_shaders()

func _load_tex(filename: String) -> Texture2D:
	var path = "res://assets/vfx/" + filename
	if ResourceLoader.exists(path): return load(path)
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img: return ImageTexture.create_from_image(img)
	return null

func _init_resources() -> void:
	var tex_spark = _load_tex("spark_01.png")
	var tex_star = _load_tex("star_04.png")
	var tex_smoke = _load_tex("smoke_04.png")
	
	# 1. STAR CORE (The initial bright flare)
	_star_mat = StandardMaterial3D.new()
	if tex_star: _star_mat.albedo_texture = tex_star
	_star_mat.albedo_color = Color(3.0, 2.5, 2.0) # HDR White/Yellow
	_star_mat.emission_enabled = true
	_star_mat.emission = Color(1.0, 0.8, 0.5)
	_star_mat.emission_energy_multiplier = 4.0
	_star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_star_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_star_mat.disable_receive_shadows = true
	
	# 2. SPARKS (High velocity, trailing sparks)
	var spark_mat = StandardMaterial3D.new()
	if tex_spark: spark_mat.albedo_texture = tex_spark
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_mat.billboard_keep_scale = true
	spark_mat.vertex_color_use_as_albedo = true # Critical for color_ramp to work
	
	_spark_mesh = QuadMesh.new()
	_spark_mesh.size = Vector2(0.15, 0.8) # Thin, long streaks
	_spark_mesh.material = spark_mat
	
	_proc_mat = ParticleProcessMaterial.new()
	_proc_mat.direction = Vector3(0, 1, 0)
	_proc_mat.spread = 180.0
	_proc_mat.initial_velocity_min = 12.0
	_proc_mat.initial_velocity_max = 24.0
	_proc_mat.gravity = Vector3(0, -25.0, 0)
	_proc_mat.particle_flag_align_y = true
	
	# Fade from White-Hot to Deep Red to Transparent
	var spark_grad = Gradient.new()
	spark_grad.set_color(0, Color(4.0, 3.5, 2.5, 1.0)) # Super bright core
	spark_grad.add_point(0.4, Color(2.0, 0.5, 0.0, 1.0)) # Cools down to orange
	spark_grad.set_color(1, Color(1.0, 0.1, 0.0, 0.0)) # Fades to red transparency
	var spark_tex = GradientTexture1D.new()
	spark_tex.gradient = spark_grad
	_proc_mat.color_ramp = spark_tex
	
	# 3. SMOKE/DUST (Lingering impact weight)
	var smoke_mat = StandardMaterial3D.new()
	if tex_smoke: smoke_mat.albedo_texture = tex_smoke
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke_mat.vertex_color_use_as_albedo = true
	
	_smoke_mesh = QuadMesh.new()
	_smoke_mesh.size = Vector2(1.5, 1.5)
	_smoke_mesh.material = smoke_mat
	
	_smoke_proc = ParticleProcessMaterial.new()
	_smoke_proc.direction = Vector3(0, 1, 0)
	_smoke_proc.spread = 90.0
	_smoke_proc.initial_velocity_min = 1.0
	_smoke_proc.initial_velocity_max = 3.5
	_smoke_proc.gravity = Vector3(0, 0.5, 0) # Slowly rises
	_smoke_proc.scale_min = 0.5
	_smoke_proc.scale_max = 1.5
	_smoke_proc.angle_min = 0.0
	_smoke_proc.angle_max = 360.0
	
	var smoke_grad = Gradient.new()
	smoke_grad.set_color(0, Color(0.1, 0.1, 0.1, 0.6))
	smoke_grad.set_color(1, Color(0.1, 0.1, 0.1, 0.0))
	var smoke_tex = GradientTexture1D.new()
	smoke_tex.gradient = smoke_grad
	_smoke_proc.color_ramp = smoke_tex

func _prewarm_shaders() -> void:
	var sparks = GPUParticles3D.new()
	sparks.position = Vector3(0, -100, 0)
	sparks.process_material = _proc_mat
	sparks.draw_pass_1 = _spark_mesh
	sparks.emitting = true
	sparks.one_shot = true
	add_child(sparks)
	
	var smoke = GPUParticles3D.new()
	smoke.position = Vector3(0, -100, 0)
	smoke.process_material = _smoke_proc
	smoke.draw_pass_1 = _smoke_mesh
	smoke.emitting = true
	smoke.one_shot = true
	add_child(smoke)
	
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(sparks): sparks.queue_free()
		if is_instance_valid(smoke): smoke.queue_free()
	)

func play_impact_vfx(pos: Vector3) -> void:
	# 1. Dynamic Flash
	var flash = OmniLight3D.new()
	flash.position = pos
	flash.light_color = Color(1.0, 0.8, 0.4)
	flash.light_energy = 8.0
	flash.omni_range = 15.0
	add_child(flash)
	
	# 2. Core Star Burst
	var core = MeshInstance3D.new()
	var core_mesh = QuadMesh.new()
	core_mesh.size = Vector2(2.5, 2.5)
	core.mesh = core_mesh
	var dynamic_star = _star_mat.duplicate()
	core.material_override = dynamic_star
	core.position = pos
	add_child(core)
	
	# 3. High-Velocity Sparks
	var sparks = GPUParticles3D.new()
	sparks.position = pos
	sparks.process_material = _proc_mat
	sparks.draw_pass_1 = _spark_mesh
	sparks.emitting = true
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.lifetime = 0.4
	sparks.amount = 35
	add_child(sparks)
	
	# 4. Lingering Dust/Smoke
	var smoke = GPUParticles3D.new()
	smoke.position = pos
	smoke.process_material = _smoke_proc
	smoke.draw_pass_1 = _smoke_mesh
	smoke.emitting = true
	smoke.one_shot = true
	smoke.explosiveness = 0.9
	smoke.lifetime = 1.2
	smoke.amount = 12
	add_child(smoke)
	
	# Animate core flare and light
	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(flash, "light_energy", 0.0, 0.2)
	t.tween_property(core, "scale", Vector3(3.0, 3.0, 3.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(dynamic_star, "albedo_color:a", 0.0, 0.2)
	
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(flash): flash.queue_free()
		if is_instance_valid(core): core.queue_free()
		if is_instance_valid(sparks): sparks.queue_free()
		if is_instance_valid(smoke): smoke.queue_free()
	)
