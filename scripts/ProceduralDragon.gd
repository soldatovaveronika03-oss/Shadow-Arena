extends Node3D
class_name ProceduralDragon

# Hand-built, runtime-generated low-poly dragon meshes for Godot 4.
# No external model generator or downloaded mesh is used.

@export var dragon_index: int = 0
@export var body_scale: float = 1.0

const PALETTES: Array[Dictionary] = [
    {"name":"Ancient Fire","body":Color("#76251f"),"belly":Color("#d18a45"),"wing":Color("#321c20"),"spike":Color("#f3a34c"),"eye":Color("#ffe36a")},
    {"name":"Frost","body":Color("#6daecb"),"belly":Color("#d7f5fa"),"wing":Color("#b4e6f3"),"spike":Color("#e8ffff"),"eye":Color("#55f4ff")},
    {"name":"Night","body":Color("#242638"),"belly":Color("#55516b"),"wing":Color("#11131f"),"spike":Color("#777eaa"),"eye":Color("#d94cff")},
    {"name":"Gold","body":Color("#b98725"),"belly":Color("#f2d77b"),"wing":Color("#76501d"),"spike":Color("#ffe7a0"),"eye":Color("#fff2ad")},
    {"name":"Forest","body":Color("#426b39"),"belly":Color("#9aab5b"),"wing":Color("#24472c"),"spike":Color("#a2c66a"),"eye":Color("#d5f47b")},
    {"name":"Storm","body":Color("#344f83"),"belly":Color("#8ba9cf"),"wing":Color("#202f55"),"spike":Color("#72d9ff"),"eye":Color("#8df5ff")},
    {"name":"Venom","body":Color("#684080"),"belly":Color("#b18b9e"),"wing":Color("#352044"),"spike":Color("#c4f05b"),"eye":Color("#caff47")},
    {"name":"Stone","body":Color("#686b70"),"belly":Color("#aaa69a"),"wing":Color("#41464d"),"spike":Color("#c1bba7"),"eye":Color("#ffb75c")},
    {"name":"Ash","body":Color("#454044"),"belly":Color("#a54c2e"),"wing":Color("#241d20"),"spike":Color("#ff6b36"),"eye":Color("#ff8b38")},
    {"name":"Royal","body":Color("#54356f"),"belly":Color("#d1b4dc"),"wing":Color("#281b3d"),"spike":Color("#e5c7ff"),"eye":Color("#fff1d0")}
]

var palette: Dictionary

func _ready() -> void:
    palette = PALETTES[posmod(dragon_index, PALETTES.size())]
    _build_dragon()

func _mat(color: Color, metallic: float = 0.0, rough: float = 0.72) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = rough
    return m

func _part(parent: Node3D, mesh: Mesh, pos: Vector3, scale: Vector3, material: Material, label: String) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = pos
    node.scale = scale
    if mesh is SphereMesh:
        (mesh as SphereMesh).material = material
    elif mesh is CylinderMesh:
        (mesh as CylinderMesh).material = material
    parent.add_child(node)
    return node

func _sphere(parent: Node3D, label: String, pos: Vector3, size: Vector3, material: Material) -> void:
    var mesh := SphereMesh.new()
    mesh.radial_segments = 16
    mesh.rings = 10
    _part(parent, mesh, pos, size, material, label)

func _horn(parent: Node3D, label: String, pos: Vector3, height: float, material: Material, lean: float) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.015
    mesh.bottom_radius = 0.16
    mesh.height = height
    mesh.radial_segments = 10
    var node := _part(parent, mesh, pos, Vector3.ONE, material, label)
    node.rotation.z = lean

func _build_dragon() -> void:
    var root := Node3D.new()
    root.name = "DragonGeometry"
    root.scale = Vector3.ONE * body_scale
    add_child(root)
    var hide := _mat(palette.body, 0.12)
    var belly := _mat(palette.belly)
    var wing_mat := _mat(palette.wing, 0.08)
    var spike := _mat(palette.spike, 0.18, 0.48)
    var eye := _mat(palette.eye, 0.15, 0.2)
    var dark := _mat(Color("#17151a"))

    # Torso, chest, neck, skull and muzzle.
    _sphere(root, "Ribcage", Vector3(0, 1.55, 0.15), Vector3(0.82, 0.82, 1.35), hide)
    _sphere(root, "ChestArmor", Vector3(0, 1.42, -0.72), Vector3(0.72, 0.75, 0.62), belly)
    _sphere(root, "Neck", Vector3(0, 1.95, -1.02), Vector3(0.42, 0.55, 0.82), hide)
    _sphere(root, "Skull", Vector3(0, 2.25, -1.62), Vector3(0.55, 0.48, 0.62), hide)
    _sphere(root, "Jaw", Vector3(0, 2.02, -1.94), Vector3(0.42, 0.2, 0.48), belly)
    _sphere(root, "Nose", Vector3(0, 2.18, -2.12), Vector3(0.34, 0.23, 0.35), hide)

    for side in [-1.0, 1.0]:
        _sphere(root, "EyeSocket", Vector3(side * 0.39, 2.34, -1.83), Vector3(0.15, 0.14, 0.12), dark)
        _sphere(root, "GlowingEye", Vector3(side * 0.46, 2.36, -1.86), Vector3(0.075, 0.085, 0.07), eye)
        _horn(root, "CrownHorn", Vector3(side * 0.34, 2.68, -1.42), 0.72, spike, side * -0.35)
        _horn(root, "JawFang", Vector3(side * 0.25, 1.94, -2.0), 0.24, belly, side * 0.1)

    # Four sturdy legs with separate feet and three visible claws each.
    for side in [-1.0, 1.0]:
        for fore in [true, false]:
            var z := -0.72 if fore else 0.92
            var hip_y := 1.22 if fore else 1.12
            var leg := MeshInstance3D.new()
            var leg_mesh := CapsuleMesh.new()
            leg_mesh.radius = 0.22 if fore else 0.29
            leg_mesh.height = 0.92
            leg.mesh = leg_mesh
            leg.material_override = hide
            leg.position = Vector3(side * (0.56 if fore else 0.62), 0.78, z)
            leg.rotation.z = side * (0.12 if fore else -0.2)
            root.add_child(leg)
            _sphere(root, "ClawedFoot", Vector3(side * (0.58 if fore else 0.64), 0.22, z - 0.12), Vector3(0.34, 0.18, 0.42), hide)
            for claw in range(3):
                _horn(root, "ToeClaw", Vector3(side * (0.42 + claw * 0.16), 0.17, z - 0.38), 0.22, spike, 0.08)

    # Long segmented tail with a bladed tip.
    for i in range(6):
        var t := float(i) / 5.0
        var z := 1.15 + t * 2.2
        var radius := lerpf(0.38, 0.11, t)
        _sphere(root, "TailSegment_%02d" % i, Vector3(0, 1.48 - t * 0.36, z), Vector3(radius, radius, 0.48), hide)
        if i % 2 == 0:
            _horn(root, "TailSpine", Vector3(0, 1.8 - t * 0.35, z), 0.32, spike, 0.0)

    # Two broad bat-like wings, each built from a triangulated 3D membrane.
    _make_wing(root, -1.0, wing_mat, spike)
    _make_wing(root, 1.0, wing_mat, spike)

    # Back ridges and neck spines.
    for i in range(9):
        var z := -1.0 + float(i) * 0.34
        _horn(root, "DorsalSpine", Vector3(0, 2.22 - maxf(0.0, z) * 0.22, z), 0.38, spike, 0.0)

func _make_wing(root: Node3D, side: float, membrane: Material, bone: Material) -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var shoulder := Vector3(side * 0.48, 2.05, -0.05)
    var wrist := Vector3(side * 1.75, 2.85, 0.18)
    var tip := Vector3(side * 3.05, 2.42, 0.72)
    var rear := Vector3(side * 2.35, 1.05, 1.55)
    var root_rear := Vector3(side * 0.62, 1.25, 0.72)
    _tri(st, shoulder, wrist, tip)
    _tri(st, shoulder, tip, rear)
    _tri(st, shoulder, rear, root_rear)
    _tri(st, shoulder, root_rear, wrist)
    st.generate_normals()
    var wing_mesh := st.commit()
    var wing_node := MeshInstance3D.new()
    wing_node.name = "WingMembrane"
    wing_node.mesh = wing_mesh
    wing_node.material_override = membrane
    root.add_child(wing_node)

    _beam(root, shoulder, wrist, 0.085, bone, "WingFinger")
    _beam(root, wrist, tip, 0.065, bone, "WingFinger")
    _beam(root, tip, rear, 0.055, bone, "WingFinger")
    _beam(root, shoulder, rear, 0.075, bone, "WingArm")

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.set_color(Color.WHITE)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

func _beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material, label: String) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.55
    mesh.bottom_radius = radius
    mesh.height = a.distance_to(b)
    var node := _part(parent, mesh, (a + b) * 0.5, Vector3.ONE, material, label)
    node.look_at(b, Vector3.UP)
    node.rotate_object_local(Vector3.RIGHT, PI * 0.5)
