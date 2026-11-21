extends CanvasLayer

var player_path: NodePath
var player: Node
var hud_root: Control
var joystick_base: Panel
var joystick_knob: Panel
var joystick_radius := 0.0
var knob_size := 0.0

func _ready() -> void:
    player = get_node_or_null(player_path)
    hud_root = Control.new()
    hud_root.name = "HUDRoot"
    hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hud_root)

    _build_joystick()
    _build_camera_button()
    _build_jump_button()
    hud_root.resized.connect(_layout_joystick)
    call_deferred("_layout_joystick")

func _process(_delta: float) -> void:
    if is_instance_valid(player) and joystick_knob != null:
        var center := joystick_base.size * 0.5
        joystick_knob.position = center + player.move_touch * (joystick_radius * 0.58) - joystick_knob.size * 0.5

func _build_joystick() -> void:
    joystick_base = Panel.new()
    joystick_base.name = "JoystickBase"
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.06, 0.09, 0.12, 0.42)
    base_style.border_color = Color(0.82, 0.91, 1.0, 0.62)
    base_style.set_border_width_all(3)
    base_style.set_corner_radius_all(999)
    joystick_base.add_theme_stylebox_override("panel", base_style)
    hud_root.add_child(joystick_base)

    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.72, 0.84, 0.94, 0.72)
    knob_style.border_color = Color(1.0, 1.0, 1.0, 0.85)
    knob_style.set_border_width_all(2)
    knob_style.set_corner_radius_all(999)
    joystick_knob.add_theme_stylebox_override("panel", knob_style)
    joystick_base.add_child(joystick_knob)

func _layout_joystick() -> void:
    if joystick_base == null:
        return
    var viewport_size := get_viewport().get_visible_rect().size
    joystick_radius = minf(viewport_size.x, viewport_size.y) * 0.14
    var diameter := joystick_radius * 2.0
    var center := Vector2(viewport_size.x * 0.22, viewport_size.y * 0.78)
    joystick_base.position = center - Vector2.ONE * joystick_radius
    joystick_base.size = Vector2.ONE * diameter
    knob_size = joystick_radius * 0.78
    joystick_knob.size = Vector2.ONE * knob_size
    joystick_knob.position = (joystick_base.size - joystick_knob.size) * 0.5

func _build_camera_button() -> void:
    var camera_button := Button.new()
    camera_button.text = "КАМЕРА"
    camera_button.anchor_left = 1.0
    camera_button.anchor_right = 1.0
    camera_button.anchor_top = 0.0
    camera_button.anchor_bottom = 0.0
    camera_button.offset_left = -150.0
    camera_button.offset_top = 24.0
    camera_button.offset_right = -24.0
    camera_button.offset_bottom = 82.0
    camera_button.add_theme_font_size_override("font_size", 20)
    camera_button.pressed.connect(_on_camera_pressed)
    hud_root.add_child(camera_button)

func _build_jump_button() -> void:
    var jump_button := Button.new()
    jump_button.text = "ПРЫЖОК"
    jump_button.anchor_left = 1.0
    jump_button.anchor_top = 1.0
    jump_button.anchor_right = 1.0
    jump_button.anchor_bottom = 1.0
    jump_button.offset_left = -166.0
    jump_button.offset_top = -116.0
    jump_button.offset_right = -24.0
    jump_button.offset_bottom = -30.0
    jump_button.add_theme_font_size_override("font_size", 18)
    jump_button.pressed.connect(_on_jump_pressed)
    hud_root.add_child(jump_button)

func _on_camera_pressed() -> void:
    if is_instance_valid(player):
        player.toggle_camera()

func _on_jump_pressed() -> void:
    if is_instance_valid(player):
        player.request_jump()
