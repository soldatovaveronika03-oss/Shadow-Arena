extends Node3D
class_name Wildlands

const WORLD_SIZE := 1000.0
const GRID := 100
var rng := RandomNumberGenerator.new()

static func terrain_height(x: float, z: float) -> float:
	return 1.8 * sin(x * 0.012) * cos(z * 0.009) + 0.8 * sin((x + z) * 0.025)

func _ready() -> void:
	rng.seed = 428119
	_build_terrain()
	_build_water()
	_build_forest()
	_build_rocks()
	_build_landmarks()

func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WORLD_SIZE * 0.5
	var step := WORLD_SIZE / float(GRID)
	for z in range(GRID):
		for x in range(GRID):
			var x0 := -half + x * step
			var z0 := -half + z * step
			var p00 := Vector3(x0, terrain_height(x0,z0), z0)
			var p10 := Vector3(x0+step, terrain_height(x0+step,z0), z0)
			var p01 := Vector3(x0, terrain_height(x0,z0+step), z0+step)
			var p11 := Vector3(x0+step, terrain_height(x0+step,z0+step), z0+step)
			for p in [p00,p01,p10,p10,p01,p11]:
				var shade := clampf((p.y+2.8)/6.0,0.0,1.0)
				var color := Color(0.10+shade*0.08,0.19+shade*0.19,0.09+shade*0.07)
				st.set_color(color)
				st.add_vertex(p)
	st.generate_normals()
	var mesh := st.commit()
	var ground := MeshInstance3D.new()
	ground.name = "ProceduralWildlandsTerrain"
	ground.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)
	ground.create_trimesh_collision()

func _build_water() -> void:
	for data in [{"pos":Vector3(155,-0.8,-115),"size":Vector2(115,62)},{"pos":Vector3(-270,-0.7,220),"size":Vector2(90,145)}]:
		var lake := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = data.size
		lake.mesh = plane
		lake.position = data.pos
		var water := StandardMaterial3D.new()
		water.albedo_color = Color(0.035,0.22,0.31,0.86)
		water.metallic = 0.25
		water.roughness = 0.16
		water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lake.material_override = water
		add_child(lake)

func _build_forest() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.34
	trunk.height = 3.2
	var leaves := SphereMesh.new()
	leaves.radius = 1.55
	leaves.height = 3.4
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.20,0.105,0.055)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.075,0.22,0.10)
	leaf_mat.roughness = 0.95
	var trunk_mm := _make_multimesh(trunk, 620)
	var leaf_mm := _make_multimesh(leaves, 620)
	for i in range(620):
		var x := rng.randf_range(-480,480)
		var z := rng.randf_range(-480,480)
		if Vector2(x,z).length() < 38:
			x += 65
		var y := terrain_height(x,z)
		var h := rng.randf_range(0.75,1.65)
		var basis := Basis().scaled(Vector3(h,h,h))
		var t := Transform3D(basis,Vector3(x,y+1.6*h,z))
		trunk_mm.set_instance_transform(i,t)
		var crown := Transform3D(Basis().scaled(Vector3(h,h,h)),Vector3(x,y+3.55*h,z))
		leaf_mm.set_instance_transform(i,crown)
	_add_multimesh(trunk_mm,trunk_mat,"Forest trunks")
	_add_multimesh(leaf_mm,leaf_mat,"Forest canopy")
	var grass := _make_multimesh(_grass_mesh(), 2600)
	for i in range(2600):
		var x := rng.randf_range(-495,495)
		var z := rng.randf_range(-495,495)
		var h := rng.randf_range(0.35,1.0)
		grass.set_instance_transform(i,Transform3D(Basis().rotated(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(h,h,h)),Vector3(x,terrain_height(x,z)+0.2,z)))
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.20,0.36,0.13)
	gm.roughness = 1.0
	_add_multimesh(grass,gm,"Grass")

func _build_rocks() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.7
	var mm := _make_multimesh(mesh,180)
	for i in range(180):
		var x := rng.randf_range(-480,480)
		var z := rng.randf_range(-480,480)
		var s := rng.randf_range(1.0,4.2)
		mm.set_instance_transform(i,Transform3D(Basis().scaled(Vector3(s*1.4,s,s)),Vector3(x,terrain_height(x,z)+s*0.45,z)))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24,0.27,0.29)
	mat.roughness = 0.94
	_add_multimesh(mm,mat,"Boulders")

func _build_landmarks() -> void:
	for i in range(8):
		var angle := TAU * float(i)/8.0
		var x := cos(angle)*350.0
		var z := sin(angle)*350.0
		var spire := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(5,22,5)
		spire.mesh = prism
		spire.position = Vector3(x,terrain_height(x,z)+11,z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.12,0.18,0.25)
		mat.emission_enabled = true
		mat.emission = Color(0.025,0.11,0.18)
		spire.material_override = mat
		add_child(spire)

func _make_multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	return mm

func _add_multimesh(mm: MultiMesh, material: Material, label: String) -> void:
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = mm
	node.material_override = material
	add_child(node)

func _grass_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in range(3):
		var a := float(blade)*PI/3.0
		var side := Vector3(cos(a),0,sin(a))*0.12
		var center := Vector3.ZERO
		st.add_vertex(center-side)
		st.add_vertex(center+Vector3.UP*0.65)
		st.add_vertex(center+side)
	return st.commit()
