extends Node3D

const MODEL_PATHS = [
	"res://assets/43293218-c338-4fe2-a177-32a10bffe72c.glb",
	"res://assets/bdd1f502-bdb6-4287-8d2c-7799487a4999.glb",
	"res://assets/fb414334-be07-4e6e-9570-0fcc8769768a.glb"
]
const WORLD_HALF_SIZE := 220.0
const TERRAIN_CELLS := 64
const TERRAIN_STEP := (WORLD_HALF_SIZE * 2.0) / float(TERRAIN_CELLS)

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
	rng.seed = 482019
	_build_world()
	_build_player()
	_build_models()
	_build_ui()

func _terrain_height(x: float, z: float) -> float:
	# Wide, gently rolling terrain; the starting clearing remains almost flat.
	var hills := sin(x * 0.021) * 2.1 + cos(z * 0.018) * 1.7
	hills += sin((x + z) * 0.012) * 1.2
	var clearing := clampf(1.0 - Vector2(x, z - 8.0).length() / 34.0, 0.0, 1.0)
	return hills * (1.0 - clearing * 0.88)

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.48, 0.68, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.80, 0.91)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.volumetric_fog_enabled = false
	# Volumetric fog is unsupported by the Android GL Compatibility renderer.
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	_build_terrain()
	_build_nature()
	_build_resource_system()
	_build_clouds()

func _build_terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(TERRAIN_CELLS):
		for x in range(TERRAIN_CELLS):
			var x0 := -WORLD_HALF_SIZE + float(x) * TERRAIN_STEP
			var z0 := -WORLD_HALF_SIZE + float(z) * TERRAIN_STEP
			var x1 := x0 + TERRAIN_STEP
			var z1 := z0 + TERRAIN_STEP
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
	terrain.name = "LargeCollidableTerrain"
	terrain.mesh = terrain_mesh
	var grass_material := ShaderMaterial.new()
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
	return mix(mix(hash(i), hash(i+vec2(1.0,0.0)), f.x),
		mix(hash(i+vec2(0.0,1.0)), hash(i+vec2(1.0,1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = world_pos.xz * 0.075;
	float n = noise2(p) * 0.55 + noise2(p * 3.7) * 0.30 + noise2(p * 11.0) * 0.15;
	float patches = noise2(world_pos.xz * 0.018);
	vec3 grass = mix(vec3(0.075,0.17,0.075), vec3(0.22,0.34,0.12), n);
	vec3 earth = vec3(0.27,0.22,0.14);
	vec3 stone = vec3(0.30,0.31,0.29);
	float dirt_mask = smoothstep(0.66,0.82, patches);
	float rock_mask = smoothstep(0.77,0.92, noise2(world_pos.xz * 0.035 + 17.0));
	vec3 col = mix(grass, earth, dirt_mask * 0.72);
	col = mix(col, stone, rock_mask * 0.28);
	ALBEDO = col;
	ROUGHNESS = 0.96;
}
"""
	grass_material.shader = terrain_shader
	terrain.material_override = grass_material
	add_child(terrain)
	# Explicit static concave collision, built from the exact visible terrain triangles.
	# This avoids relying on an automatically generated collision child.
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "TerrainStaticCollision"
	var terrain_collision := CollisionShape3D.new()
	var terrain_shape := ConcavePolygonShape3D.new()
	terrain_shape.set_faces(terrain_mesh.get_faces())
	terrain_collision.shape = terrain_shape
	terrain_body.add_child(terrain_collision)
	add_child(terrain_body)

	# A broad, readable dirt trail through the starting region.
	var path_mesh := BoxMesh.new()
	path_mesh.size = Vector3(10.0, 0.10, 170.0)
	var trail := MeshInstance3D.new()
	trail.mesh = path_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(0.34, 0.28, 0.19)
	trail_mat.roughness = 1.0
	trail.material_override = trail_mat
	trail.position = Vector3(0, 0.10, -42)
	add_child(trail)

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

func _build_nature() -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 5.2
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.24, 0.14, 0.08)
	bark_mat.roughness = 1.0

	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 2.35
	canopy_mesh.height = 4.7
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.10, 0.30, 0.14)
	leaf_mat.roughness = 1.0
	var leaf_light_mat := StandardMaterial3D.new()
	leaf_light_mat.albedo_color = Color(0.18, 0.39, 0.17)
	leaf_light_mat.roughness = 1.0

	var trunk_transforms: Array[Transform3D] = []
	var canopy_transforms: Array[Transform3D] = []
	for i in range(180):
		var x := rng.randf_range(-WORLD_HALF_SIZE + 12.0, WORLD_HALF_SIZE - 12.0)
		var z := rng.randf_range(-WORLD_HALF_SIZE + 12.0, WORLD_HALF_SIZE - 12.0)
		if Vector2(x, z - 8.0).length() < 20.0:
			continue
		if absf(x) < 8.0 and z > -130.0 and z < 55.0:
			continue
		var ground_y := _terrain_height(x, z)
		var height := rng.randf_range(4.4, 7.2)
		var width := rng.randf_range(0.78, 1.35)
		var basis := Basis().scaled(Vector3(width, height / 5.2, width))
		trunk_transforms.append(Transform3D(basis, Vector3(x, ground_y + height * 0.5, z)))
		var crown_scale := rng.randf_range(0.85, 1.35)
		var crown_basis := Basis().scaled(Vector3(crown_scale, crown_scale, crown_scale))
		canopy_transforms.append(Transform3D(crown_basis, Vector3(x, ground_y + height * 0.78, z)))
	_add_multimesh(trunk_mesh, bark_mat, trunk_transforms, "ForestTreeTrunks")
	_add_multimesh(canopy_mesh, leaf_mat, canopy_transforms, "ForestCanopies")

	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 0.85
	bush_mesh.height = 1.35
	var bush_mat := StandardMaterial3D.new()
	bush_mat.albedo_color = Color(0.15, 0.34, 0.13)
	bush_mat.roughness = 1.0
	var bushes: Array[Transform3D] = []
	for i in range(280):
		var x := rng.randf_range(-WORLD_HALF_SIZE, WORLD_HALF_SIZE)
		var z := rng.randf_range(-WORLD_HALF_SIZE, WORLD_HALF_SIZE)
		if Vector2(x, z - 8.0).length() < 13.0:
			continue
		if absf(x) < 6.0 and z > -125.0 and z < 45.0:
			continue
		var s := rng.randf_range(0.65, 1.5)
		bushes.append(Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(x, _terrain_height(x, z) + 0.48 * s, z)))
	_add_multimesh(bush_mesh, bush_mat, bushes, "ForestBushes")

	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 1.4
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.34, 0.36, 0.33)
	rock_mat.roughness = 1.0
	var rocks: Array[Transform3D] = []
	for i in range(100):
		var x := rng.randf_range(-WORLD_HALF_SIZE, WORLD_HALF_SIZE)
		var z := rng.randf_range(-WORLD_HALF_SIZE, WORLD_HALF_SIZE)
		if Vector2(x, z - 8.0).length() < 12.0:
			continue
		var s := rng.randf_range(0.45, 2.0)
		rocks.append(Transform3D(Basis().scaled(Vector3(s * 1.3, s * 0.75, s)), Vector3(x, _terrain_height(x, z) + s * 0.35, z)))
	_add_multimesh(rock_mesh, rock_mat, rocks, "ScatteredRocks")

	var blade_mesh := CylinderMesh.new()
	blade_mesh.top_radius = 0.015
	blade_mesh.bottom_radius = 0.07
	blade_mesh.height = 0.55
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.34, 0.53, 0.22)
	blade_mat.roughness = 1.0
	var grass_transforms: Array[Transform3D] = []
	for i in range(1400):
		var x := rng.randf_range(-WORLD_HALF_SIZE, WORLD_HALF_SIZE)
		var z := rng.randf_range(-WORLD_HALF_SIZE, WORLD_HALF_SIZE)
		if Vector2(x, z - 8.0).length() < 11.0:
			continue
		if absf(x) < 5.5 and z > -125.0 and z < 45.0:
			continue
		var s := rng.randf_range(0.55, 1.35)
		var rot := rng.randf_range(0.0, TAU)
		var basis := Basis(Vector3.UP, rot).scaled(Vector3(s, s, s))
		grass_transforms.append(Transform3D(basis, Vector3(x, _terrain_height(x, z) + 0.18, z)))
	_add_multimesh(blade_mesh, blade_mat, grass_transforms, "GrassField")

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
	# Preserve the user's original uploaded castle model.
	var castle_path := "res://assets/b92be73b-399b-4f3c-a238-6124bf7f379d.glb"
	if ResourceLoader.exists(castle_path):
		var castle_scene = load(castle_path) as PackedScene
		if castle_scene != null:
			var castle := castle_scene.instantiate() as Node3D
			castle.name = "GreatCastle"
			castle.scale = Vector3.ONE * 350.0
			castle.position = Vector3(0.0, _terrain_height(0.0, -155.0), -155.0)
			add_child(castle)

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
	info_label.text = "Кайрон • открытый мир • существа с искусственным интеллектом"
	info_label.position = Vector2(30, 58)
	info_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(info_label)

	var base := Panel.new()
	base.name = "VirtualJoystickBase"
	base.size = Vector2(164, 164)
	base.position = Vector2(38, 520)
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
	hero_attack_timer = 0.72
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
	for animation_player in players:
		if not is_instance_valid(animation_player):
			continue
		var animation_names := animation_player.get_animation_list()
		for keyword in keywords:
			for animation_name in animation_names:
				if str(animation_name).to_lower().contains(str(keyword)):
					if restart or animation_player.current_animation != animation_name:
						animation_player.play(animation_name)
					return str(animation_name)
	return ""

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

func _animate_parts(parts: Array[Dictionary], phase: float, move_amount: float, attack_amount: float, flap_amount: float) -> void:
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
			animated.x += sin(phase * 8.0) * move_amount * 0.65
		elif node_name.contains("arm") or node_name.contains("hand"):
			animated.x += sin(phase * 8.0 + PI) * move_amount * 0.28
			animated.y += attack_amount * 1.1
		elif node_name.contains("tail"):
			animated.y += sin(phase * 2.0) * 0.18
		node.rotation = animated

func _unhandled_input(event: InputEvent) -> void:
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
	var attack_mix := sin((0.42 - hero_attack_timer) / 0.42 * PI) if hero_attack_timer > 0.0 else 0.0
	if hero_visual != null:
		hero_visual.position = hero_visual_base_position + Vector3(0, sin(hero_run_phase * 2.0) * 0.055 if moving else 0.0, 0)
		hero_visual.rotation.z = (sin(hero_run_phase) * 0.035 if moving else 0.0) + attack_mix * 0.22
		_animate_parts(hero_parts, hero_run_phase, 1.0 if moving else 0.0, attack_mix, 0.0)
		var desired_hero_animation := "attack" if hero_attack_timer > 0.0 else ("run" if moving else "idle")
		if desired_hero_animation != hero_current_animation:
			var selected := ""
			if desired_hero_animation == "attack":
				selected = _play_model_animation(hero_animation_players, ["attack", "slash", "hit", "combat"], true)
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
	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)


func _build_resource_system() -> void:
	# Small, individually harvestable deposits near the starting clearing.
	var tree_positions := [Vector2(6.0, 7.0), Vector2(-7.0, 10.0), Vector2(10.0, -5.0)]
	for p in tree_positions:
		var root := Node3D.new()
		root.name = "HarvestableTree"
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.22
		trunk_mesh.bottom_radius = 0.34
		trunk_mesh.height = 2.8
		trunk.mesh = trunk_mesh
		var bark := StandardMaterial3D.new()
		bark.albedo_color = Color(0.30, 0.17, 0.09)
		trunk.material_override = bark
		trunk.position.y = 1.4
		root.add_child(trunk)
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 1.15
		crown_mesh.height = 2.0
		crown.mesh = crown_mesh
		var leaves := StandardMaterial3D.new()
		leaves.albedo_color = Color(0.12, 0.36, 0.14)
		crown.material_override = leaves
		crown.position.y = 3.0
		root.add_child(crown)
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

	var bush_positions := [Vector2(-5.0, -2.0), Vector2(5.0, -10.0)]
	for p in bush_positions:
		var root := Node3D.new()
		root.name = "HarvestableFiberBush"
		var bush := MeshInstance3D.new()
		var bush_mesh := SphereMesh.new()
		bush_mesh.radius = 0.72
		bush_mesh.height = 1.0
		bush.mesh = bush_mesh
		var bush_mat := StandardMaterial3D.new()
		bush_mat.albedo_color = Color(0.18, 0.42, 0.16)
		bush.material_override = bush_mat
		bush.position.y = 0.45
		root.add_child(bush)
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
