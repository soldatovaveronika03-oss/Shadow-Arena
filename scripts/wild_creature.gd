extends CharacterBody3D
class_name WildCreature

@export var species := "Волк"
@export var health := 90.0
@export var move_speed := 4.2
@export var damage := 10.0
@export var aggro_range := 22.0
@export var attack_range := 2.7
@export var is_dragon := false

var target: Node3D
var wander_dir := Vector3.ZERO
var think_time := 0.0
var attack_cooldown := 0.0
var attack_anim_time := 0.0
var anim_clock := 0.0
var body_material: StandardMaterial3D
var visual_root: Node3D
var body_pivot: Node3D
var head_pivot: Node3D
var tail_pivot: Node3D
var leg_pivots: Array[Node3D] = []
var wing_pivots: Array[Node3D] = []
var anim_state := "idle"

func _ready() -> void:
	floor_snap_length = 1.4
	floor_max_angle = deg_to_rad(50.0)
	_build_body()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.9 if is_dragon else (0.68 if species == "Медведь" else 0.48)
	shape.height = 2.8 if is_dragon else (1.9 if species == "Медведь" else 1.35)
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	add_child(collision)

func _build_body() -> void:
	var fur := Color(0.30,0.25,0.19) if species == "Волк" else (Color(0.22,0.18,0.14) if species == "Медведь" else Color(0.30,0.12,0.10))
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = fur
	body_material.roughness = 0.9
	visual_root = Node3D.new()
	visual_root.name = "AnimatedModel"
	add_child(visual_root)

	body_pivot = Node3D.new()
	body_pivot.position.y = 0.95 if not is_dragon else 1.45
	visual_root.add_child(body_pivot)
	var body := SphereMesh.new()
	body.radius = 0.75 if not is_dragon else 1.45
	body.height = 1.4 if not is_dragon else 2.7
	_add_part(body_pivot, body, Vector3.ZERO, Vector3(1.45,0.8,0.95) if not is_dragon else Vector3(1.35,0.95,1.8))

	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0,0.15,-0.85) if not is_dragon else Vector3(0,0.15,-1.55)
	body_pivot.add_child(head_pivot)
	_add_part(head_pivot, SphereMesh.new(), Vector3(0,0,-0.12), Vector3(0.58,0.58,0.65) if not is_dragon else Vector3(0.68,0.62,0.9))
	if species == "Волк":
		_add_part(head_pivot, _cone_mesh(), Vector3(-0.28,0.42,-0.12), Vector3(0.22,0.48,0.22))
		_add_part(head_pivot, _cone_mesh(), Vector3(0.28,0.42,-0.12), Vector3(0.22,0.48,0.22))
	elif species == "Дракон":
		_add_part(head_pivot, _cone_mesh(), Vector3(-0.42,0.48,0.0), Vector3(0.28,0.72,0.28))
		_add_part(head_pivot, _cone_mesh(), Vector3(0.42,0.48,0.0), Vector3(0.28,0.72,0.28))
		_add_part(head_pivot, _cone_mesh(), Vector3(0,-0.12,-0.75), Vector3(0.36,0.34,0.85))

	tail_pivot = Node3D.new()
	tail_pivot.position = Vector3(0,0.0,0.78) if not is_dragon else Vector3(0,-0.12,1.45)
	body_pivot.add_child(tail_pivot)
	_add_part(tail_pivot, _cone_mesh(), Vector3(0,0,0.55), Vector3(0.25,0.25,0.9) if not is_dragon else Vector3(0.38,0.38,1.8))

	var leg_x := 0.48 if not is_dragon else 0.72
	var leg_z := 0.48 if not is_dragon else 0.95
	for x in [-leg_x, leg_x]:
		for z in [-leg_z, leg_z]:
			var leg_pivot := Node3D.new()
			leg_pivot.position = Vector3(x,-0.12,z)
			body_pivot.add_child(leg_pivot)
			_add_part(leg_pivot, CylinderMesh.new(), Vector3(0,-0.28,0), Vector3(0.22,0.62,0.22) if not is_dragon else Vector3(0.32,0.9,0.32))
			leg_pivots.append(leg_pivot)

	if is_dragon:
		for side in [-1.0,1.0]:
			var wing_pivot := Node3D.new()
			wing_pivot.position = Vector3(side*0.72,0.38,0.15)
			body_pivot.add_child(wing_pivot)
			var wing := PrismMesh.new()
			wing.size = Vector3(2.0,0.12,1.7)
			var wing_node := _add_part(wing_pivot, wing, Vector3(side*0.9,0,0.15), Vector3(1,1,1))
			wing_node.rotation.z = side * deg_to_rad(8.0)
			wing_pivots.append(wing_pivot)

func _cone_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.5
	mesh.height = 2.0
	return mesh

func _add_part(parent: Node3D, mesh: Mesh, pos: Vector3, scale_value: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale_value
	node.material_override = body_material
	parent.add_child(node)
	return node

func _physics_process(delta: float) -> void:
	anim_clock += delta
	attack_cooldown = maxf(0.0, attack_cooldown-delta)
	attack_anim_time = maxf(0.0, attack_anim_time-delta)
	think_time -= delta
	var direction := Vector3.ZERO
	var chasing := false
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < aggro_range:
		var diff := target.global_position-global_position
		diff.y = 0.0
		if diff.length() > attack_range:
			direction = diff.normalized()
			chasing = true
		elif attack_cooldown <= 0.0:
			attack_cooldown = 1.45 if not is_dragon else 2.4
			attack_anim_time = 0.48
			if target.has_method("take_damage"):
				target.take_damage(damage,self)
	elif think_time <= 0.0:
		think_time = randf_range(2.0,5.0)
		wander_dir = Vector3(randf_range(-1,1),0,randf_range(-1,1)).normalized()

	if direction == Vector3.ZERO and think_time > 0.0 and not is_instance_valid(target):
		direction = wander_dir * 0.35
	elif direction == Vector3.ZERO and think_time > 0.0 and not chasing and attack_anim_time <= 0.0:
		direction = wander_dir * 0.35

	var moving := direction.length() > 0.08
	if attack_anim_time > 0.0:
		anim_state = "attack"
	elif moving:
		anim_state = "walk"
	else:
		anim_state = "idle"

	var acceleration := 13.0 if moving else 18.0
	velocity.x = move_toward(velocity.x, direction.x*move_speed, acceleration*delta)
	velocity.z = move_toward(velocity.z, direction.z*move_speed, acceleration*delta)
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5
	if moving:
		var face := Vector3(direction.x,0,direction.z)
		if face.length() > 0.01:
			look_at(global_position+face,Vector3.UP)
	move_and_slide()
	_update_animation(delta, moving)

func _update_animation(delta: float, moving: bool) -> void:
	if not is_instance_valid(body_pivot):
		return
	var gait_speed := 10.0 if species == "Волк" else (6.0 if species == "Медведь" else 8.0)
	var gait := sin(anim_clock*gait_speed)
	var blend := 1.0 if moving else 0.0
	var idle_breath := sin(anim_clock*2.2)*0.035
	body_pivot.position.y = (1.45 if is_dragon else 0.95) + idle_breath + absf(gait)*0.08*blend
	body_pivot.rotation.x = 0.0
	head_pivot.rotation.x = 0.0
	tail_pivot.rotation.y = sin(anim_clock*2.5)*0.18
	for i in range(leg_pivots.size()):
		var phase := gait if i%2==0 else -gait
		leg_pivots[i].rotation.x = phase*0.48*blend
	if is_dragon:
		for i in range(wing_pivots.size()):
			var side := -1.0 if i == 0 else 1.0
			wing_pivots[i].rotation.z = side*(sin(anim_clock*7.0)*0.48 if moving else sin(anim_clock*2.0)*0.12)
	if anim_state == "attack":
		var attack_blend := clampf(attack_anim_time/0.48,0.0,1.0)
		body_pivot.rotation.x = -0.18*attack_blend
		head_pivot.rotation.x = -0.5*attack_blend
		tail_pivot.rotation.y = 0.35*attack_blend
		if is_dragon:
			for wing in wing_pivots:
				wing.rotation.z *= 1.35
	elif anim_state == "idle":
		head_pivot.rotation.x = sin(anim_clock*1.4)*0.035
	else:
		head_pivot.rotation.x = -0.06*absf(gait)
		if species == "Медведь":
			body_pivot.rotation.z = sin(anim_clock*gait_speed)*0.035
		else:
			body_pivot.rotation.z = 0.0

func take_damage(amount: float, _source: Node = null) -> void:
	health -= amount
	body_material.albedo_color = Color(1,0.35,0.2)
	if health <= 0.0:
		queue_free()
