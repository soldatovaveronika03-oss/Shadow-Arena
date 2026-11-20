extends Node3D
var head_pivot: Node3D
func _ready() -> void:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.19,0.26,0.34)
 mat.metallic = 0.42
 head_pivot = Node3D.new()
 head_pivot.position = Vector3(0,1.82,-1.75)
 add_child(head_pivot)
 _part(head_pivot,SphereMesh.new(),Vector3(0,0,-0.25),Vector3(0.72,0.68,0.92),mat)
 _part(head_pivot,SphereMesh.new(),Vector3(0,-0.22,-0.88),Vector3(0.48,0.32,0.82),mat)
 for side in [-1.0,1.0]:
  _part(head_pivot,CylinderMesh.new(),Vector3(side*0.38,0.62,0.02),Vector3(0.18,0.62,0.18),mat,deg_to_rad(side*18.0))
 var eye_mat := StandardMaterial3D.new()
 eye_mat.albedo_color = Color(1.0,0.36,0.06)
 eye_mat.emission_enabled = true
 eye_mat.emission = Color(1.0,0.18,0.015)
 for side in [-1.0,1.0]:
  _part(head_pivot,SphereMesh.new(),Vector3(side*0.43,0.16,-0.62),Vector3(0.13,0.13,0.12),eye_mat)
func _part(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, mat: Material, rz: float=0.0) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.mesh = mesh
 node.position = pos
 node.scale = size
 node.rotation.z = rz
 node.material_override = mat
 parent.add_child(node)
 return node
