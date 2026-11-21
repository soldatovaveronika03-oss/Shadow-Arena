extends Node3D

const MODEL_PATHS = [
	"res://assets/43293218-c338-4fe2-a177-32a10bffe72c.glb",
	"res://assets/bdd1f502-bdb6-4287-8d2c-7799487a4999.glb",
	"res://assets/fb414334-be07-4e6e-9570-0fcc8769768a.glb"
]

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var move_vector := Vector2.ZERO
var look_touch := -1
var last_touch := Vector2.ZERO
var yaw := 0.0
var pitch := -0.22
var info_label: Label

func _ready() -> void:
	_build_world()
	_build_player()
	_build_models()
	_build_ui()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.055, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.72, 0.85)
	env.ambient_light_energy = 0.8
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.35
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.12, 0.23, 0.16)
	ground_mat.roughness = 1.0
	ground.material_override = ground_mat
	ground.position.y = -0.08
	add_child(ground)

	for i in range(18):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.35, 1.0)
		mesh.height = mesh.radius * 1.4
		rock.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.22,0.27,0.29), Color(0.28,0.25,0.2), Color(0.16,0.25,0.19)][i % 3]
		rock.material_override = mat
		rock.position = Vector3(randf_range(-24,24), mesh.radius * 0.45, randf_range(-24,24))
		rock.scale = Vector3(randf_range(0.7,1.6), randf_range(0.7,1.8), randf_range(0.7,1.6))
		add_child(rock)

	for i in range(12):
		var trunk := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.18
		cylinder.bottom_radius = 0.3
		cylinder.height = 2.2
		trunk.mesh = cylinder
		var bark := StandardMaterial3D.new()
		bark.albedo_color = Color(0.22, 0.13, 0.08)
		trunk.material_override = bark
		var x := randf_range(-30,30)
		var z := randf_range(-30,30)
		trunk.position = Vector3(x,1.1,z)
		add_child(trunk)
		var crown := MeshInstance3D.new()
		var cone := SphereMesh.new()
		cone.radius = 1.25
		cone.height = 2.5
		crown.mesh = cone
		var leaves := StandardMaterial3D.new()
		leaves.albedo_color = Color(0.08, 0.28, 0.15)
		crown.material_override = leaves
		crown.position = Vector3(x,2.8,z)
		crown.scale = Vector3(1.0,1.2,1.0)
		add_child(crown)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1, 5)
	add_child(player)

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var body := MeshInstance3D.new()
	body.mesh = capsule
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.78, 0.82, 0.9)
	armor.metallic = 0.55
	armor.roughness = 0.3
	body.material_override = armor
	body.position.y = 0.9
	player.add_child(body)

	var chest := MeshInstance3D.new()
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.72,0.42,0.38)
	chest.mesh = chest_mesh
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.82,0.61,0.19)
	gold.metallic = 0.7
	chest.material_override = gold
	chest.position = Vector3(0,1.1,-0.02)
	player.add_child(chest)

	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.5
	player.add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.4, 6.5)
	camera.current = true
	camera_pivot.add_child(camera)

func _build_models() -> void:
	for i in range(MODEL_PATHS.size()):
		var packed = load(MODEL_PATHS[i])
		if packed == null:
			continue
		var instance = packed.instantiate()
		instance.name = "UploadedModel_" + str(i + 1)
		instance.position = Vector3((i - 1) * 7.0, 0, -8)
		instance.scale = Vector3.ONE * 1.6
		add_child(instance)
		var marker := MeshInstance3D.new()
		var ring := CylinderMesh.new()
		ring.top_radius = 1.8
		ring.bottom_radius = 1.8
		ring.height = 0.12
		marker.mesh = ring
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.72,0.53,0.18)
		ring_mat.metallic = 0.6
		marker.material_override = ring_mat
		marker.position = Vector3((i - 1) * 7.0, 0.04, -8)
		add_child(marker)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "ATLAS WILDS ARENA  •  TEST WORLD"
	title.position = Vector2(28, 20)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.95,0.82,0.48))
	layer.add_child(title)

	info_label = Label.new()
	info_label.text = "Исследуй мир • 3 загруженные 3D-модели впереди"
	info_label.position = Vector2(30, 58)
	info_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(info_label)

	_add_hold_button(layer, "▲", Vector2(105, 510), Vector2(76,76), Vector2.UP)
	_add_hold_button(layer, "▼", Vector2(105, 650), Vector2(76,60), Vector2.DOWN)
	_add_hold_button(layer, "◀", Vector2(25, 585), Vector2(70,65), Vector2.LEFT)
	_add_hold_button(layer, "▶", Vector2(190, 585), Vector2(70,65), Vector2.RIGHT)

	var action := Button.new()
	action.text = "АТАКА"
	action.position = Vector2(1040, 570)
	action.size = Vector2(170, 100)
	action.add_theme_font_size_override("font_size", 23)
	action.pressed.connect(_attack)
	layer.add_child(action)

	var hint := Label.new()
	hint.text = "Проводи пальцем по правой части экрана, чтобы вращать камеру"
	hint.position = Vector2(700, 680)
	hint.add_theme_font_size_override("font_size", 13)
	layer.add_child(hint)

func _add_hold_button(layer: CanvasLayer, caption: String, pos: Vector2, button_size: Vector2, direction: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 27)
	button.button_down.connect(func(): move_vector = direction)
	button.button_up.connect(func(): if move_vector == direction: move_vector = Vector2.ZERO)
	layer.add_child(button)

func _attack() -> void:
	info_label.text = "Удар! Боевые способности будут добавлены в следующих сборках."

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
		pitch = clamp(pitch - delta.y * 0.004, -0.75, 0.25)
		camera_pivot.rotation = Vector3(pitch, yaw, 0)
		last_touch = event.position
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
		pitch = clamp(pitch - event.relative.y * 0.004, -0.75, 0.25)
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
	player.velocity.x = direction.x * 5.0
	player.velocity.z = direction.z * 5.0
	if not player.is_on_floor():
		player.velocity.y -= 22.0 * delta
	else:
		player.velocity.y = -0.2
	player.move_and_slide()
	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
