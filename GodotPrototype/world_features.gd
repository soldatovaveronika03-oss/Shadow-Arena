extends Node3D
# Mobile-friendly procedural landmarks for ATLAS WILDS ARENA.
# Geometry is deliberately split into simple meshes with primitive collision.

const CASTLE_CENTER := Vector2(-112.0, -92.0)

func _ready() -> void:
	_build_castle()
	_build_village()
	_build_ruined_outpost()
	_build_waterfall()

func _terrain_height(x: float, z: float) -> float:
	# Use the exact terrain function from the main world so landmarks never float.
	return float(get_parent().call("_terrain_height", x, z))

func _terrain_delta(local_x: float, local_z: float, origin: Vector3) -> float:
	return _terrain_height(origin.x + local_x, origin.z + local_z) - origin.y

func _material(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func _box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material, with_collision: bool = true) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "_Collision"
		body.position = pos
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		parent.add_child(body)

func _cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, mat: Material, with_collision: bool = true) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	mesh.radial_segments = 12
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	if with_collision:
		var body := StaticBody3D.new()
		body.name = node_name + "_Collision"
		body.position = pos
		var shape := CollisionShape3D.new()
		var cylinder_shape := CylinderShape3D.new()
		cylinder_shape.radius = radius * 1.04
		cylinder_shape.height = height
		shape.shape = cylinder_shape
		body.add_child(shape)
		parent.add_child(body)

func _cone(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	parent.add_child(mesh_instance)

func _build_castle() -> void:
	var castle := Node3D.new()
	castle.name = "HighKingsCastle"
	castle.position = Vector3(CASTLE_CENTER.x, _terrain_height(CASTLE_CENTER.x, CASTLE_CENTER.y), CASTLE_CENTER.y)
	add_child(castle)

	var stone := _material(Color(0.34, 0.35, 0.34))
	var dark_stone := _material(Color(0.20, 0.23, 0.23))
	var roof := _material(Color(0.16, 0.22, 0.24), 0.72, 0.12)
	var gold := _material(Color(0.72, 0.52, 0.20), 0.38, 0.55)
	var wood := _material(Color(0.24, 0.13, 0.075))
	var flag_mat := _material(Color(0.48, 0.09, 0.075), 0.85)

	# Raised stone courtyard and four curtain walls, leaving a central gate opening.
	_box(castle, "CastleFoundation", Vector3(0, 0.65, 0), Vector3(42, 1.3, 34), dark_stone)
	_box(castle, "NorthWall", Vector3(0, 7.0, -16), Vector3(42, 12, 2.2), stone)
	_box(castle, "WestWall", Vector3(-20, 7.0, 0), Vector3(2.2, 12, 34), stone)
	_box(castle, "EastWall", Vector3(20, 7.0, 0), Vector3(2.2, 12, 34), stone)
	_box(castle, "SouthWallLeft", Vector3(-13.0, 7.0, 16), Vector3(16, 12, 2.2), stone)
	_box(castle, "SouthWallRight", Vector3(13.0, 7.0, 16), Vector3(16, 12, 2.2), stone)
	_box(castle, "GateLintel", Vector3(0, 12.0, 16), Vector3(10, 2.0, 2.5), dark_stone)
	_box(castle, "GateDoorLeft", Vector3(-4.0, 4.8, 17.3), Vector3(1.1, 8.8, 0.45), wood)
	_box(castle, "GateDoorRight", Vector3(4.0, 4.8, 17.3), Vector3(1.1, 8.8, 0.45), wood)

	# Four corner towers.
	for p in [Vector2(-19, -15), Vector2(19, -15), Vector2(-19, 15), Vector2(19, 15)]:
		_cylinder(castle, "RoundCurtainTower", Vector3(p.x, 9.2, p.y), 4.2, 18.4, dark_stone)
		_cone(castle, "TowerConicalRoof", Vector3(p.x, 21.0, p.y), 5.0, 7.0, roof)
		_cylinder(castle, "TowerGoldFinial", Vector3(p.x, 25.0, p.y), 0.22, 1.5, gold, false)

	# Keep and central great hall.
	_box(castle, "GreatKeep", Vector3(0, 9.0, -5.0), Vector3(13, 17, 12), dark_stone)
	_box(castle, "KeepUpperGallery", Vector3(0, 18.0, -5.0), Vector3(15, 1.0, 14), stone)
	_cylinder(castle, "KeepCentralTower", Vector3(0, 22.0, -5.0), 5.2, 27.0, stone)
	_cone(castle, "KeepHighRoof", Vector3(0, 39.0, -5.0), 6.3, 9.0, roof)
	_cylinder(castle, "KeepFinial", Vector3(0, 44.0, -5.0), 0.25, 2.0, gold, false)

	# Battlements as a single MultiMesh to limit draw calls.
	var merlon_mesh := BoxMesh.new()
	merlon_mesh.size = Vector3(1.2, 1.5, 1.2)
	var merlons := MultiMesh.new()
	merlons.transform_format = MultiMesh.TRANSFORM_3D
	merlons.mesh = merlon_mesh
	var transforms: Array[Transform3D] = []
	for x in range(-19, 20, 3):
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(float(x), 13.7, -16)))
		if absf(float(x)) > 6.0:
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(float(x), 13.7, 16)))
	for z in range(-13, 14, 3):
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(-20, 13.7, float(z))))
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(20, 13.7, float(z))))
	merlons.instance_count = transforms.size()
	for i in range(transforms.size()):
		merlons.set_instance_transform(i, transforms[i])
	var merlon_instance := MultiMeshInstance3D.new()
	merlon_instance.name = "CastleBattlements"
	merlon_instance.multimesh = merlons
	merlon_instance.material_override = stone
	castle.add_child(merlon_instance)

	# Raised approach bridge, wooden gatehouse details and standards.
	_box(castle, "Drawbridge", Vector3(0, 0.25, 24.0), Vector3(9, 0.5, 15), wood)
	_box(castle, "GatehouseRoof", Vector3(0, 14.0, 16.0), Vector3(12, 0.7, 4.0), roof)
	for x in [-5.2, 5.2]:
		_cylinder(castle, "BannerPole", Vector3(x, 18.0, 15.8), 0.12, 8.0, gold, false)
		var banner := MeshInstance3D.new()
		var banner_mesh := BoxMesh.new()
		banner_mesh.size = Vector3(2.2, 3.4, 0.12)
		banner.mesh = banner_mesh
		banner.material_override = flag_mat
		banner.position = Vector3(x, 15.3, 15.8)
		castle.add_child(banner)

	# Interior hall roof, stairs and yard lanterns.
	_cone(castle, "HallRoof", Vector3(0, 20.0, -5.0), 10.0, 7.0, roof)
	for step in range(7):
		_box(castle, "KeepStair_%02d" % step, Vector3(0, 0.5 + step * 0.45, 8.0 - step * 1.3), Vector3(5.0, 0.5, 1.5), stone)
	for x in [-13.0, 13.0]:
		var lamp := OmniLight3D.new()
		lamp.name = "CourtyardWarmLantern"
		lamp.position = Vector3(x, 5.0, 5.0)
		lamp.light_color = Color(1.0, 0.66, 0.32)
		lamp.light_energy = 0.45
		lamp.omni_range = 9.0
		castle.add_child(lamp)

 
func _build_village() -> void:
	var village := Node3D.new()
	village.name = "GreenvaleVillage"
	village.position = Vector3(66.0, _terrain_height(66.0, 108.0), 108.0)
	add_child(village)
	var stone := _material(Color(0.34, 0.33, 0.29), 0.94)
	var plaster := _material(Color(0.63, 0.55, 0.40), 0.92)
	var timber := _material(Color(0.22, 0.12, 0.065), 0.9)
	var roof := _material(Color(0.20, 0.13, 0.10), 0.9)
	var dark := _material(Color(0.075, 0.065, 0.045), 0.98)
	_build_village_house(village, Vector3(0, _terrain_delta(0, 0, village.position), 0), 1.18, stone, plaster, timber, roof, dark, "VillageInn")
	_build_village_house(village, Vector3(-15, _terrain_delta(-15, -8, village.position), -8), 0.82, stone, plaster, timber, roof, dark, "NorthCottage")
	_build_village_house(village, Vector3(16, _terrain_delta(16, -11, village.position), -11), 0.88, stone, plaster, timber, roof, dark, "EastCottage")
	_build_village_house(village, Vector3(-17, _terrain_delta(-17, 13, village.position), 13), 0.78, stone, plaster, timber, roof, dark, "SouthCottage")
	_build_village_house(village, Vector3(17, _terrain_delta(17, 14, village.position), 14), 0.92, stone, plaster, timber, roof, dark, "CraftsmanHome")
	# Village well and low timber fencing.
	_cylinder(village, "VillageWellStoneRim", Vector3(0, 0.65, 18), 1.45, 1.3, stone)
	_cylinder(village, "VillageWellWater", Vector3(0, 1.28, 18), 1.08, 0.08, _material(Color(0.06, 0.24, 0.30), 0.2), false)
	for x in [-2.0, 2.0]:
		_cylinder(village, "WellSupport", Vector3(x, 2.6, 18), 0.12, 3.2, timber, false)
	_box(village, "WellRoof", Vector3(0, 4.25, 18), Vector3(5.2, 0.35, 3.2), roof, false)
	for side in [-1.0, 1.0]:
		for i in range(8):
			var fence_z := -17.0 + float(i) * 4.8
			_cylinder(village, "FencePost", Vector3(side * 27.0, 0.8, fence_z), 0.12, 1.6, timber, false)
			_box(village, "FenceRail", Vector3(side * 27.0, 0.55, fence_z + 2.4), Vector3(0.18, 0.16, 4.8), timber, false)
			_box(village, "FenceRailUpper", Vector3(side * 27.0, 1.1, fence_z + 2.4), Vector3(0.18, 0.16, 4.8), timber, false)

func _build_village_house(parent: Node3D, local_pos: Vector3, scale: float, stone: Material, plaster: Material, timber: Material, roof: Material, dark: Material, house_name: String) -> void:
	var house := Node3D.new()
	house.name = house_name
	house.position = local_pos
	house.scale = Vector3.ONE * scale
	parent.add_child(house)
	_box(house, "StoneFooting", Vector3(0, 0.22, 0), Vector3(7.4, 0.45, 6.4), stone)
	_box(house, "BackWall", Vector3(0, 1.9, -2.9), Vector3(7.0, 3.2, 0.28), plaster)
	_box(house, "LeftWall", Vector3(-3.35, 1.9, 0), Vector3(0.28, 3.2, 5.8), plaster)
	_box(house, "RightWall", Vector3(3.35, 1.9, 0), Vector3(0.28, 3.2, 5.8), plaster)
	_box(house, "FrontLeftWall", Vector3(-2.1, 1.9, 2.9), Vector3(2.5, 3.2, 0.28), plaster)
	_box(house, "FrontRightWall", Vector3(2.1, 1.9, 2.9), Vector3(2.5, 3.2, 0.28), plaster)
	_box(house, "FrontDoor", Vector3(0, 1.45, 3.08), Vector3(1.55, 2.55, 0.16), timber, false)
	_box(house, "DoorHandle", Vector3(0.48, 1.45, 3.18), Vector3(0.08, 0.08, 0.06), dark, false)
	for side in [-1.0, 1.0]:
		_box(house, "WindowFrame", Vector3(side * 2.15, 2.0, 3.12), Vector3(0.92, 1.05, 0.12), timber, false)
		_box(house, "WindowGlass", Vector3(side * 2.15, 2.0, 3.20), Vector3(0.68, 0.82, 0.06), dark, false)
		var roof_slope := MeshInstance3D.new()
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(4.25, 0.38, 7.1)
		roof_slope.mesh = roof_mesh
		roof_slope.material_override = roof
		roof_slope.position = Vector3(side * 1.72, 4.0, 0)
		roof_slope.rotation.z = side * -0.52
		house.add_child(roof_slope)
	_cylinder(house, "StoneChimney", Vector3(-2.25, 4.0, -1.8), 0.34, 2.3, stone, false)
	_box(house, "TimberGableBeam", Vector3(0, 3.45, 0), Vector3(7.2, 0.18, 0.18), timber, false)

func _build_ruined_outpost() -> void:
	var ruins := Node3D.new()
	ruins.name = "AncientRoadsideRuins"
	ruins.position = Vector3(72.0, _terrain_height(72.0, 42.0), 42.0)
	add_child(ruins)
	var stone := _material(Color(0.36, 0.35, 0.31))
	_box(ruins, "BrokenWallA", Vector3(-4, 1.8, 0), Vector3(8, 3.6, 0.8), stone)
	_box(ruins, "BrokenWallB", Vector3(4, 1.2, -5), Vector3(0.8, 2.4, 7), stone)
	_cylinder(ruins, "FallenColumn", Vector3(1, 0.8, 4), 0.7, 4.5, stone, false)
	for x in [-5.0, 5.0]:
		_cylinder(ruins, "OldPillar", Vector3(x, 2.8, 5), 0.65, 5.6, stone)
		_box(ruins, "PillarCapital", Vector3(x, 5.7, 5), Vector3(1.8, 0.5, 1.8), stone)

func _build_waterfall() -> void:
	var waterfall := Node3D.new()
	waterfall.name = "MountainWaterfall"
	waterfall.position = Vector3(132.0, _terrain_height(132.0, -18.0) + 5.0, -18.0)
	add_child(waterfall)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.24, 0.55, 0.64, 0.78)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.18
	water.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	var sheet := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10.0, 19.0)
	sheet.mesh = plane
	sheet.material_override = water
	sheet.rotation_degrees.x = 90.0
	sheet.position = Vector3(0, -8.0, 0)
	waterfall.add_child(sheet)
	var basin := MeshInstance3D.new()
	var basin_mesh := CylinderMesh.new()
	basin_mesh.top_radius = 6.0
	basin_mesh.bottom_radius = 6.0
	basin_mesh.height = 0.35
	basin.mesh = basin_mesh
	basin.material_override = water
	basin.position = Vector3(0, -17.0, 3.0)
	waterfall.add_child(basin)
