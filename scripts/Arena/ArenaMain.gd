extends Node3D

const UnitScript = preload("res://scripts/Arena/ArenaUnit.gd")
const DRAGON_SCRIPT = preload("res://scripts/ProceduralDragon.gd")

var units: Array = []
var structures: Array = []
var move_input := Vector2.ZERO
var match_started := false
var match_time := 0.0
var player: ArenaUnit
var arena_camera: Camera3D
var action_buttons: Array[Button] = []
var blue_core: StaticBody3D
var red_core: StaticBody3D
var hud: CanvasLayer
var menu_layer: Control
var status_label: Label
var health_label: Label
var cooldowns := [0.0, 0.0, 0.0, 0.0, 0.0]
var skill_damage := [0.0, 105.0, 145.0, 190.0, 310.0]
var skill_radius := [0.0, 4.0, 5.0, 6.5, 8.0]

func _ready() -> void:
    _build_world()
    _build_menu()

func _process(delta: float) -> void:
    if not match_started:
        return
    match_time += delta
    for i in range(5):
        cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
    if is_instance_valid(player):
        health_label.text = "HP %d / %d" % [int(player.health), int(player.max_health)]
        if is_instance_valid(arena_camera):
            var desired := player.global_position + Vector3(0.0, 66.0, 52.0)
            arena_camera.global_position = arena_camera.global_position.lerp(desired, minf(1.0, delta * 3.5))
            arena_camera.look_at(player.global_position, Vector3.UP)
    for i in range(action_buttons.size()):
        var caption := ["АТАКА", "НАВЫК 1", "НАВЫК 2", "НАВЫК 3", "УЛЬТА"][i]
        if i == 0:
            action_buttons[i].text = caption
        elif cooldowns[i] > 0.0:
            action_buttons[i].text = "%s\n%.1f" % [caption, cooldowns[i]]
        else:
            action_buttons[i].text = caption
    status_label.text = "ATLAS WILDS ARENA     %02d:%02d     СИНИЕ %d : %d КРАСНЫЕ" % [int(match_time / 60.0), int(match_time) % 60, _team_alive(0), _team_alive(1)]

func _build_world() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.52, 0.62, 0.72)
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)
    arena_camera = Camera3D.new()
    arena_camera.name = "ArenaCamera"
    arena_camera.position = Vector3(0.0, 67.0, 54.0)
    arena_camera.current = true
    arena_camera.fov = 48.0
    add_child(arena_camera)
    arena_camera.look_at(Vector3.ZERO, Vector3.UP)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)
    _box(self, "ArenaGround", Vector3(0, -0.6, 0), Vector3(150, 1.2, 110), Color(0.16, 0.28, 0.19), true)
    _box(self, "River", Vector3(0, 0.02, 0), Vector3(10.0, 0.12, 100), Color(0.12, 0.42, 0.58), false)
    for lane_z in [-34.0, 0.0, 34.0]:
        _box(self, "Lane", Vector3(0, 0.04, lane_z), Vector3(132, 0.1, 6.4), Color(0.42, 0.39, 0.29), false)
        for x in range(-62, 63, 9):
            _make_rock(Vector3(float(x), 0.0, lane_z + 5.5))
    for i in range(42):
        var x := randf_range(-68.0, 68.0)
        var z := randf_range(-50.0, 50.0)
        if absf(z) > 7.0:
            _make_tree(Vector3(x, 0.0, z))
    blue_core = _make_core(-68.0, Color(0.2, 0.55, 1.0), "BlueCore")
    red_core = _make_core(68.0, Color(1.0, 0.24, 0.18), "RedCore")
    for lane_z in [-34.0, 0.0, 34.0]:
        for x in [-48.0, -30.0, -12.0]:
            _make_tower(x, lane_z, 0)
        for x in [12.0, 30.0, 48.0]:
            _make_tower(x, lane_z, 1)

func _build_menu() -> void:
    menu_layer = Control.new()
    menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(menu_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.025, 0.045, 0.075, 0.92)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(shade)
    var title := Label.new()
    title.text = "ATLAS WILDS\nARENA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 54)
    title.anchor_left = 0.15
    title.anchor_right = 0.85
    title.anchor_top = 0.22
    title.anchor_bottom = 0.52
    menu_layer.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "3D MOBA  •  5 НА 5  •  ОФЛАЙН"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.anchor_left = 0.15
    subtitle.anchor_right = 0.85
    subtitle.anchor_top = 0.52
    subtitle.anchor_bottom = 0.62
    subtitle.add_theme_font_size_override("font_size", 20)
    menu_layer.add_child(subtitle)
    var play := Button.new()
    play.text = "НАЧАТЬ МАТЧ"
    play.anchor_left = 0.34
    play.anchor_right = 0.66
    play.anchor_top = 0.68
    play.anchor_bottom = 0.81
    play.add_theme_font_size_override("font_size", 24)
    play.pressed.connect(_start_match)
    menu_layer.add_child(play)

func _start_match() -> void:
    if match_started:
        return
    match_started = true
    menu_layer.visible = false
    _spawn_team()
    _build_hud()
    _spawn_minion_wave()
    var wave_timer := Timer.new()
    wave_timer.wait_time = 18.0
    wave_timer.timeout.connect(_spawn_minion_wave)
    wave_timer.autostart = true
    add_child(wave_timer)
    var tower_timer := Timer.new()
    tower_timer.wait_time = 1.0
    tower_timer.timeout.connect(_tower_fire)
    tower_timer.autostart = true
    add_child(tower_timer)

func _spawn_team() -> void:
    for i in range(10):
        var team := 0 if i < 5 else 1
        var unit: ArenaUnit = UnitScript.new()
        unit.name = "BlueHero_%d" % i if team == 0 else "RedHero_%d" % (i - 5)
        unit.team = team
        unit.is_player = i == 0
        unit.arena = self
        unit.max_health = 950.0 if i == 0 else 720.0
        unit.attack_damage = 68.0 if i == 0 else 42.0
        unit.move_speed = 6.2 if i == 0 else 4.6
        add_child(unit)
        var side := -1.0 if team == 0 else 1.0
        unit.global_position = Vector3(side * (57.0 if i == 0 else 54.0), 0.0, float((i % 5) - 2) * 2.8)
        units.append(unit)
        if i == 0:
            player = unit
    for unit in units:
        if unit != player:
            unit.target = null

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(root)
    status_label = Label.new()
    status_label.position = Vector2(12, 8)
    status_label.add_theme_font_size_override("font_size", 18)
    root.add_child(status_label)
    health_label = Label.new()
    health_label.position = Vector2(14, 42)
    health_label.add_theme_font_size_override("font_size", 20)
    root.add_child(health_label)
    _add_action_button(root, "АТАКА", Vector2(-150, -100), 0, Color(0.8, 0.22, 0.12))
    _add_action_button(root, "НАВЫК 1", Vector2(-300, -95), 1, Color(0.2, 0.55, 0.95))
    _add_action_button(root, "НАВЫК 2", Vector2(-445, -95), 2, Color(0.22, 0.7, 0.8))
    _add_action_button(root, "НАВЫК 3", Vector2(-590, -95), 3, Color(0.65, 0.32, 0.88))
    _add_action_button(root, "УЛЬТА", Vector2(-735, -95), 4, Color(0.95, 0.68, 0.16))
    var joystick := Control.new()
    joystick.position = Vector2(18, -180)
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.size = Vector2(150, 150)
    root.add_child(joystick)
    var pad := ColorRect.new()
    pad.color = Color(0.8, 0.9, 1.0, 0.16)
    pad.size = Vector2(150, 150)
    pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick.add_child(pad)
    var knob := ColorRect.new()
    knob.name = "Knob"
    knob.color = Color(0.7, 0.85, 1.0, 0.45)
    knob.position = Vector2(48, 48)
    knob.size = Vector2(54, 54)
    knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick.add_child(knob)
    joystick.gui_input.connect(func(event: InputEvent):
        if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseMotion:
            var p := joystick.get_local_mouse_position() - Vector2(75, 75)
            move_input = (p / 62.0).limit_length(1.0)
            knob.position = Vector2(48, 48) + move_input * 36.0
            if event is InputEventScreenTouch and not event.pressed:
                move_input = Vector2.ZERO
                knob.position = Vector2(48, 48)
    )
    var back := Button.new()
    back.text = "БАЗА"
    back.anchor_left = 1.0
    back.anchor_right = 1.0
    back.anchor_top = 0.0
    back.anchor_bottom = 0.0
    back.offset_left = -120
    back.offset_right = -16
    back.offset_top = 18
    back.offset_bottom = 64
    back.pressed.connect(func(): player.global_position = Vector3(-62, 0, 0))
    root.add_child(back)

func _add_action_button(root: Control, caption: String, offset: Vector2, index: int, tint: Color) -> void:
    var button := Button.new()
    button.text = caption
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = offset.x
    button.offset_right = offset.x + 126
    button.offset_top = offset.y
    button.offset_bottom = offset.y + 72
    button.add_theme_font_size_override("font_size", 15)
    var style := StyleBoxFlat.new()
    style.bg_color = tint
    style.set_corner_radius_all(18)
    button.add_theme_stylebox_override("normal", style)
    button.pressed.connect(_on_action_pressed.bind(index))
    action_buttons.append(button)
    root.add_child(button)

func _on_action_pressed(index: int) -> void:\n    _use_skill(index)\n\nfunc _use_skill(index: int) -> void:
    if not match_started or not is_instance_valid(player) or player.health <= 0.0:
        return
    if cooldowns[index] > 0.0:
        status_label.text = "НАВЫК ПЕРЕЗАРЯЖАЕТСЯ"
        return
    var target_range: float = 8.0 if index == 0 else 34.0
    var target: Node3D = _nearest_enemy(player.global_position, target_range)
    if target == null:
        status_label.text = "НЕТ ВРАГА В РАДИУСЕ — ПОДОЙДИ БЛИЖЕ"
        return
    var cooldown: float = [0.65, 5.0, 8.0, 18.0, 24.0][index]
    cooldowns[index] = cooldown
    if index == 0:
        apply_damage(target, 105.0)
        _show_hit_effect(target.global_position, 2.0, Color(1.0, 0.72, 0.22))
        status_label.text = "УДАР ПО ЦЕЛИ"
        return
    var damage: float = skill_damage[index]
    var radius: float = skill_radius[index]
    var impact_position := target.global_position
    if index == 1:
        # Dragon rush: leap toward the selected enemy and strike.
        var direction := (target.global_position - player.global_position).normalized()
        player.global_position += direction * minf(8.0, player.global_position.distance_to(target.global_position) - 2.0)
        impact_position = target.global_position
    _show_hit_effect(impact_position, radius, [Color.WHITE, Color(0.2, 0.75, 1.0), Color(0.3, 1.0, 0.65), Color(0.8, 0.25, 1.0), Color(1.0, 0.45, 0.12)][index])
    for enemy in units:
        if is_instance_valid(enemy) and enemy is ArenaUnit and enemy.team != player.team and enemy.health > 0.0:
            if impact_position.distance_to(enemy.global_position) <= radius + 2.0:
                apply_damage(enemy, damage)
    status_label.text = "НАВЫК %d: ПОПАДАНИЕ" % index

func _show_hit_effect(pos: Vector3, radius: float, tint: Color) -> void:
    var effect := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.35
    sphere.height = 0.7
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.emission_enabled = true
    mat.emission = tint
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = 0.62
    sphere.material = mat
    effect.mesh = sphere
    effect.position = pos + Vector3.UP * 0.8
    effect.scale = Vector3.ONE * maxf(1.0, radius * 0.65)
    add_child(effect)
    var tween := create_tween()
    tween.tween_property(effect, "scale", Vector3.ONE * radius, 0.22)
    tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
    tween.tween_callback(effect.queue_free)

func apply_damage(target: Node, amount: float) -> void:
    if target is ArenaUnit:
        target.take_damage(amount)
    elif target is StaticBody3D and target.has_meta("health"):
        var hp: float = float(target.get_meta("health")) - amount
        target.set_meta("health", hp)
        if hp <= 0.0:
            target.queue_free()
            if target == red_core:
                _finish_match(true)
            elif target == blue_core:
                _finish_match(false)

func on_unit_killed(unit: ArenaUnit) -> void:
    if unit.is_player:
        health_label.text = "ДРАКОН ПОВЕРЖЕН — ВОЗРОЖДЕНИЕ 7 СЕК."

func _team_alive(team: int) -> int:
    var count := 0
    for unit in units:
        if is_instance_valid(unit) and unit.team == team and unit.health > 0.0:
            count += 1
    return count

func _nearest_enemy(from: Vector3, radius: float) -> Node3D:
    var best: Node3D
    var best_distance := radius
    for unit in units:
        if is_instance_valid(unit) and unit.team == 1 and unit.health > 0.0:
            var d: float = from.distance_to(unit.global_position)
            if d < best_distance:
                best_distance = d
                best = unit
    return best

func _spawn_minion_wave() -> void:
    if not match_started:
        return
    for team in [0, 1]:
        for lane in [-25.0, 0.0, 25.0]:
            for n in range(2):
                var minion: ArenaUnit = UnitScript.new()
                minion.name = "Minion_%d" % randi()
                minion.team = team
                minion.max_health = 210.0
                minion.attack_damage = 24.0
                minion.move_speed = 3.5
                minion.attack_range = 2.0
                minion.arena = self
                add_child(minion)
                minion.global_position = Vector3(-63.0 if team == 0 else 63.0, 0.0, lane + float(n) * 1.8)
                units.append(minion)

func _tower_fire() -> void:
    for tower in structures:
        if not is_instance_valid(tower):
            continue
        var team := int(tower.get_meta("team"))
        var best: Node3D
        var best_distance := 12.0
        for unit in units:
            if is_instance_valid(unit) and unit.team != team and unit.health > 0.0:
                var d: float = tower.global_position.distance_to(unit.global_position)
                if d < best_distance:
                    best_distance = d
                    best = unit
        if best != null:
            apply_damage(best, 36.0)

func _make_core(x: float, color: Color, label: String) -> StaticBody3D:
    var core := StaticBody3D.new()
    core.name = label
    core.position = Vector3(x, 1.8, 0)
    add_child(core)
    var mesh_node := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 2.2
    sphere.height = 4.4
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 0.8
    sphere.material = material
    mesh_node.mesh = sphere
    core.add_child(mesh_node)
    core.set_meta("team", 0 if x < 0 else 1)
    core.set_meta("health", 3000.0)
    return core

func _make_tower(x: float, z: float, team: int) -> void:
    var tower := StaticBody3D.new()
    tower.name = "Tower_%d_%d" % [team, structures.size()]
    tower.position = Vector3(x, 1.8, z)
    add_child(tower)
    var pillar := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.72
    mesh.bottom_radius = 1.05
    mesh.height = 3.6
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.48, 0.95) if team == 0 else Color(0.9, 0.22, 0.18)
    material.metallic = 0.25
    material.roughness = 0.35
    mesh.material = material
    pillar.mesh = mesh
    tower.add_child(pillar)
    tower.set_meta("team", team)
    structures.append(tower)

func _make_tree(pos: Vector3) -> void:
    var trunk := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.18
    cylinder.bottom_radius = 0.3
    cylinder.height = 2.4
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.24, 0.15, 0.09)
    cylinder.material = bark
    trunk.mesh = cylinder
    trunk.position = pos + Vector3(0, 1.2, 0)
    add_child(trunk)
    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.35
    sphere.height = 2.5
    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.1, randf_range(0.22, 0.36), 0.13)
    sphere.material = leaves
    crown.mesh = sphere
    crown.position = pos + Vector3(0, 2.8, 0)
    add_child(crown)

func _make_rock(pos: Vector3) -> void:
    var rock := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = randf_range(0.7, 1.3)
    mesh.height = mesh.radius * 1.2
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.26, 0.3, 0.28)
    mesh.material = mat
    rock.mesh = mesh
    rock.position = pos + Vector3(0, 0.45, 0)
    rock.scale = Vector3(1.3, 0.7, 0.8)
    add_child(rock)

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.92
    mesh.material = mat
    node.mesh = mesh
    node.position = pos
    parent.add_child(node)
    if collision:
        var body := StaticBody3D.new()
        body.position = pos
        parent.add_child(body)
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        body.add_child(shape)

func _finish_match(victory: bool) -> void:
    match_started = false
    var overlay := ColorRect.new()
    overlay.color = Color(0.02, 0.03, 0.06, 0.9)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(overlay)
    var result := Label.new()
    result.text = "ПОБЕДА!" if victory else "ПОРАЖЕНИЕ"
    result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    result.add_theme_font_size_override("font_size", 54)
    overlay.add_child(result)
    var again := Button.new()
    again.text = "В ГЛАВНОЕ МЕНЮ"
    again.anchor_left = 0.35
    again.anchor_right = 0.65
    again.anchor_top = 0.72
    again.anchor_bottom = 0.84
    again.pressed.connect(func(): get_tree().reload_current_scene())
    overlay.add_child(again)
