extends Node3D

var hero: ArenaHero
var enemies: Array[ArenaHero] = []
var joystick_vector := Vector2.ZERO
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var attack_button: Button
var skill_button: Button
var dash_button: Button
var heroes_button: Button
var health_bar: ProgressBar
var status_label: Label
var match_time := 0.0
var kills := 0
var match_over := false
var follow_camera: Camera3D
var world: Wildlands

func _ready() -> void:
	_build_world()
	_spawn_fighters()
	_spawn_wildlife()
	_build_hud()
	hero.health_changed.connect(_on_health_changed)
	_on_health_changed(hero.health, hero.max_health)
	hero.defeated.connect(_on_hero_defeated)
	for e in enemies:
		e.defeated.connect(_on_enemy_defeated)
		e.target = hero
	_update_hud()

func _build_world() -> void:
	world = Wildlands.new()
	world.name = "OpenWorld"
	add_child(world)
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
	follow_camera = Camera3D.new()
	follow_camera.position = Vector3(0,25,24)
	follow_camera.current = true
	follow_camera.fov = 58
	add_child(follow_camera)

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
	hero.position = Vector3(0,Wildlands.terrain_height(0,8)+0.08,8)
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
		enemy.position = Vector3(-7+i*7,Wildlands.terrain_height(-7+i*7,-7-(i%2)*3)+0.08,-7-(i%2)*3)
		enemy.target = hero
		add_child(enemy)
		enemy.add_to_group("fighters")
		enemies.append(enemy)

func _spawn_wildlife() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99172
	for i in range(14):
		var wolf := WildCreature.new()
		wolf.species = "Волк"
		wolf.health = 85.0
		wolf.move_speed = 4.8
		wolf.damage = 9.0
		var wx := rng.randf_range(-300,300)
		var wz := rng.randf_range(-300,300)
		wolf.position = Vector3(wx,Wildlands.terrain_height(wx,wz)+0.08,wz)
		wolf.target = hero
		add_child(wolf)
		wolf.add_to_group("wild_creatures")
	for i in range(5):
		var bear := WildCreature.new()
		bear.species = "Медведь"
		bear.health = 240.0
		bear.move_speed = 2.8
		bear.damage = 22.0
		bear.aggro_range = 15.0
		var bx := rng.randf_range(-360,360)
		var bz := rng.randf_range(-360,360)
		bear.position = Vector3(bx,Wildlands.terrain_height(bx,bz)+0.08,bz)
		bear.target = hero
		add_child(bear)
		bear.add_to_group("wild_creatures")
	var dragon_scene: PackedScene = preload("res://scenes/Dragon.tscn")
	for i in range(2):
		var dragon := dragon_scene.instantiate() as DragonCreature
		dragon.position = Vector3(-260+i*520,Wildlands.terrain_height(-260+i*520,-320)+0.8,-320)
		dragon.target = hero
		add_child(dragon)

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
	heroes_button = _make_button(root,"ГЕРОИ",Vector2(-270,-245),Color(0.18,0.38,0.58))
	heroes_button.pressed.connect(_open_heroes)
	var joystick_base := Panel.new()
	joystick_base.name = "VirtualJoystickBase"
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.position = Vector2(34,-204)
	joystick_base.size = Vector2(168,168)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.08,0.12,0.2,0.52)
	base_style.border_color = Color(0.55,0.78,1.0,0.85)
	base_style.set_border_width_all(3)
	base_style.set_corner_radius_all(84)
	joystick_base.add_theme_stylebox_override("panel",base_style)
	root.add_child(joystick_base)
	var joystick_knob := Panel.new()
	joystick_knob.name = "VirtualJoystickKnob"
	joystick_knob.size = Vector2(76,76)
	joystick_knob.position = Vector2(46,46)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.32,0.68,0.95,0.9)
	knob_style.border_color = Color(0.85,0.95,1.0)
	knob_style.set_border_width_all(3)
	knob_style.set_corner_radius_all(38)
	joystick_knob.add_theme_stylebox_override("panel",knob_style)
	joystick_base.add_child(joystick_knob)
	joystick_base.gui_input.connect(_on_joystick_gui_input.bind(joystick_base,joystick_knob))
	var objective := Label.new()
	objective.text = "СВОБОДНОЕ ИССЛЕДОВАНИЕ • ВЫЖИВАНИЕ"
	objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective.position = Vector2(-220,18)
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

func _on_joystick_gui_input(event: InputEvent, base: Control, knob: Control) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_update_joystick(event.position,base,knob)
		else:
			_reset_joystick(base,knob)
		base.accept_event()
	elif event is InputEventScreenDrag:
		_update_joystick(event.position,base,knob)
		base.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_joystick(event.position,base,knob)
		else:
			_reset_joystick(base,knob)
		base.accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_joystick(event.position,base,knob)
		base.accept_event()

func _update_joystick(local_position: Vector2, base: Control, knob: Control) -> void:
	var center := base.size * 0.5
	var offset := local_position - center
	var max_radius := 48.0
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	joystick_vector = offset / max_radius
	knob.position = center + offset - knob.size * 0.5

func _reset_joystick(base: Control, knob: Control) -> void:
	joystick_vector = Vector2.ZERO
	knob.position = (base.size - knob.size) * 0.5

func _process(delta: float) -> void:
	if match_over:
		return
	match_time += delta
	if is_instance_valid(hero):
		hero.joystick = joystick_vector
		if is_instance_valid(follow_camera):
			var desired := hero.global_position + Vector3(0,32,30)
			follow_camera.global_position = follow_camera.global_position.lerp(desired,delta*3.0)
			follow_camera.look_at(hero.global_position+Vector3(0,1,0),Vector3.UP)
	_update_hud()

func _attack() -> void:
	if not is_instance_valid(hero):
		return
	var nearest: Node3D
	var best := 3.5
	for e in enemies:
		if is_instance_valid(e):
			var d := hero.global_position.distance_to(e.global_position)
			if d < best:
				best = d
				nearest = e
	for creature in get_tree().get_nodes_in_group("wild_creatures"):
		if is_instance_valid(creature):
			var d := hero.global_position.distance_to(creature.global_position)
			if d < best:
				best = d
				nearest = creature
	if nearest and nearest.has_method("take_damage"):
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

func _on_hero_defeated() -> void:
	match_over = true
	status_label.text = "ПОРАЖЕНИЕ — ПОПРОБУЙ ЕЩЁ РАЗ"

func _update_hud() -> void:
	if status_label and not match_over:
		status_label.text = "ПОБЕЖДЕНО ПРОТИВНИКОВ: %d     ВРЕМЯ: %02d:%02d" % [kills,int(match_time)/60,int(match_time)%60]

func _open_heroes() -> void:
	get_tree().change_scene_to_file("res://scenes/hero_gallery.tscn")
