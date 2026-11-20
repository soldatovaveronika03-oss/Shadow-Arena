extends Node3D

var preview: Node3D
var preview_holder: Node3D
var info: Label
var current_index := 0

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.012,0.018,0.04)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55,0.62,0.85)
	e.ambient_light_energy = 0.9
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-25,0)
	sun.light_energy = 1.8
	add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14,14)
	floor.mesh = plane
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.055,0.07,0.12)
	floor.material_override = fm
	add_child(floor)
	var camera := Camera3D.new()
	camera.position = Vector3(0,3.1,7.8)
	camera.look_at(Vector3(0,1.25,0))
	camera.current = true
	add_child(camera)
	preview_holder = Node3D.new()
	add_child(preview_holder)
	_build_ui()
	_show_hero(0)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var heading := Label.new()
	heading.text = "SHADOW ARENA  •  30 ГЕРОЕВ"
	heading.position = Vector2(24,14)
	heading.add_theme_font_size_override("font_size",26)
	heading.add_theme_color_override("font_color",Color(0.55,0.88,1))
	root.add_child(heading)
	var back := Button.new()
	back.text = "НАЗАД В БОЙ"
	back.position = Vector2(24,58)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	root.add_child(back)
	info = Label.new()
	info.position = Vector2(24,105)
	info.size = Vector2(520,220)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size",18)
	info.add_theme_color_override("font_color",Color(0.9,0.92,1))
	root.add_child(info)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24,340)
	scroll.size = Vector2(620,330)
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for i in range(HeroCatalog.HEROES.size()):
		var data: Dictionary = HeroCatalog.HEROES[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(185,66)
		b.text = "%02d  %s\n%s • %s" % [i+1,data.name,data.role,data.element]
		b.add_theme_font_size_override("font_size",14)
		b.pressed.connect(_show_hero.bind(i))
		grid.add_child(b)

func _show_hero(index: int) -> void:
	current_index = index
	if is_instance_valid(preview):
		preview.queue_free()
	var data: Dictionary = HeroCatalog.HEROES[index]
	preview = HeroCatalog.build_model(data)
	preview_holder.add_child(preview)
	info.text = "%s — %s\nРОЛЬ: %s    СТИХИЯ: %s\nЗДОРОВЬЕ: %d\n\nI. %s\n\nII. %s\n\nУЛЬТА: %s" % [data.name,data.title,data.role,data.element,data.hp,data.s1,data.s2,data.ult]

func _process(delta: float) -> void:
	if is_instance_valid(preview):
		preview.rotation.y += delta * 0.45
