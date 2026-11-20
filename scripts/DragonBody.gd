extends Node3D
var material: StandardMaterial3D
var pivot: Node3D
func _ready() -> void:
 material = StandardMaterial3D.new()
 material.albedo_color = Color(0.16,0.22,0.30)
 material.metallic = 0.48
 material.roughness = 0.34
 pivot = Node3D.new()
 pivot.name = "BodyPivot"
 pivot.position.y = 1.65
 add_child(pivot)
 _part(pivot, SphereMesh.new(), Vector3.ZERO, Vector3(1.45,0.95,2.25))
 _part(pivot, SphereMesh.new(), Vector3(0,-0.42,0.25), Vector3(1.0,0.48,1.35))
func _part(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.mesh = mesh
 node.position = pos
 node.scale = size
 node.material_override = material
 parent.add_child(node)
 return node
