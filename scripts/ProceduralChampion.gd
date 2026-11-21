extends Node3D
class_name ProceduralChampion

@export var champion_index: int = 0
@export var team_color: Color = Color(0.2, 0.55, 1.0)

const PALETTES: Array[Color] = [
    Color("#b64a32"), Color("#3c91bd"), Color("#8d5bc0"), Color("#b68a32"), Color("#4b9b58")
]

func _ready() -> void:
    _build()

func _material(color: Color, metallic: float = 0.12) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = 0.48
    return m

func _sphere(label: String, pos: Vector3, size: Vector3, mat: Material) -> void:
    var mesh := SphereMesh.new()
    mesh.radial_segments = 16
    mesh.rings = 10
    mesh.material = mat
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = pos
    node.scale = size
    add_child(node)

func _capsule(label: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.material = mat
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = pos
    add_child(node)

func _cylinder(label: String, pos: Vector3, radius: float, height: float, mat: Material, tilt: float = 0.0) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.72
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.material = mat
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = pos
    node.rotation.z = tilt
    add_child(node)

func _build() -> void:
    var style: int = posmod(champion_index, PALETTES.size())
    var armor := _material(PALETTES[style])
    var trim := _material(Color("#e5c77b"), 0.55)
    var dark := _material(Color("#222633"), 0.18)
    var skin := _material(Color("#8b6a56"))
    var energy := _material(team_color, 0.3)
    # Distinct silhouette: armored torso, shoulder guards, head, limbs and feet.
    _sphere("HipArmor", Vector3(0, 0.92, 0), Vector3(0.43, 0.34, 0.32), dark)
    _capsule("Chest", Vector3(0, 1.48, 0), 0.43, 1.0, armor)
    _sphere("ChestEmblem", Vector3(0, 1.55, -0.39), Vector3(0.19, 0.23, 0.08), energy)
    _sphere("Head", Vector3(0, 2.25, -0.02), Vector3(0.36, 0.4, 0.34), skin)
    _sphere("Helmet", Vector3(0, 2.48, 0.02), Vector3(0.43, 0.22, 0.39), trim)
    _sphere("Visor", Vector3(0, 2.28, -0.31), Vector3(0.25, 0.07, 0.07), dark)
    for side in [-1.0, 1.0]:
        _sphere("ShoulderGuard", Vector3(side * 0.53, 1.82, 0), Vector3(0.3, 0.29, 0.32), trim)
        _capsule("Arm", Vector3(side * 0.57, 1.34, 0), 0.16, 0.72, armor)
        _sphere("Gauntlet", Vector3(side * 0.58, 1.02, -0.05), Vector3(0.2, 0.2, 0.2), dark)
        _capsule("Leg", Vector3(side * 0.22, 0.55, 0), 0.19, 0.72, dark)
        _sphere("Boot", Vector3(side * 0.22, 0.18, -0.1), Vector3(0.23, 0.17, 0.34), trim)
    # A unique back silhouette and weapon per champion archetype.
    if style == 0:
        _sphere("WarriorPauldron", Vector3(0, 1.95, 0.32), Vector3(0.55, 0.42, 0.2), trim)
        _cylinder("WarriorBlade", Vector3(0.9, 1.25, -0.05), 0.09, 1.55, trim, -0.22)
    elif style == 1:
        for side in [-1.0, 1.0]:
            _sphere("MageWing", Vector3(side * 0.68, 1.72, 0.42), Vector3(0.48, 0.78, 0.12), energy)
        _sphere("ArcaneOrb", Vector3(0.78, 1.35, -0.25), Vector3(0.2, 0.2, 0.2), trim)
    elif style == 2:
        _cylinder("AssassinDagger", Vector3(0.72, 1.2, -0.18), 0.055, 1.0, trim, -0.48)
        _cylinder("AssassinDagger2", Vector3(-0.72, 1.2, -0.18), 0.055, 1.0, trim, 0.48)
        _sphere("Hood", Vector3(0, 2.48, 0.12), Vector3(0.46, 0.28, 0.44), dark)
    elif style == 3:
        _sphere("MarksmanQuiver", Vector3(0, 1.65, 0.48), Vector3(0.25, 0.55, 0.2), dark)
        _cylinder("Longbow", Vector3(0.78, 1.55, 0), 0.045, 1.65, trim, 0.08)
    else:
        _sphere("GuardianShield", Vector3(-0.72, 1.45, -0.12), Vector3(0.22, 0.65, 0.48), trim)
        _sphere("GuardianCrest", Vector3(0, 2.82, 0), Vector3(0.16, 0.42, 0.16), energy)
