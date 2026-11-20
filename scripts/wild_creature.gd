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
var attack_time := 0.0
var body_material: StandardMaterial3D

func _ready() -> void:
	_build_body()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.85 if is_dragon else 0.55
	shape.height = 2.3 if is_dragon else 1.35
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)

func _build_body() -> void:
	var fur := Color(0.30,0.25,0.19) if species == "Волк" else (Color(0.22,0.18,0.14) if species == "Медведь" else Color(0.30,0.12,0.10))
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = fur
	body_material.roughness = 0.9
	var body := SphereMesh.new()
	body.radius = 0.75 if not is_dragon else 1.65
	body.height = 1.4 if not is_dragon else 2.8
	_part(body,Vector3(0,1.0,0),Vector3(1.45,0.8,0.85))
	_part(SphereMesh.new(),Vector3(0,1.15,-0.85),Vector3(0.58,0.58,0.58))
	_part(ConeMesh.new(),Vector3(-0.28,1.55,-1.05),Vector3(0.22,0.48,0.22))
	_part(ConeMesh.new(),Vector3(0.28,1.55,-1.05),Vector3(0.22,0.48,0.22))
	for x in [-0.48,0.48]:
		for z in [-0.48,0.48]:
			_part(CylinderMesh.new(),Vector3(x,0.48,z),Vector3(0.22,0.65,0.22))
	if is_dragon:
		var wing := PrismMesh.new()
		_part(wing,Vector3(-1.35,2.0,0.0),Vector3(1.9,0.16,1.25))
		_part(wing,Vector3(1.35,2.0,0.0),Vector3(1.9,0.16,1.25))
		_part(ConeMesh.new(),Vector3(0,1.1,1.9),Vector3(0.38,0.38,1.8))
		_part(SphereMesh.new(),Vector3(0,1.2,-1.9),Vector3(0.72,0.55,0.9))

func _part(mesh: Mesh, pos: Vector3, scale_value: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale_value
	node.material_override = body_material
	add_child(node)

func _physics_process(delta: float) -> void:
	think_time -= delta
	attack_time = maxf(0.0,attack_time-delta)
	var direction := Vector3.ZERO
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < aggro_range:
		var diff := target.global_position-global_position
		if diff.length() > attack_range:
			direction = Vector3(diff.x,0,diff.z).normalized()
		elif attack_time <= 0.0:
			attack_time = 1.45 if not is_dragon else 2.4
			if target.has_method("take_damage"):
				target.take_damage(damage,self)
	elif think_time <= 0.0:
		think_time = randf_range(2.0,5.0)
		wander_dir = Vector3(randf_range(-1,1),0,randf_range(-1,1)).normalized()
	if direction == Vector3.ZERO and think_time > 0.0:
		direction = wander_dir * 0.35
	velocity.x = direction.x*move_speed
	velocity.z = direction.z*move_speed
	velocity.y = 0.0
	if direction.length() > 0.1:
		look_at(global_position+direction,Vector3.UP)
	move_and_slide()
	global_position.y = Wildlands.terrain_height(global_position.x,global_position.z)

func take_damage(amount: float, _source: Node = null) -> void:
	health -= amount
	body_material.albedo_color = Color(1,0.35,0.2)
	if health <= 0.0:
		queue_free()
