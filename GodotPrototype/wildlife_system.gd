extends Node3D
# Lightweight procedural 3D wildlife and dragon controller for mobile.
# Animals use articulated pivots so locomotion remains animated without imported rigs.

var rng := RandomNumberGenerator.new()
var player: Node3D
var creatures: Array[Dictionary] = []
var wind_parts: Array[Dictionary] = []
var world_time := 0.0

func _ready() -> void:
	rng.seed = 731904
	player = get_parent().get_node_or_null("Kairon") as Node3D
	_spawn_wildlife()
	_spawn_dragon()
	_build_wind_foliage()

func _ground(x: float, z: float) -> float:
	return float(get_parent().call("_terrain_height", x, z))

func _mat(color: Color, roughness: float = 0.88, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _mesh(parent: Node3D, name: String, mesh: Mesh, material: Material, pos: Vector3, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name
	n.mesh = mesh
	n.material_override = material
	n.position = pos
	n.scale = scale
	parent.add_child(n)
	return n

func _sphere(parent: Node3D, name: String, material: Material, pos: Vector3, scale: Vector3) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 12
	m.rings = 8
	return _mesh(parent, name, m, material, pos, scale)

func _capsule(parent: Node3D, name: String, material: Material, pos: Vector3, radius: float, height: float) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 8
	m.rings = 4
	return _mesh(parent, name, m, material, pos)

func _make_quadruped(kind: String, coat: Color) -> Dictionary:
	var root := Node3D.new()
	root.name = kind
	var body_mat := _mat(coat)
	var dark_mat := _mat(coat.darkened(0.28))
	var light_mat := _mat(coat.lightened(0.18))
	_sphere(root, "Torso", body_mat, Vector3(0, 0.95, 0), Vector3(0.72, 0.48, 1.12))
	var neck := Node3D.new()
	neck.position = Vector3(0, 1.03, -0.72)
	root.add_child(neck)
	_sphere(neck, "Neck", body_mat, Vector3(0, 0.12, -0.18), Vector3(0.34, 0.42, 0.55))
	_sphere(neck, "Head", light_mat, Vector3(0, 0.28, -0.48), Vector3(0.38, 0.34, 0.48))
	_sphere(neck, "Muzzle", dark_mat, Vector3(0, 0.10, -0.80), Vector3(0.25, 0.18, 0.28))
	for side in [-1.0, 1.0]:
		_sphere(neck, "Eye", _mat(Color(0.025, 0.02, 0.015)), Vector3(side * 0.19, 0.36, -0.68), Vector3(0.055, 0.055, 0.055))
		if kind == "ForestDeer":
			var horn := _capsule(neck, "Antler", light_mat, Vector3(side * 0.20, 0.62, -0.42), 0.045, 0.72)
			horn.rotation.z = side * -0.38
			var tine := _capsule(neck, "AntlerBranch", light_mat, Vector3(side * 0.34, 0.83, -0.43), 0.028, 0.38)
			tine.rotation.z = side * -0.9
		elif kind == "WildBoar":
			var tusk := _capsule(neck, "Tusk", light_mat, Vector3(side * 0.22, 0.05, -0.72), 0.045, 0.24)
			tusk.rotation.z = side * 0.55
	var legs: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		for front in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 0.38, 0.78, front * 0.68)
			root.add_child(pivot)
			_capsule(pivot, "Leg", dark_mat, Vector3(0, -0.29, 0), 0.105, 0.66)
			_sphere(pivot, "Hoof", light_mat, Vector3(0, -0.59, -0.025), Vector3(0.19, 0.12, 0.22))
			legs.append(pivot)
	var tail := Node3D.new()
	tail.position = Vector3(0, 1.0, 0.96)
	root.add_child(tail)
	_capsule(tail, "Tail", dark_mat, Vector3(0, -0.02, 0.28), 0.075, 0.56).rotation.x = 1.15
	if kind == "ForestDeer":
		_sphere(root, "CreamFlank", light_mat, Vector3(0, 1.02, 0.35), Vector3(0.50, 0.27, 0.48))
	return {"root": root, "legs": legs, "neck": neck, "tail": tail, "kind": kind, "phase": rng.randf_range(0.0, TAU), "speed": rng.randf_range(1.0, 2.0), "state": "graze", "target": Vector3.ZERO, "think": rng.randf_range(1.0, 4.0), "home": Vector3.ZERO}

func _spawn_wildlife() -> void:
	var types := [
		{"kind": "ForestDeer", "color": Color(0.48, 0.25, 0.12), "count": 8},
		{"kind": "GreyWolf", "color": Color(0.28, 0.32, 0.34), "count": 6},
		{"kind": "WildBoar", "color": Color(0.25, 0.16, 0.12), "count": 5}
	]
	for entry in types:
		for i in range(int(entry.count)):
			var x := rng.randf_range(-150.0, 150.0)
			var z := rng.randf_range(-150.0, 150.0)
			if Vector2(x, z - 8.0).length() < 36.0:
				x += 52.0
			var data := _make_quadruped(String(entry.kind), entry.color)
			var root: Node3D = data.root
			root.position = Vector3(x, _ground(x, z), z)
			root.rotation.y = rng.randf_range(-PI, PI)
			add_child(root)
			data.home = root.position
			data.target = root.position
			creatures.append(data)

func _wing_mesh(material: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(0, 0, 0))
	st.add_vertex(Vector3(2.8, 0.15, 0))
	st.add_vertex(Vector3(1.9, 0.95, 0))
	st.add_vertex(Vector3(0, 0, 0))
	st.add_vertex(Vector3(1.9, 0.95, 0))
	st.add_vertex(Vector3(0.5, 1.45, 0))
	st.generate_normals()
	return _mesh(Node3D.new(), "unused", st.commit(), material, Vector3.ZERO)

func _spawn_dragon() -> void:
	var root := Node3D.new()
	root.name = "AncientWildDragon"
	var hide := _mat(Color(0.12, 0.25, 0.20), 0.72)
	var belly := _mat(Color(0.47, 0.34, 0.20))
	var horn_mat := _mat(Color(0.72, 0.61, 0.38), 0.52)
	var eye_mat := _mat(Color(1.0, 0.28, 0.035), 0.3, 0.2)
	_sphere(root, "DragonChest", hide, Vector3(0, 1.55, 0), Vector3(1.15, 0.82, 2.0))
	_sphere(root, "DragonBelly", belly, Vector3(0, 1.18, -0.12), Vector3(0.88, 0.38, 1.55))
	var neck := Node3D.new()
	neck.position = Vector3(0, 1.85, -1.25)
	root.add_child(neck)
	_capsule(neck, "Neck", hide, Vector3(0, 0.18, -0.55), 0.42, 1.55).rotation.x = -0.45
	_sphere(neck, "DragonHead", hide, Vector3(0, 0.58, -1.12), Vector3(0.62, 0.48, 0.85))
	_sphere(neck, "DragonJaw", belly, Vector3(0, 0.30, -1.55), Vector3(0.48, 0.18, 0.55))
	for side in [-1.0, 1.0]:
		_sphere(neck, "GlowingEye", eye_mat, Vector3(side * 0.43, 0.70, -1.35), Vector3(0.10, 0.10, 0.10))
		var horn := _capsule(neck, "CrownHorn", horn_mat, Vector3(side * 0.32, 1.02, -0.88), 0.12, 0.82)
		horn.rotation.z = side * -0.52
	var tail := Node3D.new()
	tail.position = Vector3(0, 1.48, 1.5)
	root.add_child(tail)
	_capsule(tail, "LongTail", hide, Vector3(0, 0, 0.88), 0.22, 2.15).rotation.x = 1.15
	var legs: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		for front in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.72, 1.18, front * 0.92)
			root.add_child(leg)
			_capsule(leg, "DragonLeg", hide, Vector3(0, -0.30, 0), 0.20, 0.92)
			_sphere(leg, "Claw", horn_mat, Vector3(0, -0.72, -0.12), Vector3(0.26, 0.12, 0.34))
			legs.append(leg)
	var wings: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.82, 2.05, 0.1)
		root.add_child(pivot)
		var wing_mat := _mat(Color(0.075, 0.16, 0.13, 0.94), 0.8)
		var wing := _wing_mesh(wing_mat)
		pivot.add_child(wing)
		wing.position.x = 0.0 if side > 0.0 else -2.8
		wing.scale.x = side
		pivot.rotation.z = side * 0.12
		wings.append(pivot)
	root.position = Vector3(38.0, _ground(38.0, -42.0), -42.0)
	root.scale = Vector3.ONE * 1.9
	add_child(root)
	creatures.append({"root": root, "legs": legs, "wings": wings, "tail": tail, "neck": neck, "kind": "Dragon", "phase": 0.0, "speed": 4.0, "state": "ground", "target": Vector3(75, 0, -75), "think": 3.0, "home": root.position, "flight_time": 0.0})

func _build_wind_foliage() -> void:
	var leaf_mat := _mat(Color(0.16, 0.34, 0.16))
	var grass_mat := _mat(Color(0.24, 0.38, 0.16))
	for i in range(32):
		var x := rng.randf_range(-180.0, 180.0)
		var z := rng.randf_range(-180.0, 180.0)
		if Vector2(x, z - 8.0).length() < 42.0:
			continue
		var shrub := Node3D.new()
		shrub.position = Vector3(x, _ground(x, z), z)
		add_child(shrub)
		for j in range(3):
			_sphere(shrub, "LeafCluster", leaf_mat, Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.3, 0.8), rng.randf_range(-0.4, 0.4)), Vector3(0.65, 0.45, 0.6))
		wind_parts.append({"node": shrub, "phase": rng.randf_range(0.0, TAU), "strength": 0.06})
	for i in range(90):
		var x := rng.randf_range(-190.0, 190.0)
		var z := rng.randf_range(-190.0, 190.0)
		var clump := Node3D.new()
		clump.position = Vector3(x, _ground(x, z), z)
		add_child(clump)
		for j in range(3):
			var blade := _capsule(clump, "GrassBlade", grass_mat, Vector3(rng.randf_range(-0.22, 0.22), 0.25, rng.randf_range(-0.22, 0.22)), 0.035, 0.62)
			blade.rotation.z = rng.randf_range(-0.5, 0.5)
		wind_parts.append({"node": clump, "phase": rng.randf_range(0.0, TAU), "strength": 0.10})

func _choose_target(data: Dictionary) -> void:
	var home: Vector3 = data.home
	data.target = home + Vector3(rng.randf_range(-24.0, 24.0), 0.0, rng.randf_range(-24.0, 24.0))
	data.state = "wander"
	data.think = rng.randf_range(3.0, 7.0)

func _process(delta: float) -> void:
	world_time += delta
	for part in wind_parts:
		var node: Node3D = part.node
		node.rotation.z = sin(world_time * 1.35 + float(part.phase)) * float(part.strength)
	for data in creatures:
		var root: Node3D = data.root
		var kind := String(data.kind)
		var phase := float(data.phase) + delta * (5.5 if kind == "Dragon" else 4.5)
		data.phase = phase
		var legs: Array = data.legs
		var moving := false
		if kind == "Dragon":
			_update_dragon(data, delta, phase)
			continue
		data.think = float(data.think) - delta
		var distance_to_player := 9999.0
		if player != null:
			distance_to_player = root.global_position.distance_to(player.global_position)
		if kind == "GreyWolf" and distance_to_player < 17.0:
			data.state = "hunt"
			data.target = player.global_position
		elif kind != "GreyWolf" and distance_to_player < 13.0:
			data.state = "flee"
			var away := (root.global_position - player.global_position).normalized()
			data.target = root.global_position + away * 28.0
		elif float(data.think) <= 0.0:
			_choose_target(data)
		var target: Vector3 = data.target
		var flat := Vector3(target.x - root.global_position.x, 0, target.z - root.global_position.z)
		if flat.length() > 1.4:
			moving = true
			var speed := float(data.speed) * (1.55 if String(data.state) in ["flee", "hunt"] else 0.62)
			root.position += flat.normalized() * speed * delta
			root.rotation.y = lerp_angle(root.rotation.y, atan2(-flat.x, -flat.z), minf(delta * 4.0, 1.0))
		else:
			data.think = minf(float(data.think), 0.4)
		root.position.y = _ground(root.position.x, root.position.z)
		for i in range(legs.size()):
			var leg: Node3D = legs[i]
			leg.rotation.x = sin(phase + (PI if i % 2 == 0 else 0.0)) * (0.62 if moving else 0.045)
		var tail: Node3D = data.tail
		tail.rotation.x = sin(phase * 0.7) * 0.16
		var neck: Node3D = data.neck
		neck.rotation.x = sin(phase * 0.55) * (0.08 if not moving else 0.025)

func _update_dragon(data: Dictionary, delta: float, phase: float) -> void:
	var root: Node3D = data.root
	var wings: Array = data.wings
	var legs: Array = data.legs
	data.flight_time = float(data.flight_time) + delta
	data.think = float(data.think) - delta
	if String(data.state) == "ground" and float(data.think) <= 0.0:
		data.state = "takeoff"
		data.think = 2.2
		data.target = Vector3(rng.randf_range(-110.0, 110.0), 0.0, rng.randf_range(-110.0, 110.0))
	elif String(data.state) == "flight" and float(data.think) <= 0.0:
		data.state = "landing"
		data.think = 2.0
	elif String(data.state) == "landing" and float(data.think) <= 0.0:
		data.state = "ground"
		data.think = rng.randf_range(7.0, 13.0)
		data.target = root.position
	if String(data.state) == "ground":
		root.position.y = _ground(root.position.x, root.position.z)
	else:
		var target: Vector3 = data.target
		var target_y := 20.0 + sin(phase * 0.22) * 5.0
		if String(data.state) == "takeoff":
			target_y = 24.0
		elif String(data.state) == "landing":
			target_y = 1.8
		var flat := Vector3(target.x - root.position.x, 0, target.z - root.position.z)
		if flat.length() > 3.0:
			root.position.x += flat.normalized().x * 6.5 * delta
			root.position.z += flat.normalized().z * 6.5 * delta
			root.rotation.y = lerp_angle(root.rotation.y, atan2(-flat.x, -flat.z), minf(delta * 2.2, 1.0))
		root.position.y = lerpf(root.position.y, _ground(root.position.x, root.position.z) + target_y, minf(delta * 0.7, 1.0))
		if String(data.state) == "takeoff" and root.position.y > _ground(root.position.x, root.position.z) + 18.0:
			data.state = "flight"
			data.think = rng.randf_range(8.0, 14.0)
	for i in range(wings.size()):
		var wing: Node3D = wings[i]
		var side := -1.0 if i == 0 else 1.0
		wing.rotation.z = side * (0.12 + sin(phase * 2.8) * (0.72 if String(data.state) != "ground" else 0.18))
		wing.rotation.x = cos(phase * 2.8) * 0.12
	for i in range(legs.size()):
		var leg: Node3D = legs[i]
		leg.rotation.x = sin(phase * 2.0 + float(i)) * (0.24 if String(data.state) == "ground" else 0.05)
	var tail: Node3D = data.tail
	tail.rotation.y = sin(phase * 0.65) * 0.22
	var neck: Node3D = data.neck
	neck.rotation.x = sin(phase * 0.4) * 0.06
