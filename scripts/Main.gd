extends Node3D

const WORLD_SCALE: float = 400.0

const PlayerScript = preload("res://scripts/Player.gd")
const CreatureScript = preload("res://scripts/Creature.gd")
const HUDScript = preload("res://scripts/MobileHUD.gd")

func _ready() -> void:
    _create_environment()
    _create_terrain()
    var player := CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PlayerScript)
    add_child(player)
    player.position = Vector3(0, 1.1, 0)

    _create_creature("Grazer", Vector3(7, 0.8, -8) * WORLD_SCALE, Color(0.62, 0.72, 0.48), 1)
    _create_creature("Stalker", Vector3(-9, 0.8, -12) * WORLD_SCALE, Color(0.48, 0.52, 0.62), 2)
    _create_creature("Glider", Vector3(12, 3.2, 8) * WORLD_SCALE, Color(0.7, 0.48, 0.34), 3)

    # New wildlife models supplied for ATLAS WILDS.
    _create_creature("PolarBear", Vector3(-15, 0.9, -7) * WORLD_SCALE, Color(0.85, 0.9, 0.94), 2,
        "res://assets/Polar_Bear.glb", 0.58, 0.68, 0.55, 1.9)
    _create_creature("IceDragon", Vector3(16, 1.0, -16) * WORLD_SCALE, Color(0.55, 0.82, 0.96), 3,
        "res://assets/ATLAS_WILDS_Ice_Dragon.glb", 0.22, 1.05, 0.72, 2.1)

    var hud := CanvasLayer.new()
    hud.name = "MobileHUD"
    hud.set_script(HUDScript)
    hud.player_path = NodePath("../Player")
    add_child(hud)

func _create_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.62, 0.7)
    env.ambient_light_energy = 0.7
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

func _create_terrain() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    add_child(ground)

    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(180, 1, 180) * WORLD_SCALE
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.19, 0.34, 0.19)
    mat.roughness = 1.0
    box.material = mat
    mesh_instance.mesh = box
    ground.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    ground.add_child(collision)
    ground.position.y = -0.5

    for i in range(520):
        var angle := TAU * float(i) / 520.0
        var radius := randf_range(18.0, 75.0) * WORLD_SCALE
        var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        _make_tree(p, randf_range(0.75, 1.35))

func _make_tree(pos: Vector3, scale_factor: float) -> void:
    var tree := Node3D.new()
    tree.position = pos
    tree.scale = Vector3.ONE * scale_factor
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22
    trunk_mesh.bottom_radius = 0.35
    trunk_mesh.height = 3.2
    var trunk_mat := StandardMaterial3D.new()
    trunk_mat.albedo_color = Color(0.25, 0.16, 0.1)
    trunk_mesh.material = trunk_mat
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.6
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.55
    crown_mesh.height = 3.1
    var crown_mat := StandardMaterial3D.new()
    crown_mat.albedo_color = Color(0.12, randf_range(0.25, 0.38), 0.13)
    crown_mat.roughness = 1.0
    crown_mesh.material = crown_mat
    crown.mesh = crown_mesh
    crown.position.y = 3.6
    tree.add_child(crown)

func _create_creature(creature_name: String, pos: Vector3, tint: Color, kind: int,
        model_path: String = "", model_scale: float = 1.0, model_y_offset: float = 0.0,
        collision_radius: float = 0.5, collision_height: float = 1.6) -> void:
    var creature := CharacterBody3D.new()
    creature.name = creature_name
    creature.set_script(CreatureScript)
    creature.kind = kind
    creature.body_color = tint
    creature.model_path = model_path
    creature.model_scale = model_scale
    creature.model_y_offset = model_y_offset
    creature.collision_radius = collision_radius
    creature.collision_height = collision_height
    add_child(creature)
    creature.position = pos
