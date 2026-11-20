extends Node3D
var legs: Array[Node3D] = []
func _ready() -> void:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.13,0.19,0.27)
 for side in [-1.0,1.0]:
  for z in [-0.85,0.95]:
   var leg := Node3D.new()
   leg.position = Vector3(side*0.72,1.05,z)
   add_child(leg)
   legs.append(leg)
   var mesh := MeshInstance3D.new()
   var capsule := CapsuleMesh.new()
   capsule.radius = 0.23
   capsule.height = 1.05
   mesh.mesh = capsule
   mesh.position.y = -0.42
   mesh.material_override = mat
   leg.add_child(mesh)
   var claw := MeshInstance3D.new()
   var cone := CylinderMesh.new()
   cone.top_radius = 0.0
   cone.bottom_radius = 0.12
   cone.height = 0.32
   claw.mesh = cone
   claw.position = Vector3(0,-0.91,-0.12)
   claw.rotation.x = PI
   claw.material_override = mat
   leg.add_child(claw)
