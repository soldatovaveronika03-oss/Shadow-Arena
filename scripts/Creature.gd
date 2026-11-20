extends CharacterBody3D

@export var kind: int = 1 # 1 grazer, 2 stalker, 3 glider prototype
@export var body_color: Color = Color(0.5, 0.7, 0.4)
@export var move_speed: float = 1.8
@export var detection_range: float = 12.0
@export var flee_range: float = 5.0

var home := Vector3.ZERO
var destination := Vector3.ZERO
var pause_time := 0.0
var player: Node3D

func _ready() -> void:
    home = global_position
    _make_placeholder_model()
    _pick_destination()
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if player == null:
        player = get_tree().get_first_node_in_group("player")

    var target := destination
    if player != null:
        var distance := global_position.distance_to(player.global_position)
        if distance < flee_range and kind == 1:
            target = global_position + (global_position - player.global_position).normalized() * 8.0
        elif distance < detection_range and kind == 2:
            target = player.global_position
        elif distance < detection_range and kind == 3:
            target = player.global_position + Vector3.UP * 2.0

    var flat := target - global_position
    flat.y = 0
    if flat.length() > 0.6:
        velocity.x = flat.normalized().x * move_speed
        velocity.z = flat.normalized().z * move_speed
        rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), delta * 3.0)
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed * delta * 2)
        velocity.z = move_toward(velocity.z, 0, move_speed * delta * 2)
        pause_time -= delta
        if pause_time <= 0:
            _pick_destination()

    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = -0.1
    move_and_slide()

func _pick_destination() -> void:
    var offset := Vector2(randf_range(-12, 12), randf_range(-12, 12))
    destination = home + Vector3(offset.x, 0, offset.y)
    pause_time = randf_range(1.5, 4.0)

func _make_placeholder_model() -> void:
    var shape := CapsuleShape3D.new()
    shape.radius = 0.55 if kind == 1 else 0.42
    shape.height = 1.5 if kind == 1 else 1.2
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = shape.height * 0.5
    add_child(collision)

    var body := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.65 if kind == 1 else 0.48
    mesh.height = 1.3 if kind == 1 else 1.0
    var mat := StandardMaterial3D.new()
    mat.albedo_color = body_color
    mat.roughness = 0.82
    mesh.material = mat
    body.mesh = mesh
    body.position.y = 0.85
    body.scale = Vector3(1.0, 0.85, 1.35)
    add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.28
    head_mesh.height = 0.56
    head_mesh.material = mat
    head.mesh = head_mesh
    head.position = Vector3(0, 1.15, -0.65)
    add_child(head)
