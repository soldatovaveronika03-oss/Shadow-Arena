extends CharacterBody3D
class_name ArenaHero

signal health_changed(current: float, maximum: float)
signal defeated

@export var move_speed := 7.0
@export var max_health := 220.0
var health := 220.0
var attack_damage := 28.0
var attack_cooldown := 0.0
var dash_cooldown := 0.0
var skill_cooldown := 0.0
var joystick := Vector2.ZERO
var target: Node3D
var team := 0
var is_enemy := false
var ai_timer := 0.0
var arena_limit := 495.0
var body_mesh: MeshInstance3D
var health_fill: MeshInstance3D
var label: Label3D
var invulnerable := 0.0

func _ready() -> void:
	health = max_health
	_build_character()
	health_changed.emit(health, max_health)

func _build_character() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.58
	capsule.height = 1.8
	body_mesh = MeshInstance3D.new()
	body_mesh.mesh = capsule
	body_mesh.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.78, 0.92) if not is_enemy else Color(0.92, 0.19, 0.28)
	mat.metallic = 0.42
	mat.roughness = 0.28
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.22
	body_mesh.material_override = mat
	add_child(body_mesh)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	sphere.height = 0.84
	head.mesh = sphere
	head.position.y = 2.05
	head.material_override = mat
	add_child(head)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.68
	torus.outer_radius = 0.78
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	ring.position.y = 0.08
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = mat.albedo_color
	ring_mat.emission_enabled = true
	ring_mat.emission = mat.albedo_color
	ring.material_override = ring_mat
	add_child(ring)
	label = Label3D.new()
	label.text = "КАЙРОН" if not is_enemy else "ТЕНЬ"
	label.position.y = 2.85
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	var bar_bg := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(1.5, 0.12, 0.08)
	bar_bg.mesh = bar
	bar_bg.position.y = 2.55
	var bgmat := StandardMaterial3D.new()
	bgmat.albedo_color = Color(0.08,0.04,0.07)
	bar_bg.material_override = bgmat
	add_child(bar_bg)
	health_fill = MeshInstance3D.new()
	health_fill.mesh = bar
	health_fill.position = Vector3(0,2.56,0.05)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.2,0.95,0.48) if not is_enemy else Color(1.0,0.22,0.18)
	health_fill.material_override = hm
	add_child(health_fill)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown-delta)
	dash_cooldown = maxf(0.0, dash_cooldown-delta)
	skill_cooldown = maxf(0.0, skill_cooldown-delta)
	invulnerable = maxf(0.0, invulnerable-delta)
	var input_dir := joystick
	if is_enemy:
		input_dir = _enemy_direction(delta)
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if direction.length() > 0.08:
		look_at(global_position + direction, Vector3.UP)
	velocity.y = 0.0
	global_position.y = Wildlands.terrain_height(global_position.x,global_position.z)
	move_and_slide()
	global_position.x = clampf(global_position.x, -arena_limit, arena_limit)
	global_position.z = clampf(global_position.z, -arena_limit, arena_limit)
	if health_fill:
		health_fill.scale.x = maxf(0.01, health/max_health)
		health_fill.position.x = -0.75 * (1.0-health/max_health)

func _enemy_direction(delta: float) -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	ai_timer -= delta
	var diff := target.global_position - global_position
	var distance := diff.length()
	if distance > 2.6:
		return Vector2(diff.x, diff.z).normalized()
	if ai_timer <= 0.0:
		ai_timer = 0.9
		try_attack()
	return Vector2.ZERO

func try_attack() -> void:
	if attack_cooldown > 0.0 or not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) > 3.2:
		return
	attack_cooldown = 0.72
	if target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

func dash(direction: Vector2) -> void:
	if dash_cooldown > 0.0:
		return
	dash_cooldown = 3.2
	var d := Vector3(direction.x,0,direction.y)
	if d.length() < 0.1:
		d = -global_transform.basis.z
	velocity = d.normalized() * 19.0
	invulnerable = 0.22

func cast_skill() -> void:
	if skill_cooldown > 0.0:
		return
	skill_cooldown = 8.0
	for node in get_tree().get_nodes_in_group("fighters"):
		if node == self or not node is ArenaHero:
			continue
		if global_position.distance_to(node.global_position) < 6.0:
			node.take_damage(65.0, self)

func take_damage(amount: float, _source: Node = null) -> void:
	if invulnerable > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health-amount)
	health_changed.emit(health,max_health)
	if body_mesh:
		var m := body_mesh.material_override as StandardMaterial3D
		m.albedo_color = Color(1,0.85,0.85)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(body_mesh):
			m.albedo_color = Color(0.16,0.78,0.92) if not is_enemy else Color(0.92,0.19,0.28)
	if health <= 0.0:
		defeated.emit()
		queue_free()
