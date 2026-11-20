extends Node3D
var tail_pivot: Node3D
func _ready() -> void:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.16,0.22,0.30)
 tail_pivot = Node3D.new()
 tail_pivot.position = Vector3(0,1.55,1.55)
 add_child(tail_pivot)
 for i in range(4):
  var segment := MeshInstance3D.new()
  var cone := CylinderMesh.new()
  cone.top_radius = 0.05
  cone.bottom_radius = 0.34 - i*0.065
  cone.height = 0.82
  segment.mesh = cone
  segment.position = Vector3(0,0,0.38+i*0.65)
  segment.rotation.x = PI/2
  segment.material_override = mat
  tail_pivot.add_child(segment)
 var tip := MeshInstance3D.new()
 var spike := PrismMesh.new()
 spike.size = Vector3(0.65,0.42,0.9)
 tip.mesh = spike
 tip.position = Vector3(0,0,3.05)
 tip.material_override = mat
 tail_pivot.add_child(tip)
