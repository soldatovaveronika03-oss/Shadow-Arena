extends CharacterBody3D
class_name DragonCreature
@export var move_speed := 5.0
@export var health := 900.0
@export var damage := 38.0
@export var aggro_range := 55.0
@export var attack_range := 8.5
var target: Node3D
var attack_cooldown := 0.0
var attack_time := 0.0
var anim: Node
var body_part: Node3D
var head_part: Node3D
var wings_part: Node3D
var legs_part: Node3D
var tail_part: Node3D
func _ready() -> void:
 name = "AncientDragon"
 floor_snap_length = 1.4
 var body_script = preload("res://scripts/DragonBody.gd")
 var head_script = preload("res://scripts/DragonHead.gd")
 var wings_script = preload("res://scripts/DragonWings.gd")
 var legs_script = preload("res://scripts/DragonLegs.gd")
 var tail_script = preload("res://scripts/DragonTail.gd")
 body_part = _add_component("DragonBody",body_script)
 head_part = _add_component("DragonHead",head_script)
 wings_part = _add_component("DragonWings",wings_script)
 legs_part = _add_component("DragonLegs",legs_script)
 tail_part = _add_component("DragonTail",tail_script)
 anim = preload("res://scripts/DragonAnimation.gd").new()
 add_child(anim)
 var shape := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius = 1.05
 capsule.height = 3.6
 shape.shape = capsule
 shape.position.y = 1.8
 add_child(shape)
 add_to_group("wild_creatures")
func _add_component(node_name: String, script: Script) -> Node3D:
 var node := Node3D.new()
 node.name = node_name
 node.set_script(script)
 add_child(node)
 return node
func _physics_process(delta: float) -> void:
 attack_cooldown = maxf(0.0,attack_cooldown-delta)
 attack_time = maxf(0.0,attack_time-delta)
 var direction := Vector3.ZERO
 var engaged := false
 if is_instance_valid(target) and global_position.distance_to(target.global_position) <= aggro_range:
  var diff := target.global_position-global_position
  diff.y = 0.0
  engaged = true
  if diff.length() > attack_range:
   direction = diff.normalized()
  elif attack_cooldown <= 0.0:
   attack_cooldown = 2.5
   attack_time = 0.55
   if target.has_method("take_damage"):
    target.take_damage(damage,self)
 if not engaged:
  direction = Vector3(sin(Time.get_ticks_msec()*0.00018),0,cos(Time.get_ticks_msec()*0.00016))*0.18
 velocity.x = move_toward(velocity.x,direction.x*move_speed,12.0*delta)
 velocity.z = move_toward(velocity.z,direction.z*move_speed,12.0*delta)
 if not is_on_floor():
  velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity"))*delta
 elif velocity.y < 0.0:
  velocity.y = -0.5
 if direction.length() > 0.05:
  look_at(global_position+direction,Vector3.UP)
 move_and_slide()
 anim.update_dragon(delta,body_part,head_part,wings_part,legs_part,tail_part,direction.length()>0.05,attack_time>0.0)
func take_damage(amount: float, _source: Node = null) -> void:
 health = maxf(0.0,health-amount)
 if health <= 0.0:
  queue_free()
