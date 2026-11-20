extends Node3D

const ARENA_SIZE := 34.0
const PLAYER_SPEED := 7.0
const ATTACK_RANGE := 3.0
const MAX_ENEMIES := 18

var player: CharacterBody3D
var camera: Camera3D
var enemies: Array[CharacterBody3D] = []
var health := 100
var wave := 1
var score := 0
var attack_cooldown := 0.0
var spawn_timer := 0.0
var move_vector := Vector2.ZERO
var hud: Label
var status_label: Label
var attack_button: Button
var joystick_origin := Vector2.ZERO
var joystick_touch := -1

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	_start_wave()

func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	spawn_timer -= delta
	if spawn_timer <= 0.0 and enemies.size() < mini(wave * 3 + 2, MAX_ENEMIES):
		_spawn_enemy()
		spawn_timer = maxf(0.7, 2.4 - wave * 0.12)
	_update_hud()

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_vector.length() > 0.1:
		input_dir = move_vector
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	player.velocity.x = direction.x * PLAYER_SPEED
	player.velocity.z = direction.z * PLAYER_SPEED
	if direction.length() > 0.1:
		player.rotation.y = atan2(-direction.x, -direction.z)
	player.velocity.y -= 22.0 * get_physics_process_delta_time()
	player.move_and_slide()
	_follow_camera()
	_update_enemies(get_physics_process_delta_time())

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.045, 0.075)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.8)
	environment.ambient_light_energy = 0.8
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.4
	add_child(sun)

	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ARENA_SIZE, ARENA_SIZE)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.16, 0.22)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ARENA_SIZE, 0.5, ARENA_SIZE)
	floor_shape.shape = box
	floor_shape.position.y = -0.25
	floor_body.add_child(floor_shape)

	for i in range(4):
		var wall := StaticBody3D.new()
		add_child(wall)
		var mesh_instance := MeshInstance3D.new()
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(ARENA_SIZE, 2.0, 0.7) if i < 2 else Vector3(0.7, 2.0, ARENA_SIZE)
		mesh_instance.mesh = wall_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.25, 0.38)
		mesh_instance.material_override = mat
		wall.add_child(mesh_instance)
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = wall_mesh.size
		shape_node.shape = shape
		wall.add_child(shape_node)
		if i == 0: wall.position = Vector3(0, 1, -ARENA_SIZE / 2)
		elif i == 1: wall.position = Vector3(0, 1, ARENA_SIZE / 2)
		elif i == 2: wall.position = Vector3(-ARENA_SIZE / 2, 1, 0)
		else: wall.position = Vector3(ARENA_SIZE / 2, 1, 0)

func _make_character(color: Color, radius: float, height: float) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	mesh_instance.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.25
	material.roughness = 0.45
	mesh_instance.material_override = material
	mesh_instance.position.y = height * 0.5
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position.y = height * 0.5
	body.add_child(collision)
	return body

func _build_player() -> void:
	player = _make_character(Color(0.12, 0.65, 1.0), 0.48, 1.8)
	player.name = "Hero"
	player.position = Vector3(0, 0.1, 7)
	add_child(player)
	camera = Camera3D.new()
	camera.position = Vector3(0, 8, 11)
	camera.rotation_degrees = Vector3(-32, 0, 0)
	camera.current = true
	player.add_child(camera)

func _follow_camera() -> void:
	if camera:
		camera.position = Vector3(0, 8, 11)
		camera.look_at(player.global_position + Vector3(0, 0.8, 0), Vector3.UP)

func _spawn_enemy() -> void:
	var enemy := _make_character(Color(0.9, 0.18, 0.24), 0.45, 1.65)
	enemy.name = "Enemy"
	var angle := randf() * TAU
	var distance := randf_range(10.0, 14.0)
	enemy.position = Vector3(cos(angle) * distance, 0.1, sin(angle) * distance)
	add_child(enemy)
	enemies.append(enemy)

func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var to_player := player.global_position - enemy.global_position
		to_player.y = 0
		if to_player.length() > 1.35:
			var dir := to_player.normalized()
			enemy.velocity.x = dir.x * (2.0 + wave * 0.08)
			enemy.velocity.z = dir.z * (2.0 + wave * 0.08)
			enemy.rotation.y = atan2(-dir.x, -dir.z)
		else:
			enemy.velocity.x = 0
			enemy.velocity.z = 0
			if randf() < delta * 0.65:
				health -= 5
				if health <= 0:
					_game_over()
		enemy.velocity.y -= 22.0 * delta
		enemy.move_and_slide()

func _attack() -> void:
	if attack_cooldown > 0.0 or player == null:
		return
	attack_cooldown = 0.48
	var hit_count := 0
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and player.global_position.distance_to(enemy.global_position) <= ATTACK_RANGE:
			enemies.erase(enemy)
			enemy.queue_free()
			score += 10
			hit_count += 1
	if enemies.is_empty() and hit_count == 0:
		_start_wave()

func _start_wave() -> void:
	wave += 1
	spawn_timer = 0.4

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(18, 14)
	layer.add_child(panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 26)
	panel.add_child(hud)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(status_label)

	var attack := Button.new()
	attack.text = "ATTACK"
	attack.custom_minimum_size = Vector2(130, 76)
	attack.anchor_left = 1.0
	attack.anchor_top = 1.0
	attack.anchor_right = 1.0
	attack.anchor_bottom = 1.0
	attack.position = Vector2(-155, -105)
	attack.pressed.connect(_attack)
	layer.add_child(attack)
	attack_button = attack

	var up := _make_control_button(layer, "▲", Vector2(92, -190), "move_forward")
	var down := _make_control_button(layer, "▼", Vector2(92, -76), "move_back")
	var left := _make_control_button(layer, "◀", Vector2(34, -132), "move_left")
	var right := _make_control_button(layer, "▶", Vector2(150, -132), "move_right")
	for button in [up, down, left, right]:
		button.anchor_left = 0.0
		button.anchor_top = 1.0
		button.anchor_right = 0.0
		button.anchor_bottom = 1.0

func _make_control_button(layer: CanvasLayer, caption: String, offset: Vector2, action: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(58, 58)
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.position = offset
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	layer.add_child(button)
	return button

func _update_hud() -> void:
	if hud:
		hud.text = "SHADOW ARENA    WAVE %d\nHP: %d     SCORE: %d" % [wave, health, score]
	if status_label:
		status_label.text = "Enemies: %d" % enemies.size()

func _game_over() -> void:
	health = 0
	set_physics_process(false)
	set_process(false)
	if status_label:
		status_label.text = "GAME OVER  •  SCORE: %d" % score
