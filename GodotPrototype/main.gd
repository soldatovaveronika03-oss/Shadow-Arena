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
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	_build_terrain()
	_build_nature()

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
	var grass_material := StandardMaterial3D.new()
	grass_material.albedo_color = Color(0.20, 0.36, 0.19)
	grass_material.roughness = 1.0
	grass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = grass_material
	add_child(terrain)
	# Critical fix: the terrain now has a real trimesh collision surface.
	terrain.create_trimesh_collision()

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
	for i in range(360):
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
	for i in range(620):
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
	for i in range(190):
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
	for i in range(5200):
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
	player.position = Vector3(0, _terrain_height(0, 8.0) + 0.12, 8)
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
			var hero_model := packed.instantiate()
			hero_model.name = "KaironUploaded3DModel"
			visual_root.add_child(hero_model)
			_fit_model_to_height(hero_model, 2.45)
			hero_loaded = true
	if not hero_loaded:
		_add_fallback_hero(visual_root)

	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.55
	player.add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.1, 6.8)
	camera.current = true
	camera.fov = 72.0
	camera_pivot.add_child(camera)

func _fit_model_to_height(model: Node, target_height: float) -> void:
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
	# The first uploaded model is now Kairon's actual character mesh.
	# The remaining two GLBs are displayed as creatures/landmarks in the world.
	for i in range(1, MODEL_PATHS.size()):
		if not ResourceLoader.exists(MODEL_PATHS[i]):
			continue
		var packed = load(MODEL_PATHS[i]) as PackedScene
		if packed == null:
			continue
		var instance := packed.instantiate()
		instance.name = "WorldCreature_" + str(i + 1)
		var x := -13.0 if i == 1 else 13.0
		var z := -20.0
		_fit_model_to_height(instance, 3.0)
		instance.position = Vector3(x, _terrain_height(x, z), z)
		add_child(instance)

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
	info_label.text = "Кайрон • большой открытый мир • лес, трава и скалы"
	info_label.position = Vector2(30, 58)
	info_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(info_label)

	_add_hold_button(layer, "▲", Vector2(105, 510), Vector2(76, 76), Vector2.UP)
	_add_hold_button(layer, "▼", Vector2(105, 650), Vector2(76, 60), Vector2.DOWN)
	_add_hold_button(layer, "◀", Vector2(25, 585), Vector2(70, 65), Vector2.LEFT)
	_add_hold_button(layer, "▶", Vector2(190, 585), Vector2(70, 65), Vector2.RIGHT)

	var action := Button.new()
	action.text = "АТАКА"
	action.position = Vector2(1040, 570)
	action.size = Vector2(170, 100)
	action.add_theme_font_size_override("font_size", 23)
	action.pressed.connect(_attack)
	layer.add_child(action)

	var hint := Label.new()
	hint.text = "Свайп справа — вращение камеры"
	hint.position = Vector2(790, 680)
	hint.add_theme_font_size_override("font_size", 13)
	layer.add_child(hint)

func _add_hold_button(layer: CanvasLayer, caption: String, pos: Vector2, button_size: Vector2, direction: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 27)
	button.button_down.connect(_set_move.bind(direction))
	button.button_up.connect(_clear_move.bind(direction))
	layer.add_child(button)

func _set_move(direction: Vector2) -> void:
	move_vector = direction

func _clear_move(direction: Vector2) -> void:
	if move_vector == direction:
		move_vector = Vector2.ZERO

func _attack() -> void:
	info_label.text = "Кайрон атакует! Следующий этап — анимации и боевые навыки."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
			look_touch = event.index
			last_touch = event.position
		elif not event.pressed and event.index == look_touch:
			look_touch = -1
	elif event is InputEventScreenDrag and event.index == look_touch:
		var delta = event.position - last_touch
		yaw -= delta.x * 0.006
		pitch = clampf(pitch - delta.y * 0.004, -0.72, 0.20)
		camera_pivot.rotation = Vector3(pitch, yaw, 0)
		last_touch = event.position
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch - event.relative.y * 0.004, -0.72, 0.20)
		camera_pivot.rotation = Vector3(pitch, yaw, 0)

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var input_dir := move_vector
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
	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
