extends Node3D

var hero: ArenaHero
var enemies: Array[ArenaHero] = []
var joystick_vector := Vector2.ZERO
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var attack_button: Button
var skill_button: Button
var dash_button: Button
var health_bar: ProgressBar
var status_label: Label
var match_time := 0.0
var kills := 0
var match_over := false

func _ready() -> void:
	_build_world()
	_spawn_fighters()
	_build_hud()
	hero.health_changed.connect(_on_health_changed)
	_on_health_changed(hero.health, hero.max_health)
	hero.defeated.connect(_on_hero_defeated)
	for e in enemies:
		e.defeated.connect(_on_enemy_defeated)
		e.target = hero
	_update_hud()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018,0.025,0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35,0.43,0.68)
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-35,0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(44,44)
	floor.mesh = plane
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.055,0.075,0.12)
	fm.roughness = 0.9
	floor.material_override = fm
	add_child(floor)
	var arena_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 18.8
	torus.outer_radius = 19.15
	arena_ring.mesh = torus
	arena_ring.rotation_degrees.x = 90
	arena_ring.position.y = 0.08
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.1,0.75,0.95)
	rm.emission_enabled = true
	rm.emission = Color(0.04,0.32,0.6)
	arena_ring.material_override = rm
	add_child(arena_ring)
	for i in range(12):
		var angle := TAU * float(i)/12.0
		_add_pillar(Vector3(cos(angle)*16.5,0,sin(angle)*16.5), i)
	for x in range(-2,3):
		for z in range(-2,3):
			if abs(x)+abs(z) > 2:
				continue
			_add_rune(Vector3(x*4.0,0.035,z*4.0))
	var camera := Camera3D.new()
	camera.position = Vector3(0,25,24)
	camera.rotation_degrees = Vector3(-42,0,0)
	camera.current = true
	camera.fov = 55
	add_child(camera)

func _add_pillar(pos: Vector3, index: int) -> void:
	var p := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.72
	mesh.height = 3.8
	p.mesh = mesh
	p.position = pos + Vector3.UP*1.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12,0.16,0.25) if index%2==0 else Color(0.19,0.11,0.24)
	mat.metallic = 0.55
	p.material_override = mat
	add_child(p)
	var crystal := MeshInstance3D.new()
	var c := PrismMesh.new()
	c.size = Vector3(0.6,0.9,0.6)
	crystal.mesh = c
	crystal.position = pos + Vector3.UP*4.1
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.12,0.75,1.0)
	cm.emission_enabled = true
	cm.emission = Color(0.05,0.5,1.0)
	crystal.material_override = cm
	add_child(crystal)
	var light := OmniLight3D.new()
	light.position = crystal.position
	light.light_color = Color(0.1,0.55,1.0)
	light.light_energy = 0.8
	light.omni_range = 5
	add_child(light)

func _add_rune(pos: Vector3) -> void:
	var r := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.7,0.045,0.12)
	r.mesh = mesh
	r.position = pos
	r.rotation.y = PI/4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25,0.12,0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.18,0.06,0.5)
	r.material_override = mat
	add_child(r)

func _spawn_fighters() -> void:
	hero = ArenaHero.new()
	hero.name = "Kairon"
	hero.position = Vector3(0,0,8)
	hero.team = 0
	hero.max_health = 260
	hero.health = 260
	hero.move_speed = 8.0
	hero.attack_damage = 34
	add_child(hero)
	hero.add_to_group("fighters")
	for i in range(3):
		var enemy := ArenaHero.new()
		enemy.name = ["Rift Stalker","Ash Warden","Void Reaver"][i]
		enemy.is_enemy = true
		enemy.team = 1
		enemy.max_health = 150 + i*35
		enemy.health = enemy.max_health
		enemy.attack_damage = 12 + i*3
		enemy.move_speed = 3.2 + i*0.25
		enemy.position = Vector3(-7+i*7,0,-7-(i%2)*3)
		add_child(enemy)
		enemy.add_to_group("fighters")
		enemies.append(enemy)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var title := Label.new()
	title.text = "SHADOW ARENA     •     РЕЖИМ: ВЫЖИВАНИЕ"
	title.position = Vector2(28,18)
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color(0.55,0.88,1))
	root.add_child(title)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(28,58)
	health_bar.size = Vector2(260,22)
	health_bar.max_value = 260
	health_bar.show_percentage = false
	root.add_child(health_bar)
	status_label = Label.new()
	status_label.position = Vector2(28,88)
	status_label.add_theme_font_size_override("font_size",18)
	root.add_child(status_label)
	var hint := Label.new()
	hint.text = "КАЙРОН  •  ХРАНИТЕЛЬ РАЗЛОМА"
	hint.position = Vector2(28,118)
	hint.add_theme_font_size_override("font_size",16)
	hint.add_theme_color_override("font_color",Color(0.65,0.72,0.88))
	root.add_child(hint)
	attack_button = _make_button(root,"УДАР",Vector2(-250,-120),Color(0.78,0.18,0.25))
	skill_button = _make_button(root,"РАЗЛОМ",Vector2(-130,-230),Color(0.35,0.2,0.78))
	dash_button = _make_button(root,"РЫВОК",Vector2(-135,-95),Color(0.08,0.52,0.72))
	attack_button.pressed.connect(_attack)
	skill_button.pressed.connect(_skill)
	dash_button.pressed.connect(_dash)
	var joystick_hint := Label.new()
	joystick_hint.text = "ДВИЖЕНИЕ"
	joystick_hint.position = Vector2(42,-62)
	joystick_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_hint.add_theme_color_override("font_color",Color(0.6,0.75,0.9,0.7))
	root.add_child(joystick_hint)
	var objective := Label.new()
	objective.text = "ЦЕЛЬ: ПОБЕДИ ВСЕХ ПРОТИВНИКОВ"
	objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective.position = Vector2(-180,18)
	objective.add_theme_font_size_override("font_size",18)
	objective.add_theme_color_override("font_color",Color(1,0.8,0.42))
	root.add_child(objective)

func _make_button(parent: Control, caption: String, offset: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text = caption
	b.size = Vector2(104,104) if caption!="УДАР" else Vector2(118,118)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.position = offset
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_color_override("font_color",Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(54)
	b.add_theme_stylebox_override("normal",style)
	b.add_theme_stylebox_override("hover",style)
	b.add_theme_stylebox_override("pressed",style)
	parent.add_child(b)
	return b

func _input(event: InputEvent) -> void:
	if match_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x*0.48 and joystick_touch == -1:
			joystick_touch = event.index
			joystick_origin = event.position
		elif not event.pressed and event.index == joystick_touch:
			joystick_touch = -1
			joystick_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		joystick_vector = (event.position-joystick_origin)/75.0
		if joystick_vector.length() > 1.0:
			joystick_vector = joystick_vector.normalized()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x*0.48:
			joystick_touch = 999
			joystick_origin = event.position
		elif not event.pressed:
			joystick_touch = -1
			joystick_vector = Vector2.ZERO
	elif event is InputEventMouseMotion and joystick_touch == 999:
		joystick_vector = (event.position-joystick_origin)/75.0
		if joystick_vector.length() > 1.0:
			joystick_vector = joystick_vector.normalized()

func _process(delta: float) -> void:
	if match_over:
		return
	match_time += delta
	if is_instance_valid(hero):
		hero.joystick = joystick_vector
	_update_hud()

func _attack() -> void:
	if not is_instance_valid(hero):
		return
	var nearest: ArenaHero
	var best := 3.5
	for e in enemies:
		if is_instance_valid(e):
			var d := hero.global_position.distance_to(e.global_position)
			if d < best:
				best = d
				nearest = e
	if nearest:
		nearest.take_damage(hero.attack_damage,hero)

func _skill() -> void:
	if is_instance_valid(hero):
		hero.cast_skill()

func _dash() -> void:
	if is_instance_valid(hero):
		hero.dash(joystick_vector)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func _on_enemy_defeated() -> void:
	kills += 1
	_update_hud()
	if kills >= 3:
		match_over = true
		status_label.text = "ПОБЕДА! АРЕНА ОЧИЩЕНА"

func _on_hero_defeated() -> void:
	match_over = true
	status_label.text = "ПОРАЖЕНИЕ — ПОПРОБУЙ ЕЩЁ РАЗ"

func _update_hud() -> void:
	if status_label and not match_over:
		status_label.text = "ВРАГИ: %d/3     ВРЕМЯ: %02d:%02d" % [kills,int(match_time)/60,int(match_time)%60]
