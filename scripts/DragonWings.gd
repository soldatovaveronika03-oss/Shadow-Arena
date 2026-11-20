extends Node3D
var wing_pivots: Array[Node3D] = []
func _ready() -> void:
 var membrane := StandardMaterial3D.new()
 membrane.albedo_color = Color(0.10,0.17,0.25,0.92)
 membrane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 membrane.roughness = 0.55
 var bone := StandardMaterial3D.new()
 bone.albedo_color = Color(0.34,0.39,0.45)
 for side in [-1.0,1.0]:
  var root := Node3D.new()
  root.position = Vector3(side*0.82,2.0,0.12)
  add_child(root)
  wing_pivots.append(root)
  var sail := MeshInstance3D.new()
  var prism := PrismMesh.new()
  prism.size = Vector3(2.8,0.12,2.0)
  sail.mesh = prism
  sail.position = Vector3(side*1.15,0,0.15)
  sail.scale = Vector3(1,1,1)
  sail.rotation.z = side*deg_to_rad(12)
  sail.material_override = membrane
  root.add_child(sail)
  var spar := MeshInstance3D.new()
  var beam := CylinderMesh.new()
  beam.top_radius = 0.045
  beam.bottom_radius = 0.075
  beam.height = 2.5
  spar.mesh = beam
  spar.position = Vector3(side*1.05,0.05,-0.12)
  spar.rotation.z = side*deg_to_rad(55)
  spar.material_override = bone
  root.add_child(spar)
