extends CharacterBody3D
class_name ArenaUnit

@export var team: int = 0
@export var is_player: bool = false
@export var max_health: float = 520.0
@export var attack_damage: float = 48.0
@export var move_speed: float = 5.2

var health: float = 520.0
var attack_range: float = 2.4
var attack_cooldown: float = 0.0
var respawn_timer: float = 0.0
var destination: Vector3 = Vector3.ZERO
var target: Node3D
var arena

func _ready() -> void:
    health = max_health
    _build_body()

func _physics_process(delta: float) -> void:
    if health <= 0.0:
        respawn_timer -= delta
        if respawn_timer <= 0.0:
            health = max_health
            visible = true
            collision_layer = 1
            collision_mask = 1
            global_position = Vector3(-34.0 if team == 0 else 34.0, 0.0, 0.0)
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    if is_player:
        _player_move(delta)
    else:
        _bot_move(delta)

func _player_move(delta: float) -> void:
    var input_vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_vector.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_vector.y += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_vector.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_vector.x += 1.0
    if arena != null:
        input_vector = arena.move_input if arena.move_input.length() > 0.08 else input_vector
    var direction := Vector3(input_vector.x, 0.0, input_vector.y).limit_length(1.0)
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    move_and_slide()
    if direction.length() > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 9.0)

func _bot_move(delta: float) -> void:
    if not is_instance_valid(target) or (target is ArenaUnit and target.health <= 0.0):
        target = _find_enemy()
    if not is_instance_valid(target):
        velocity = Vector3.ZERO
        return
    var offset := target.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    if distance > attack_range:
        var direction := offset.normalized()
        velocity.x = direction.x * move_speed * 0.72
        velocity.z = direction.z * move_speed * 0.72
        move_and_slide()
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 5.0)
    else:
        velocity = Vector3.ZERO
        if attack_cooldown <= 0.0 and arena != null:
            attack_cooldown = 1.35
            arena.apply_damage(target, attack_damage)

func _find_enemy() -> Node3D:
    if arena == null:
        return null
    var best: Node3D
    var best_distance := 999999.0
    for candidate in arena.units:
        if not is_instance_valid(candidate) or candidate == self or candidate.team == team or candidate.health <= 0.0:
            continue
        var d := global_position.distance_squared_to(candidate.global_position)
        if d < best_distance:
            best_distance = d
            best = candidate
    return best

func take_damage(amount: float) -> void:
    if health <= 0.0:
        return
    health -= amount
    if health <= 0.0:
        health = 0.0
        visible = false
        collision_layer = 0
        collision_mask = 0
        respawn_timer = 7.0
        if arena != null:
            arena.on_unit_killed(self)

func _build_body() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.58 if is_player else 0.48
    capsule.height = 1.9
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position.y = 0.95
    add_child(collision)
    if is_player:
        var dragon_script = load("res://scripts/ProceduralDragon.gd")
        var dragon = Node3D.new()
        dragon.set_script(dragon_script)
        dragon.dragon_index = 0
        dragon.body_scale = 0.52
        dragon.position.y = 0.0
        add_child(dragon)
    elif not name.begins_with("Minion_"):
        var champion := Node3D.new()
        champion.set_script(load("res://scripts/ProceduralChampion.gd"))
        var hero_number := 0
        var parts := name.split("_")
        if parts.size() > 1:
            hero_number = int(parts[1])
        champion.set("champion_index", posmod(hero_number + team * 2, 5))
        champion.set("team_color", Color(0.22, 0.58, 0.92) if team == 0 else Color(0.92, 0.26, 0.2))
        add_child(champion)
    else:
        var body := MeshInstance3D.new()
        var mesh := CapsuleMesh.new()
        mesh.radius = 0.34
        mesh.height = 1.25
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.22, 0.58, 0.92) if team == 0 else Color(0.86, 0.24, 0.22)
        material.roughness = 0.68
        mesh.material = material
        body.mesh = mesh
        body.position.y = 0.65
        add_child(body)
