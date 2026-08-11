class_name EnvironmentManager
extends Node3D

func _ready() -> void:
	_build_room()
	_build_table()
	_setup_lighting()

func _build_room() -> void:
	# Floor
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(40.0, 1.0, 40.0)
	floor_mesh.position = Vector3(7.0, -10.0, 7.0)
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.08, 0.08, 0.1) # Very dark stone
	floor_mat.roughness = 0.9
	floor_mesh.material = floor_mat
	add_child(floor_mesh)
	
	# Background Wall
	var wall_mesh = CSGBox3D.new()
	wall_mesh.size = Vector3(40.0, 30.0, 2.0)
	wall_mesh.position = Vector3(7.0, 5.0, -15.0)
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.05, 0.05, 0.08)
	wall_mat.roughness = 1.0
	wall_mesh.material = wall_mat
	add_child(wall_mesh)
	
	# Columns
	var col_positions = [
		Vector3(-5.0, -5.0, -5.0),
		Vector3(19.0, -5.0, -5.0),
		Vector3(-5.0, -5.0, 19.0),
		Vector3(19.0, -5.0, 19.0)
	]
	
	for pos in col_positions:
		var col = CSGCylinder3D.new()
		col.radius = 1.5
		col.height = 30.0
		col.position = pos
		col.material = wall_mat
		add_child(col)

func _build_table() -> void:
	# Main Plinth
	var table = CSGBox3D.new()
	# Board is 16x16 units (8 squares * 2.0). 
	table.size = Vector3(18.0, 2.0, 18.0) 
	table.position = Vector3(7.0, -1.1, 7.0) # Slightly below Y=0
	
	var table_mat = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.1, 0.05, 0.03) # Dark warm wood/stone
	table_mat.roughness = 0.6
	table_mat.metallic = 0.2
	table.material = table_mat
	
	# Table Border/Trim
	var trim = CSGBox3D.new()
	trim.size = Vector3(18.5, 0.5, 18.5)
	trim.position = Vector3(0.0, 1.0, 0.0) # Relative to table
	var trim_mat = StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.2, 0.15, 0.05) # Gold/brass trim
	trim_mat.metallic = 0.8
	trim_mat.roughness = 0.4
	trim.material = trim_mat
	
	table.add_child(trim)
	add_child(table)

func _setup_lighting() -> void:
	# World Environment (Atmosphere)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	
	# Ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.1, 0.15)
	
	# Subtle Fog
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.02
	env.volumetric_fog_albedo = Color(0.1, 0.1, 0.15)
	
	# Glow (for magic/fire)
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.2
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Key Light (Moonlight streaming in)
	var moon = DirectionalLight3D.new()
	moon.light_color = Color(0.6, 0.7, 0.9)
	moon.light_energy = 0.8
	moon.shadow_enabled = true
	moon.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-30), 0)
	add_child(moon)
	
	# Warm local lights (Torches)
	var torch_positions = [
		Vector3(-4.0, 3.0, -4.0),
		Vector3(18.0, 3.0, -4.0)
	]
	
	for pos in torch_positions:
		var torch = OmniLight3D.new()
		torch.light_color = Color(1.0, 0.6, 0.2)
		torch.light_energy = 2.0
		torch.omni_range = 25.0
		torch.shadow_enabled = true
		torch.position = pos
		add_child(torch)
