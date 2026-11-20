extends CharacterBody3D

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var jump_velocity: float = 5.0
@export var look_sensitivity: float = 0.004
@export var third_person_distance: float = 4.2

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_touch := Vector2.ZERO
var look_finger := -1
var move_finger := -1
var last_look := Vector2.ZERO
var first_person := false
var sprinting := false
var jump_requested := false
var yaw := 0.0
var pitch := -0.12
var camera_pivot: Node3D
var camera: Camera3D
var visual: MeshInstance3D

func _ready() -> void:
    name = "Player"
    _build_player()
    _build_camera()
    add_to_group("player")

func _build_player() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    visual = MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.38
    mesh.height = 1.8
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.48, 0.72)
    mesh.material = material
    visual.mesh = mesh
    visual.position.y = 0.9
    add_child(visual)

func _build_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.55
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 75
    camera_pivot.add_child(camera)
    _update_camera()

func _physics_process(delta: float) -> void:
    var input_vec := move_touch
    if not OS.has_feature("mobile"):
        input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        if Input.is_action_just_pressed("jump"):
            jump_requested = true
        sprinting = Input.is_action_pressed("sprint")

    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    var direction := (right * input_vec.x + forward * -input_vec.y).normalized()
    var speed := sprint_speed if sprinting else walk_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif jump_requested:
        velocity.y = jump_velocity
    else:
        velocity.y = -0.1
    jump_requested = false

    move_and_slide()

    if direction.length() > 0.1:
        var target_yaw := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, 8.0 * delta)
    _update_camera()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if touch.position.x < get_viewport().get_visible_rect().size.x * 0.48 and move_finger == -1:
                move_finger = touch.index
                _set_move_from_screen(touch.position)
            elif touch.position.x >= get_viewport().get_visible_rect().size.x * 0.48 and look_finger == -1:
                look_finger = touch.index
                last_look = touch.position
        else:
            if touch.index == move_finger:
                move_finger = -1
                move_touch = Vector2.ZERO
            if touch.index == look_finger:
                look_finger = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == move_finger:
            _set_move_from_screen(drag.position)
        elif drag.index == look_finger:
            var delta := drag.position - last_look
            yaw -= delta.x * look_sensitivity
            pitch = clamp(pitch - delta.y * look_sensitivity, -0.85, 0.55)
            last_look = drag.position
    elif event is InputEventKey and event.pressed and event.keycode == KEY_V:
        toggle_camera()

func _set_move_from_screen(pos: Vector2) -> void:
    var size := get_viewport().get_visible_rect().size
    var center := Vector2(size.x * 0.22, size.y * 0.78)
    var radius := min(size.x, size.y) * 0.14
    move_touch = ((pos - center) / radius).limit_length(1.0)
    move_touch.y = -move_touch.y

func _update_camera() -> void:
    camera_pivot.rotation.y = yaw
    camera_pivot.rotation.x = pitch
    if first_person:
        camera.position = Vector3(0, 0, 0)
        visual.visible = false
    else:
        camera.position = Vector3(0, 0.25, third_person_distance)
        visual.visible = true
    camera.look_at(camera_pivot.global_position + (-camera_pivot.global_transform.basis.z * 8.0), Vector3.UP)

func toggle_camera() -> void:
    first_person = not first_person
    _update_camera()

func set_sprint(value: bool) -> void:
    sprinting = value

func request_jump() -> void:
    jump_requested = true
