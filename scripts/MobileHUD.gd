extends CanvasLayer

var player_path: NodePath
var player: Node

func _ready() -> void:
    player = get_node_or_null(player_path)
    var camera_button := Button.new()
    camera_button.text = "КАМЕРА"
    camera_button.anchor_left = 1.0
    camera_button.anchor_right = 1.0
    camera_button.anchor_top = 0.0
    camera_button.anchor_bottom = 0.0
    camera_button.offset_left = -150
    camera_button.offset_top = 24
    camera_button.offset_right = -24
    camera_button.offset_bottom = 82
    camera_button.add_theme_font_size_override("font_size", 20)
    camera_button.pressed.connect(_on_camera_pressed)
    add_child(camera_button)

    var jump_button := Button.new()
    jump_button.text = "ПРЫЖОК"
    jump_button.anchor_left = 1.0
    jump_button.anchor_top = 1.0
    jump_button.anchor_right = 1.0
    jump_button.anchor_bottom = 1.0
    jump_button.offset_left = -166
    jump_button.offset_top = -116
    jump_button.offset_right = -24
    jump_button.offset_bottom = -30
    jump_button.add_theme_font_size_override("font_size", 18)
    jump_button.pressed.connect(_on_jump_pressed)
    add_child(jump_button)

    var sprint_button := Button.new()
    sprint_button.text = "БЕГ"
    sprint_button.anchor_left = 0.0
    sprint_button.anchor_top = 1.0
    sprint_button.anchor_right = 0.0
    sprint_button.anchor_bottom = 1.0
    sprint_button.offset_left = 24
    sprint_button.offset_top = -92
    sprint_button.offset_right = 112
    sprint_button.offset_bottom = -30
    sprint_button.add_theme_font_size_override("font_size", 18)
    sprint_button.button_down.connect(_on_sprint_down)
    sprint_button.button_up.connect(_on_sprint_up)
    add_child(sprint_button)

func _on_camera_pressed() -> void:
    if is_instance_valid(player):
        player.toggle_camera()

func _on_jump_pressed() -> void:
    if is_instance_valid(player):
        player.request_jump()

func _on_sprint_down() -> void:
    if is_instance_valid(player):
        player.set_sprint(true)

func _on_sprint_up() -> void:
    if is_instance_valid(player):
        player.set_sprint(false)
