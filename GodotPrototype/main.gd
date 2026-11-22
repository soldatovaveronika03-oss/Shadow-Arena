extends Node3D

const MODEL_PATHS = [
	"res://assets/43293218-c338-4fe2-a177-32a10bffe72c.glb",
	"res://assets/bdd1f502-bdb6-4287-8d2c-7799487a4999.glb",
	"res://assets/fb414334-be07-4e6e-9570-0fcc8769768a.glb"
]
const HERO_MODEL_FORWARD_OFFSET := PI
const WORLD_HALF_SIZE := 220.0
const WORLD_QUALITY_PROFILE := "MEDIUM"
var terrain_cells := 112
var terrain_step := (WORLD_HALF_SIZE * 2.0) / float(terrain_cells)
var foliage_density := 1.0
var tree_density := 1.0

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var move_vector := Vector2.ZERO
var look_touch := -1
var last_touch := Vector2.ZERO
var yaw := 0.0
var pitch := -0.20
var info_label: Label
var rng := RandomNumberGenerator.new()
var joystick_touch := -1
var joystick_center := Vector2.ZERO
var joystick_radius := 76.0
var joystick_knob: Panel
var hero_visual: Node3D
var hero_visual_base_position := Vector3.ZERO
var hero_attack_timer := 0.0
var hero_jump_requested := false
var hero_run_phase := 0.0
var hero_parts: Array[Dictionary] = []
var hero_animation_players: Array[AnimationPlayer] = []
var hero_skeleton_bones: Array[Dictionary] = []
var hero_current_animation := ""
var wood_count := 0
var stone_count := 0
var fiber_count := 0
var has_shelter_kit := false
var shelter_built := false
var resource_nodes: Array[Dictionary] = []
var inventory_label: Label
var resource_hint_label: Label

func _ready() -> void:
	# Run procedural fallback posing after imported AnimationPlayers update.
	process_priority = 100
	rng.seed = 482019
	_configure_world_quality()
	_build_world()
	_build_player()
	_build_models()
	_build_ui()


func _configure_world_quality() -> void:
	# Change WORLD_QUALITY_PROFILE to HIGH, MEDIUM or LOW for device classes.
	match WORLD_QUALITY_PROFILE:
		"HIGH":
			terrain_cells = 144
			foliage_density = 1.35
			tree_density = 1.25
		"LOW":
			terrain_cells = 80
			foliage_density = 0.55
			tree_density = 0.65
		_:
			terrain_cells = 112
			foliage_density = 1.0
			tree_density = 1.0
	terrain_step = (WORLD_HALF_SIZE * 2.0) / float(terrain_cells)

func _terrain_height(x: float, z: float) -> float:
	var broad := sin(x * 0.012 + sin(z * 0.009) * 1.4) * 4.2 + cos(z * 0.016 - x * 0.006) * 3.0
	var detail := sin(x * 0.043 + z * 0.021) * 1.15 + cos(z * 0.052 - x * 0.027) * 0.82 + sin((x - z) * 0.091) * 0.32
	var distance := Vector2(x * 0.92, z * 1.04).length()
	var mountain_mask: float = smoothstep(86.0, 178.0, distance)
	var wx := x + sin(z * 0.018) * 18.0 + cos(x * 0.014) * 8.0
	var wz := z + cos(x * 0.016) * 16.0 + sin(z * 0.012) * 7.0
	var ridge_a := abs(sin(wx * 0.031 + cos(wz * 0.021) * 1.6))
	var ridge_b := abs(cos(wz * 0.027 - sin(wx * 0.019) * 1.25))
	var ridged := pow(maxf(ridge_a * ridge_b, 0.008), 0.48) * 48.0
	var peaks := pow(maxf(0.0, sin(wx * 0.047) * cos(wz * 0.039)), 1.35) * 22.0
	var mountain := ridged + peaks + sin(wx * 0.021 + wz * 0.013) * 5.0 + detail * 1.8
	var clearing := clampf(1.0 - Vector2(x, z - 8.0).length() / 48.0, 0.0, 1.0)
	var natural_height := lerpf(broad + detail, mountain, mountain_mask) * (1.0 - clearing * 0.96)
	var castle_distance := Vector2(x + 112.0, z + 92.0).length()
	var terrace_weight := 1.0 - smoothstep(29.0, 47.0, castle_distance)
	var castle_ground := lerpf(natural_height, 5.35233, terrace_weight)
	var lake_distance := Vector2((x - 86.0) * 0.82, (z + 82.0) * 1.12).length()
	var lake_basin := (1.0 - smoothstep(18.0, 38.0, lake_distance)) * 5.2
	return castle_ground - lake_basin

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.055, 0.16, 0.28)
	sky_material.sky_horizon_color = Color(0.48, 0.68, 0.78)
	sky_material.ground_bottom_color = Color(0.075, 0.105, 0.075)
	sky_material.ground_horizon_color = Color(0.42, 0.55, 0.50)
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.72
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.57, 0.69, 0.70)
	env.fog_density = 0.00115
	env.volumetric_fog_enabled = false
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "WorldSun"
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.91, 0.76)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	add_child(sun)

	_build_terrain()
	_build_water_features()
	_build_foliage_and_rocks()
	_build_generated_tree_landmarks()
	_build_resource_system()
	_build_clouds()
	var wildlife_script := load("res://wildlife_system.gd") as Script
	if wildlife_script != null:
		var wildlife := Node3D.new()
		wildlife.set_script(wildlife_script)
		wildlife.name = "LivingWildlifeAndDragon"
		add_child(wildlife)
	var landmarks_script := load("res://world_features.gd") as Script
	if landmarks_script != null:
		var landmarks := Node3D.new()
		landmarks.set_script(landmarks_script)
		landmarks.name = "WorldLandmarks"
		add_child(landmarks)

func _build_terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(terrain_cells):
		for x in range(TERRAIN_CELLS):
			var x0 := -WORLD_HALF_SIZE + float(x) * terrain_step
			var z0 := -WORLD_HALF_SIZE + float(z) * TERRAIN_STEP
			var x1 := x0 + terrain_step
			var z1 := z0 + terrain_step
			var a := Vector3(x0, _terrain_height(x0, z0), z0)
			var b := Vector3(x1, _terrain_height(x1, z0), z0)
			var c := Vector3(x0, _terrain_height(x0, z1), z1)
			var d := Vector3(x1, _terrain_height(x1, z1), z1)
			surface.add_vertex(a)
			surface.add_vertex(c)
			surface.add_vertex(b)
			surface.add_vertex(b)
			surface.add_vertex(c)
			surface.add_vertex(d)
	surface.generate_normals()
	var terrain_mesh := surface.commit()
	var terrain := MeshInstance3D.new()
	terrain.name = "SculptedOpenWorldTerrain"
	terrain.mesh = terrain_mesh
	var terrain_material := ShaderMaterial.new()
	var terrain_shader := Shader.new()
	terrain_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1.0,0.0)), f.x), mix(hash(i+vec2(0.0,1.0)), hash(i+vec2(1.0,1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = world_pos.xz * 0.12;
	float grain = noise2(p) * 0.48 + noise2(p * 2.7) * 0.31 + noise2(p * 8.2) * 0.21;
	float broad = noise2(world_pos.xz * 0.018);
	float altitude = clamp((world_pos.y + 5.0) / 76.0, 0.0, 1.0);
	float slope = 1.0 - clamp(NORMAL.y, 0.0, 1.0);
	vec3 meadow = mix(vec3(0.075,0.145,0.075), vec3(0.19,0.30,0.12), grain);
	vec3 loam = mix(vec3(0.19,0.135,0.075), vec3(0.32,0.235,0.13), grain);
	vec3 stone = mix(vec3(0.20,0.22,0.21), vec3(0.43,0.42,0.36), grain);
	vec3 alpine = mix(vec3(0.34,0.38,0.36), vec3(0.62,0.64,0.59), grain);
	float soil_mask = smoothstep(0.61,0.79,broad) * 0.72;
	float cliff_mask = smoothstep(0.22,0.62,slope);
	float high_mask = smoothstep(0.52,0.82,altitude);
	vec3 color = mix(meadow, loam, soil_mask);
	color = mix(color, stone, max(cliff_mask, high_mask * 0.68));
	color = mix(color, alpine, smoothstep(0.86,0.98,altitude) * 0.62);
	float mottling = (noise2(world_pos.xz * 0.9) - 0.5) * 0.055;
	ALBEDO = max(color + vec3(mottling), vec3(0.015));
	ROUGHNESS = mix(0.98, 0.78, cliff_mask * 0.45);
}
"""
	terrain_material.shader = terrain_shader
	terrain.material_override = terrain_material
	add_child(terrain)

	var terrain_body := StaticBody3D.new()
	terrain_body.name = "TerrainStaticCollision"
	var terrain_collision := CollisionShape3D.new()
	var terrain_shape := ConcavePolygonShape3D.new()
	terrain_shape.set_faces(terrain_mesh.get_faces())
	terrain_collision.shape = terrain_shape
	terrain_body.add_child(terrain_collision)
	add_child(terrain_body)

	# A dirt road follows the valley floor instead of floating above a flat plane.
	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in range(42):
		var z0 := -WORLD_HALF_SIZE + float(step) * 10.0
		var z1 := z0 + 10.0
		var curve0 := sin(z0 * 0.012) * 3.5
		var curve1 := sin(z1 * 0.012) * 3.5
		var left0 := Vector3(curve0 - 3.2, _terrain_height(curve0 - 3.2, z0) + 0.07, z0)
		var right0 := Vector3(curve0 + 3.2, _terrain_height(curve0 + 3.2, z0) + 0.07, z0)
		var left1 := Vector3(curve1 - 3.2, _terrain_height(curve1 - 3.2, z1) + 0.07, z1)
		var right1 := Vector3(curve1 + 3.2, _terrain_height(curve1 + 3.2, z1) + 0.07, z1)
		road_surface.add_vertex(left0)
		road_surface.add_vertex(left1)
		road_surface.add_vertex(right0)
		road_surface.add_vertex(right0)
		road_surface.add_vertex(left1)
		road_surface.add_vertex(right1)
	road_surface.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "WindingDirtRoad"
	road.mesh = road_surface.commit()
	var road_material := StandardMaterial3D.new()
	road_material.albedo_color = Color(0.34, 0.27, 0.17)
	road_material.roughness = 1.0
	road.material_override = road_material
	add_child(road)

func _build_water_features() -> void:
	var water_shader := Shader.new()
	water_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float edge = length(uv);
	if (edge > 1.0) discard;
	float wave_a = sin(UV.x * 38.0 + TIME * 1.25) * 0.018;
	float wave_b = cos(UV.y * 31.0 - TIME * 0.92) * 0.016;
	float ripple = sin((UV.x + UV.y) * 78.0 + TIME * 2.0) * 0.012;
	float fresnel = pow(1.0 - clamp(abs(NORMAL.y), 0.0, 1.0), 2.0);
	ALBEDO = mix(vec3(0.045,0.22,0.28), vec3(0.22,0.48,0.55), 0.35 + fresnel * 0.55 + wave_a + wave_b + ripple);
	METALLIC = 0.18;
	ROUGHNESS = 0.12 + edge * 0.12;
	SPECULAR = 0.85;
	ALPHA = 0.82;
}
"""
	var water_material := ShaderMaterial.new()
	water_material.shader = water_shader
	var lake_mesh := PlaneMesh.new()
	lake_mesh.size = Vector2(58.0, 42.0)
	lake_mesh.subdivide_width = 36
	lake_mesh.subdivide_depth = 28
	var lake := MeshInstance3D.new()
	lake.name = "EmeraldLake"
	lake.mesh = lake_mesh
	lake.material_override = water_material
	lake.position = Vector3(86.0, _terrain_height(86.0, -82.0) + 3.2, -82.0)
	add_child(lake)

	var river_surface := SurfaceTool.new()
	river_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(72):
		var z0 := -190.0 + float(i) * 5.25
		var z1 := z0 + 5.25
		var x0 := -68.0 + sin(z0 * 0.018) * 22.0
		var x1 := -68.0 + sin(z1 * 0.018) * 22.0
		var width0 := 2.0 + 0.55 * (0.5 + 0.5 * sin(z0 * 0.047))
		var width1 := 2.0 + 0.55 * (0.5 + 0.5 * sin(z1 * 0.047))
		var l0 := Vector3(x0 - width0, _terrain_height(x0 - width0, z0) + 0.16, z0)
		var r0 := Vector3(x0 + width0, _terrain_height(x0 + width0, z0) + 0.16, z0)
		var l1 := Vector3(x1 - width1, _terrain_height(x1 - width1, z1) + 0.16, z1)
		var r1 := Vector3(x1 + width1, _terrain_height(x1 + width1, z1) + 0.16, z1)
		river_surface.add_vertex(l0)
		river_surface.add_vertex(l1)
		river_surface.add_vertex(r0)
		river_surface.add_vertex(r0)
		river_surface.add_vertex(l1)
		river_surface.add_vertex(r1)
	river_surface.generate_normals()
	var river_shader := Shader.new()
	river_shader.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled;
void fragment() {
	float current = sin(UV.y * 80.0 - TIME * 2.4) * 0.04 + cos(UV.x * 34.0 + TIME) * 0.025;
	ALBEDO = vec3(0.075,0.31,0.39) + vec3(current);
	METALLIC = 0.16;
	ROUGHNESS = 0.16;
	ALPHA = 0.86;
}
"""
	var river_material := ShaderMaterial.new()
	river_material.shader = river_shader
	var river := MeshInstance3D.new()
	river.name = "WindingRiverWater"
	river.mesh = river_surface.commit()
	river.material_override = river_material
	add_child(river)

func _build_foliage_and_rocks() -> void:
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 1.5
	rock_mesh.radial_segments = 9
	rock_mesh.rings = 5
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.29, 0.31, 0.29)
	rock_material.roughness = 0.96
	var rock_transforms: Array[Transform3D] = []
	var shrub_mesh := SphereMesh.new()
	shrub_mesh.radius = 0.5
	shrub_mesh.height = 1.0
	shrub_mesh.radial_segments = 8
	shrub_mesh.rings = 5
	var shrub_material := StandardMaterial3D.new()
	shrub_material.albedo_color = Color(0.12, 0.26, 0.10)
	shrub_material.roughness = 0.98
	var shrub_transforms: Array[Transform3D] = []
	for i in range(int(360 * foliage_density)):
		var x := rng.randf_range(-WORLD_HALF_SIZE + 8.0, WORLD_HALF_SIZE - 8.0)
		var z := rng.randf_range(-WORLD_HALF_SIZE + 8.0, WORLD_HALF_SIZE - 8.0)
		if Vector2(x, z - 8.0).length() < 40.0 or Vector2(x + 112.0, z + 92.0).length() < 52.0 or Vector2(x - 86.0, z + 82.0).length() < 30.0:
			continue
		var ground := _terrain_height(x, z)
		var yaw_angle := rng.randf_range(0.0, TAU)
		if i % 3 == 0:
			var size := rng.randf_range(0.55, 2.1)
			var rock_basis := Basis(Vector3.UP, yaw_angle).scaled(Vector3(size, size * rng.randf_range(0.55, 0.9), size * rng.randf_range(0.7, 1.2)))
			rock_transforms.append(Transform3D(rock_basis, Vector3(x, ground + size * 0.32, z)))
		else:
			var size := rng.randf_range(0.65, 1.35)
			var shrub_basis := Basis(Vector3.UP, yaw_angle).scaled(Vector3(size, size * 0.78, size))
			shrub_transforms.append(Transform3D(shrub_basis, Vector3(x, ground + size * 0.42, z)))
	_add_multimesh(rock_mesh, rock_material, rock_transforms, "WeatheredRockScatter")
	_add_multimesh(shrub_mesh, shrub_material, shrub_transforms, "DenseUndergrowth")

	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = 0.5
	flower_mesh.height = 0.5
	flower_mesh.radial_segments = 7
	flower_mesh.rings = 4
	var flower_gold := StandardMaterial3D.new()
	flower_gold.albedo_color = Color(0.92, 0.69, 0.22)
	var flower_blue := StandardMaterial3D.new()
	flower_blue.albedo_color = Color(0.40, 0.56, 0.82)
	var flower_white := StandardMaterial3D.new()
	flower_white.albedo_color = Color(0.84, 0.83, 0.68)
	var flower_sets: Array[Array] = [[], [], []]
	for i in range(int(210 * foliage_density)):
		var fx := rng.randf_range(-WORLD_HALF_SIZE + 8.0, WORLD_HALF_SIZE - 8.0)
		var fz := rng.randf_range(-WORLD_HALF_SIZE + 8.0, WORLD_HALF_SIZE - 8.0)
		if Vector2(fx, fz - 8.0).length() < 34.0 or _terrain_height(fx, fz) > 30.0:
			continue
		var flower_scale := rng.randf_range(0.12, 0.24)
		flower_sets[i % 3].append(Transform3D(Basis().scaled(Vector3(flower_scale, flower_scale * 0.7, flower_scale)), Vector3(fx, _terrain_height(fx, fz) + rng.randf_range(0.42, 0.72), fz)))
	_add_multimesh(flower_mesh, flower_gold, flower_sets[0], "GoldenMeadowFlowers")
	_add_multimesh(flower_mesh, flower_blue, flower_sets[1], "BlueMeadowFlowers")
	_add_multimesh(flower_mesh, flower_white, flower_sets[2], "WhiteMeadowFlowers")

	var grass_mesh := CapsuleMesh.new()
	grass_mesh.radius = 0.045
	grass_mesh.height = 0.78
	grass_mesh.radial_segments = 5
	grass_mesh.rings = 3
	var grass_shader := Shader.new()
	grass_shader.code = """
shader_type spatial;
render_mode cull_disabled;
void vertex() {
	float sway = sin(TIME * 1.65 + MODEL_MATRIX[3].x * 0.17 + MODEL_MATRIX[3].z * 0.13);
	VERTEX.x += sway * 0.10 * max(VERTEX.y, 0.0);
}
void fragment() {
	float variation = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898,78.233))) * 43758.5453);
	ALBEDO = mix(vec3(0.10,0.22,0.075), vec3(0.31,0.43,0.15), variation);
	ROUGHNESS = 0.96;
}
"""
	var grass_material := ShaderMaterial.new()
	grass_material.shader = grass_shader
	var grass_transforms: Array[Transform3D] = []
	for i in range(int(1700 * foliage_density)):
		var x := rng.randf_range(-WORLD_HALF_SIZE + 5.0, WORLD_HALF_SIZE - 5.0)
		var z := rng.randf_range(-WORLD_HALF_SIZE + 5.0, WORLD_HALF_SIZE - 5.0)
		if Vector2(x, z - 8.0).length() < 32.0 or _terrain_height(x, z) > 38.0:
			continue
		var blade_scale := rng.randf_range(0.55, 1.35)
		var blade_yaw := rng.randf_range(0.0, TAU)
		grass_transforms.append(Transform3D(Basis(Vector3.UP, blade_yaw).scaled(Vector3.ONE * blade_scale), Vector3(x, _terrain_height(x, z) + 0.35 * blade_scale, z)))
	_add_multimesh(grass_mesh, grass_material, grass_transforms, "WindAnimatedGrass")
	_build_detailed_tree_forest()

func _collect_tree_mesh_data(node: Node, parent_transform: Transform3D, output: Array[Dictionary]) -> void:
	var current_transform := parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			output.append({"mesh": mesh_node.mesh, "material": mesh_node.material_override, "transform": current_transform})
	for child in node.get_children():
		_collect_tree_mesh_data(child, current_transform, output)

func _build_detailed_tree_forest() -> void:
	var species := [
		{"path": "res://assets/generated/Tree_Old_Oak.glb", "name": "OakCanopy", "count": 24, "height": 8.0},
		{"path": "res://assets/generated/Tree_Young_Birch.glb", "name": "BirchGrove", "count": 22, "height": 7.0},
		{"path": "res://assets/generated/Tree_Wide_Ancient.glb", "name": "AncientOaks", "count": 13, "height": 9.0},
		{"path": "res://assets/generated/Tree_Pine.glb", "name": "AlpinePines", "count": 32, "height": 8.5}
	]
	for entry in species:
		_add_tree_species_multimesh(String(entry.path), String(entry.name), int(float(entry.count) * tree_density), float(entry.height))

func _add_tree_species_multimesh(path: String, species_name: String, count: int, target_height: float) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Tree asset missing: " + path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var source := packed.instantiate() as Node3D
	if source == null:
		return
	_fit_model_to_height(source, target_height)
	var mesh_data: Array[Dictionary] = []
	_collect_tree_mesh_data(source, Transform3D.IDENTITY, mesh_data)
	if mesh_data.is_empty():
		source.free()
		return
	var placements: Array[Transform3D] = []
	for i in range(count):
		var accepted := false
		var x := 0.0
		var z := 0.0
		var ground := 0.0
		for attempt in range(20):
			x = rng.randf_range(-WORLD_HALF_SIZE + 12.0, WORLD_HALF_SIZE - 12.0)
			z = rng.randf_range(-WORLD_HALF_SIZE + 12.0, WORLD_HALF_SIZE - 12.0)
			ground = _terrain_height(x, z)
			if Vector2(x, z - 8.0).length() < 43.0 or Vector2(x + 112.0, z + 92.0).length() < 58.0 or Vector2(x - 86.0, z + 82.0).length() < 35.0 or ground > 48.0:
				continue
			accepted = true
			break
		if accepted:
			var yaw_angle := rng.randf_range(0.0, TAU)
			var instance_scale := rng.randf_range(0.78, 1.22)
			placements.append(Transform3D(Basis(Vector3.UP, yaw_angle).scaled(Vector3.ONE * instance_scale), Vector3(x, ground, z)))
	for mesh_index in range(mesh_data.size()):
		var record: Dictionary = mesh_data[mesh_index]
		var tree_mesh := record["mesh"] as Mesh
		if tree_mesh == null:
			continue
		var local_transform: Transform3D = record["transform"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tree_mesh
		mm.instance_count = placements.size()
		for j in range(placements.size()):
			mm.set_instance_transform(j, placements[j] * local_transform)
		var instance := MultiMeshInstance3D.new()
		instance.name = species_name + "_Part_%02d" % mesh_index
		instance.multimesh = mm
		instance.material_override = record["material"] as Material
		instance.visibility_range_end = 230.0
		add_child(instance)
	source.free()

func _build_clouds() -> void:
	# Soft, layered cloud banks at several heights and scales.
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 1.0
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(0.91, 0.95, 1.0, 0.82)
	cloud_mat.roughness = 1.0
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var clouds: Array[Transform3D] = []
	for i in range(20):
		var x := rng.randf_range(-WORLD_HALF_SIZE * 1.3, WORLD_HALF_SIZE * 1.3)
		var z := rng.randf_range(-WORLD_HALF_SIZE * 1.3, WORLD_HALF_SIZE * 1.3)
		var y := rng.randf_range(54.0, 82.0)
		var scale_x := rng.randf_range(10.0, 23.0)
		var scale_y := rng.randf_range(2.2, 4.8)
		var scale_z := rng.randf_range(7.0, 16.0)
		clouds.append(Transform3D(Basis().scaled(Vector3(scale_x, scale_y, scale_z)), Vector3(x, y, z)))
	_add_multimesh(cloud_mesh, cloud_mat, clouds, "DistantCloudBanks")

func _add_multimesh(mesh: Mesh, material: Material, transforms: Array[Transform3D], node_name: String) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	instance.material_override = material
	if node_name == "WindAnimatedGrass":
		instance.visibility_range_end = 82.0
	elif node_name == "DistantCloudBanks":
		instance.visibility_range_end = 420.0
	else:
		instance.visibility_range_end = 230.0
	add_child(instance)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Kairon"
	# Spawn safely above the ground so the capsule can settle onto the collision.
	player.position = Vector3(0, _terrain_height(0, 8.0) + 1.15, 8)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.43
	capsule_shape.height = 1.95
	collision.shape = capsule_shape
	collision.position.y = 1.0
	player.add_child(collision)

	var visual_root := Node3D.new()
	visual_root.name = "KaironVisual"
	player.add_child(visual_root)
	var hero_loaded := false
	if ResourceLoader.exists(MODEL_PATHS[0]):
		var packed = load(MODEL_PATHS[0]) as PackedScene
		if packed != null:
			var hero_model := packed.instantiate() as Node3D
			hero_model.name = "KaironUploaded3DModel"
			visual_root.add_child(hero_model)
			_fit_model_to_height(hero_model, 2.45)
			hero_visual = hero_model
			hero_visual_base_position = hero_model.position
			hero_parts = _collect_named_rig_parts(hero_model, ["arm", "leg", "wing", "tail", "hand"])
			hero_skeleton_bones = _collect_skeleton_bones(hero_model)
			hero_animation_players = _find_animation_players(hero_model)
			_play_model_animation(hero_animation_players, ["idle", "stand", "wait"])
			hero_loaded = true
	if not hero_loaded:
		_add_fallback_hero(visual_root)
		hero_visual = visual_root
		hero_visual_base_position = visual_root.position

	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.55
	player.add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.1, 6.8)
	camera.fov = 72.0
	camera_pivot.add_child(camera)
	camera.make_current()
	camera.look_at(player.global_position + Vector3(0.0, 1.0, 0.0))

func _fit_model_to_height(model: Node3D, target_height: float) -> void:
	var bounds: Array = [Vector3.ZERO, Vector3.ZERO, false]
	_collect_model_bounds(model, Transform3D.IDENTITY, bounds)
	if not bool(bounds[2]):
		model.scale = Vector3.ONE
		return
	var minimum: Vector3 = bounds[0]
	var maximum: Vector3 = bounds[1]
	var size := maximum - minimum
	if size.y < 0.01:
		model.scale = Vector3.ONE
		return
	var factor := target_height / size.y
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-(minimum.x + maximum.x) * 0.5 * factor, -minimum.y * factor, -(minimum.z + maximum.z) * 0.5 * factor)

func _collect_model_bounds(node: Node, parent_transform: Transform3D, bounds: Array) -> void:
	var current_transform := parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var aabb := mesh_instance.mesh.get_aabb()
			for ix in range(2):
				for iy in range(2):
					for iz in range(2):
						var corner := Vector3(aabb.position.x + aabb.size.x * ix, aabb.position.y + aabb.size.y * iy, aabb.position.z + aabb.size.z * iz)
						var point := current_transform * corner
						if not bool(bounds[2]):
							bounds[0] = point
							bounds[1] = point
							bounds[2] = true
						else:
							var current_min: Vector3 = bounds[0]
							var current_max: Vector3 = bounds[1]
							bounds[0] = current_min.min(point)
							bounds[1] = current_max.max(point)
	for child in node.get_children():
		_collect_model_bounds(child, current_transform, bounds)

func _add_fallback_hero(parent: Node3D) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	body.mesh = capsule
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.82, 0.84, 0.90)
	armor.metallic = 0.58
	armor.roughness = 0.28
	body.material_override = armor
	body.position.y = 0.9
	parent.add_child(body)

func _build_models() -> void:
	# Preserve the user's uploaded creature as a stationary world model.
	# Animal AI and autonomous movement are intentionally disabled.
	var creature_path := "res://assets/fb414334-be07-4e6e-9570-0fcc8769768a.glb"
	if ResourceLoader.exists(creature_path):
		var creature_scene = load(creature_path) as PackedScene
		if creature_scene != null:
			var creature := creature_scene.instantiate() as Node3D
			creature.name = "WildCreature_Static"
			_fit_model_to_height(creature, 3.2)
			creature.position = Vector3(18.0, _terrain_height(18.0, -26.0), -26.0)
			add_child(creature)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "ATLAS WILDS ARENA  •  OPEN WORLD TEST"
	title.position = Vector2(28, 20)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.98, 0.84, 0.48))
	layer.add_child(title)

	info_label = Label.new()
	info_label.text = "Кайрон • свободное исследование • строительство по сетке"
	info_label.position = Vector2(30, 58)
	info_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(info_label)

	var base := Panel.new()
	base.name = "VirtualJoystickBase"
	base.size = Vector2(164, 164)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_center = Vector2(120.0, get_viewport().get_visible_rect().size.y - 120.0)
	base.position = joystick_center - base.size * 0.5
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.08, 0.12, 0.16, 0.48)
	base_style.border_color = Color(0.85, 0.88, 0.92, 0.65)
	base_style.set_border_width_all(3)
	base_style.set_corner_radius_all(82)
	base.add_theme_stylebox_override("panel", base_style)
	layer.add_child(base)

	joystick_knob = Panel.new()
	joystick_knob.name = "VirtualJoystickKnob"
	joystick_knob.size = Vector2(72, 72)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob.position = Vector2(46, 46)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.83, 0.87, 0.93, 0.82)
	knob_style.border_color = Color(1.0, 0.88, 0.55, 0.95)
	knob_style.set_border_width_all(3)
	knob_style.set_corner_radius_all(36)
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	base.add_child(joystick_knob)

	var attack := Button.new()
	attack.text = "АТАКА"
	attack.position = Vector2(1080, 570)
	attack.size = Vector2(150, 90)
	attack.add_theme_font_size_override("font_size", 22)
	attack.pressed.connect(_attack)
	layer.add_child(attack)

	var jump := Button.new()
	jump.text = "ПРЫЖОК"
	jump.position = Vector2(930, 610)
	jump.size = Vector2(125, 65)
	jump.add_theme_font_size_override("font_size", 17)
	jump.pressed.connect(_jump)
	layer.add_child(jump)

	var hint := Label.new()
	hint.text = "Левый джойстик — движение • свайп справа — камера"
	hint.position = Vector2(350, 680)
	hint.add_theme_font_size_override("font_size", 13)
	layer.add_child(hint)

	inventory_label = Label.new()
	inventory_label.name = "ResourceInventory"
	inventory_label.position = Vector2(30, 92)
	inventory_label.add_theme_font_size_override("font_size", 17)
	layer.add_child(inventory_label)

	resource_hint_label = Label.new()
	resource_hint_label.name = "ResourceHint"
	resource_hint_label.position = Vector2(30, 122)
	resource_hint_label.add_theme_font_size_override("font_size", 15)
	layer.add_child(resource_hint_label)

	var harvest_button := Button.new()
	harvest_button.text = "СОБРАТЬ"
	harvest_button.position = Vector2(760, 540)
	harvest_button.size = Vector2(145, 62)
	harvest_button.pressed.connect(_harvest_nearest_resource)
	layer.add_child(harvest_button)

	var craft_button := Button.new()
	craft_button.text = "КРАФТ"
	craft_button.position = Vector2(760, 610)
	craft_button.size = Vector2(145, 62)
	craft_button.pressed.connect(_craft_shelter_kit)
	layer.add_child(craft_button)

	var build_button := Button.new()
	build_button.text = "ПОСТРОИТЬ"
	build_button.position = Vector2(920, 540)
	build_button.size = Vector2(145, 62)
	build_button.pressed.connect(_build_shelter)
	layer.add_child(build_button)

func _update_joystick(screen_position: Vector2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	joystick_center = Vector2(120.0, viewport_size.y - 120.0)
	var offset := screen_position - joystick_center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	move_vector = Vector2(offset.x / joystick_radius, offset.y / joystick_radius)
	if joystick_knob != null:
		joystick_knob.position = Vector2(46, 46) + offset * 0.58

func _reset_joystick() -> void:
	move_vector = Vector2.ZERO
	joystick_touch = -1
	if joystick_knob != null:
		joystick_knob.position = Vector2(46, 46)

func _attack() -> void:
	hero_attack_timer = 0.62
	_play_model_animation(hero_animation_players, ["attack", "slash", "hit", "combat"], true)
	info_label.text = "Кайрон наносит удар!"

func _jump() -> void:
	hero_jump_requested = true

func _find_animation_players(root: Node) -> Array[AnimationPlayer]:
	var players: Array[AnimationPlayer] = []
	_find_animation_players_recursive(root, players)
	return players

func _find_animation_players_recursive(node: Node, players: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		players.append(node as AnimationPlayer)
	for child in node.get_children():
		_find_animation_players_recursive(child, players)

func _play_model_animation(players: Array[AnimationPlayer], keywords: Array, restart: bool = false) -> String:
	var selected_player: AnimationPlayer = null
	var selected_name := ""
	for animation_player in players:
		if not is_instance_valid(animation_player):
			continue
		for animation_name in animation_player.get_animation_list():
			var lower_name := str(animation_name).to_lower()
			for keyword in keywords:
				if lower_name.contains(str(keyword).to_lower()):
					selected_player = animation_player
					selected_name = str(animation_name)
					break
			if selected_player != null:
				break
		if selected_player != null:
			break
	# Stop stale clips when this model has no clip for the requested state.
	# The procedural Skeleton3D fallback can then animate the rig without
	# an unrelated imported clip overwriting its bone poses.
	for animation_player in players:
		if not is_instance_valid(animation_player):
			continue
		if animation_player != selected_player and animation_player.is_playing():
			animation_player.stop()
	if selected_player == null:
		for animation_player in players:
			if is_instance_valid(animation_player) and animation_player.is_playing():
				animation_player.stop()
		return ""
	if restart or selected_player.current_animation != selected_name:
		selected_player.play(selected_name)
	return selected_name

func _collect_skeleton_bones(root: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	_collect_skeleton_bones_recursive(root, found)
	return found

func _collect_skeleton_bones_recursive(node: Node, found: Array[Dictionary]) -> void:
	if node is Skeleton3D:
		var skeleton := node as Skeleton3D
		for bone_index in range(skeleton.get_bone_count()):
			var bone_name := skeleton.get_bone_name(bone_index).to_lower()
			if bone_name.contains("arm") or bone_name.contains("hand") or bone_name.contains("leg") or bone_name.contains("thigh") or bone_name.contains("calf") or bone_name.contains("foot"):
				found.append({"skeleton": skeleton, "bone": bone_index, "name": bone_name, "base": skeleton.get_bone_pose_rotation(bone_index)})
	for child in node.get_children():
		_collect_skeleton_bones_recursive(child, found)

func _animate_skeleton_bones(parts: Array[Dictionary], phase: float, move_amount: float, attack_amount: float, jump_amount: float) -> void:
	for part in parts:
		var skeleton = part.get("skeleton")
		if not is_instance_valid(skeleton):
			continue
		var bone_index := int(part.get("bone", -1))
		if bone_index < 0:
			continue
		var bone_name := str(part.get("name", ""))
		var angle := 0.0
		if bone_name.contains("leg") or bone_name.contains("thigh") or bone_name.contains("calf") or bone_name.contains("foot"):
			angle = sin(phase * 8.0) * move_amount * 0.55 + jump_amount * 0.25
		elif bone_name.contains("arm") or bone_name.contains("hand"):
			angle = sin(phase * 8.0 + PI) * move_amount * 0.25 - jump_amount * 0.38 - attack_amount * 1.05
		var base: Quaternion = part.get("base", Quaternion.IDENTITY)
		skeleton.set_bone_pose_rotation(bone_index, base * Quaternion(Vector3.RIGHT, angle))

func _collect_named_rig_parts(root: Node, keywords: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	_collect_named_rig_parts_recursive(root, keywords, found)
	return found

func _collect_named_rig_parts_recursive(node: Node, keywords: Array, found: Array[Dictionary]) -> void:
	if node is Node3D:
		var lower_name := node.name.to_lower()
		for keyword in keywords:
			if lower_name.contains(str(keyword)):
				found.append({"node": node, "base": (node as Node3D).rotation})
				break
	for child in node.get_children():
		_collect_named_rig_parts_recursive(child, keywords, found)

func _animate_parts(parts: Array[Dictionary], phase: float, move_amount: float, attack_amount: float, flap_amount: float, jump_amount: float = 0.0) -> void:
	for part in parts:
		var node = part.get("node")
		if not is_instance_valid(node):
			continue
		var base: Vector3 = part.get("base", Vector3.ZERO)
		var node_name: String = str(node.name).to_lower()
		var animated := base
		if node_name.contains("wing"):
			animated.z += sin(phase * 2.8) * flap_amount * 0.9
		elif node_name.contains("leg"):
			animated.x += sin(phase * 8.0) * move_amount * 0.65 + jump_amount * 0.28
		elif node_name.contains("arm") or node_name.contains("hand"):
			animated.x += sin(phase * 8.0 + PI) * move_amount * 0.28 - jump_amount * 0.38 - attack_amount * 1.05
			animated.y += attack_amount * 0.35
		elif node_name.contains("tail"):
			animated.y += sin(phase * 2.0) * 0.18
		node.rotation = animated

func _input(event: InputEvent) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	joystick_center = Vector2(120, viewport_size.y - 120)
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < viewport_size.x * 0.43 and joystick_touch == -1:
				joystick_touch = event.index
				_update_joystick(event.position)
			elif event.position.x >= viewport_size.x * 0.43:
				look_touch = event.index
				last_touch = event.position
		else:
			if event.index == joystick_touch:
				_reset_joystick()
			if event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)
		elif event.index == look_touch:
			var delta = event.position - last_touch
			yaw -= delta.x * 0.006
			pitch = clampf(pitch - delta.y * 0.004, -0.72, 0.20)
			camera_pivot.rotation = Vector3(pitch, yaw, 0)
			last_touch = event.position
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch - event.relative.y * 0.004, -0.72, 0.20)
		camera_pivot.rotation = Vector3(pitch, yaw, 0)

func _process(delta: float) -> void:
	_update_resource_ui()
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.35 if player != null else false
	if moving:
		hero_run_phase += delta * 9.0
	if hero_attack_timer > 0.0:
		hero_attack_timer = maxf(0.0, hero_attack_timer - delta)
	var attack_duration := 0.62
	var attack_elapsed := clampf((attack_duration - hero_attack_timer) / attack_duration, 0.0, 1.0)
	var attack_mix := sin(attack_elapsed * PI) if hero_attack_timer > 0.0 else 0.0
	var jump_mix := 1.0 if player != null and not player.is_on_floor() else 0.0
	if hero_visual != null:
		var run_bob := sin(hero_run_phase * 2.0) * 0.055 if moving else 0.0
		var jump_bob := 0.10 if jump_mix > 0.5 else 0.0
		hero_visual.position = hero_visual_base_position + Vector3(0, run_bob + jump_bob, 0)
		hero_visual.rotation.z = (sin(hero_run_phase) * 0.035 if moving else 0.0) + attack_mix * 0.32
		# Uploaded GLB faces +Z; Godot's character forward is -Z.
		# Rotate only the visual model, never the CharacterBody3D root,
		# because the camera pivot is attached to that root.
		if moving:
			var move_direction := Vector3(player.velocity.x, 0.0, player.velocity.z).normalized()
			var desired_facing := atan2(-move_direction.x, -move_direction.z) + HERO_MODEL_FORWARD_OFFSET
			hero_visual.rotation.y = lerp_angle(hero_visual.rotation.y, desired_facing, minf(delta * 12.0, 1.0))
		_animate_parts(hero_parts, hero_run_phase, 1.0 if moving else 0.0, attack_mix, 0.0, jump_mix)
		_animate_skeleton_bones(hero_skeleton_bones, hero_run_phase, 1.0 if moving else 0.0, attack_mix, jump_mix)
		var desired_hero_animation := "attack" if hero_attack_timer > 0.0 else ("jump" if jump_mix > 0.5 else ("run" if moving else "idle"))
		if desired_hero_animation != hero_current_animation:
			var selected := ""
			if desired_hero_animation == "attack":
				selected = _play_model_animation(hero_animation_players, ["attack", "slash", "hit", "combat"], true)
			elif desired_hero_animation == "jump":
				selected = _play_model_animation(hero_animation_players, ["jump", "air", "fall"])
			elif desired_hero_animation == "run":
				selected = _play_model_animation(hero_animation_players, ["run", "walk", "move"])
			else:
				selected = _play_model_animation(hero_animation_players, ["idle", "stand", "wait"])
			hero_current_animation = desired_hero_animation

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var input_dir := move_vector
	if hero_jump_requested and player.is_on_floor():
		player.velocity.y = 8.2
		hero_current_animation = ""
	hero_jump_requested = false
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	direction = direction.rotated(Vector3.UP, yaw)
	player.velocity.x = direction.x * 6.0
	player.velocity.z = direction.z * 6.0
	if not player.is_on_floor():
		player.velocity.y -= 24.0 * delta
	else:
		player.velocity.y = -0.15
	player.move_and_slide()
	# Last-resort ground safety: never allow the hero to remain below the
	# mathematically defined terrain surface if a physics contact is missed.
	var ground_y := _terrain_height(player.global_position.x, player.global_position.z)
	if player.global_position.y < ground_y + 0.08:
		player.global_position.y = ground_y + 0.08
		if player.velocity.y < 0.0:
			player.velocity.y = 0.0
	# Keep the CharacterBody3D root unrotated so the camera never inherits
	# the hero's facing rotation. The visual model turns independently in _process().


func _build_resource_system() -> void:
	# Small, individually harvestable deposits near the starting clearing.
	var wood_positions := [Vector2(6.0, 7.0), Vector2(-7.0, 10.0), Vector2(10.0, -5.0)]
	for p in wood_positions:
		var root := Node3D.new()
		root.name = "TimberPile"
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.20
		log_mesh.bottom_radius = 0.20
		log_mesh.height = 2.0
		var log_mat := StandardMaterial3D.new()
		log_mat.albedo_color = Color(0.34, 0.20, 0.11)
		log_mat.roughness = 1.0
		for i in range(3):
			var log_piece := MeshInstance3D.new()
			log_piece.mesh = log_mesh
			log_piece.material_override = log_mat
			log_piece.rotation.z = PI * 0.5
			log_piece.position = Vector3(0.0, 0.22 + float(i % 2) * 0.30, float(i - 1) * 0.22)
			root.add_child(log_piece)
		root.position = Vector3(p.x, _terrain_height(p.x, p.y), p.y)
		add_child(root)
		resource_nodes.append({"node": root, "kind": "wood", "amount": 3})

	var rock_positions := [Vector2(8.0, 13.0), Vector2(-10.0, 3.0), Vector2(13.0, 5.0)]
	for p in rock_positions:
		var root := Node3D.new()
		root.name = "HarvestableStone"
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.85
		rock_mesh.height = 1.15
		rock.mesh = rock_mesh
		var stone_mat := StandardMaterial3D.new()
		stone_mat.albedo_color = Color(0.38, 0.41, 0.40)
		stone_mat.roughness = 1.0
		rock.material_override = stone_mat
		rock.scale = Vector3(1.25, 0.75, 1.0)
		rock.position.y = 0.45
		root.add_child(rock)
		root.position = Vector3(p.x, _terrain_height(p.x, p.y), p.y)
		add_child(root)
		resource_nodes.append({"node": root, "kind": "stone", "amount": 2})

	var fiber_positions := [Vector2(-5.0, -2.0), Vector2(5.0, -10.0)]
	for p in fiber_positions:
		var root := Node3D.new()
		root.name = "CraftingMaterialBundle"
		var bundle_mesh := BoxMesh.new()
		bundle_mesh.size = Vector3(1.0, 0.22, 0.72)
		var bundle_mat := StandardMaterial3D.new()
		bundle_mat.albedo_color = Color(0.42, 0.31, 0.19)
		bundle_mat.roughness = 1.0
		for i in range(3):
			var strip := MeshInstance3D.new()
			strip.mesh = bundle_mesh
			strip.material_override = bundle_mat
			strip.position = Vector3(0.0, 0.18 + float(i) * 0.11, 0.0)
			strip.rotation.y = float(i) * 0.35
			root.add_child(strip)
		root.position = Vector3(p.x, _terrain_height(p.x, p.y), p.y)
		add_child(root)
		resource_nodes.append({"node": root, "kind": "fiber", "amount": 2})

func _nearest_resource() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 5.5
	if player == null:
		return best
	for i in range(resource_nodes.size()):
		var entry: Dictionary = resource_nodes[i]
		var node = entry.get("node")
		if not is_instance_valid(node):
			continue
		var distance := Vector2(player.global_position.x - node.global_position.x, player.global_position.z - node.global_position.z).length()
		if distance < best_distance:
			best_distance = distance
			best = {"index": i, "entry": entry, "distance": distance}
	return best

func _update_resource_ui() -> void:
	if inventory_label == null or resource_hint_label == null:
		return
	inventory_label.text = "Дерево: %d   Камень: %d   Волокно: %d" % [wood_count, stone_count, fiber_count]
	var nearest := _nearest_resource()
	if nearest.is_empty():
		resource_hint_label.text = "Подойди к дереву, камню или кусту и нажми «СОБРАТЬ»."
	else:
		var entry: Dictionary = nearest["entry"]
		var kind: String = str(entry.get("kind", ""))
		var label := "дерево" if kind == "wood" else ("камень" if kind == "stone" else "куст")
		resource_hint_label.text = "Рядом: %s • можно добыть" % label
	if has_shelter_kit:
		resource_hint_label.text = "Комплект дома готов — нажми «ПОСТРОИТЬ»."
	elif shelter_built:
		resource_hint_label.text = "Убежище построено. Можно продолжать исследование."

func _harvest_nearest_resource() -> void:
	var nearest := _nearest_resource()
	if nearest.is_empty():
		info_label.text = "Подойди ближе к ресурсу."
		return
	var index: int = nearest["index"]
	var entry: Dictionary = nearest["entry"]
	var kind: String = str(entry.get("kind", ""))
	var amount: int = int(entry.get("amount", 1))
	if kind == "wood":
		wood_count += amount
		info_label.text = "Получено древесины: %d" % amount
	elif kind == "stone":
		stone_count += amount
		info_label.text = "Получено камня: %d" % amount
	else:
		fiber_count += amount
		info_label.text = "Получено волокна: %d" % amount
	var node = entry.get("node")
	if is_instance_valid(node):
		node.queue_free()
	resource_nodes.remove_at(index)

func _craft_shelter_kit() -> void:
	if has_shelter_kit:
		info_label.text = "Комплект уже изготовлен — построй убежище."
		return
	if shelter_built:
		info_label.text = "У тебя уже есть убежище."
		return
	if wood_count < 6 or stone_count < 3 or fiber_count < 2:
		info_label.text = "Для комплекта нужно: 6 дерева, 3 камня, 2 волокна."
		return
	wood_count -= 6
	stone_count -= 3
	fiber_count -= 2
	has_shelter_kit = true
	info_label.text = "Изготовлен комплект для строительства дома!"

func _build_shelter() -> void:
	if not has_shelter_kit:
		info_label.text = "Сначала изготовь комплект в меню «КРАФТ»."
		return
	if shelter_built:
		info_label.text = "Убежище уже построено."
		return
	var forward := -player.global_transform.basis.z
	var origin := player.global_position + forward * 6.0
	var ground := _terrain_height(origin.x, origin.z)
	var house := Node3D.new()
	house.name = "KaironWoodlandShelter"
	house.position = Vector3(origin.x, ground, origin.z)
	add_child(house)
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.34, 0.20, 0.11)
	wood_mat.roughness = 0.95
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.32, 0.34, 0.32)
	stone_mat.roughness = 1.0
	_add_house_box(house, Vector3(0, 0.15, 0), Vector3(4.4, 0.3, 4.4), stone_mat, "StoneFoundation")
	_add_house_box(house, Vector3(0, 1.55, -2.0), Vector3(4.2, 2.8, 0.22), wood_mat, "BackWall")
	_add_house_box(house, Vector3(-2.0, 1.55, 0), Vector3(0.22, 2.8, 4.2), wood_mat, "LeftWall")
	_add_house_box(house, Vector3(2.0, 1.55, 0), Vector3(0.22, 2.8, 4.2), wood_mat, "RightWall")
	_add_house_box(house, Vector3(-1.15, 1.55, 2.0), Vector3(1.9, 2.8, 0.22), wood_mat, "FrontLeftWall")
	_add_house_box(house, Vector3(1.15, 1.55, 2.0), Vector3(1.9, 2.8, 0.22), wood_mat, "FrontRightWall")
	_add_house_box(house, Vector3(0, 2.95, 0), Vector3(4.8, 0.22, 4.8), wood_mat, "FlatRoof")
	shelter_built = true
	has_shelter_kit = false
	info_label.text = "Твоё первое убежище построено!"
	resource_hint_label.text = "Убежище построено."

func _add_house_box(parent: Node3D, local_position: Vector3, box_size: Vector3, material: Material, node_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = box_size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = local_position
	mesh_instance.name = node_name
	parent.add_child(mesh_instance)
