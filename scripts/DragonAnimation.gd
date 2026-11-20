extends Node
var clock := 0.0
func update_dragon(delta: float, body: Node3D, head: Node3D, wings: Node3D, legs: Node3D, tail: Node3D, moving: bool, attacking: bool) -> void:
 clock += delta
 if is_instance_valid(body):
  body.position.y = 1.65 + sin(clock*2.1)*0.045
  body.rotation.x = sin(clock*1.7)*0.025
 if is_instance_valid(head):
  head.rotation.x = (-0.22 if attacking else sin(clock*1.4)*0.025)
 if is_instance_valid(wings):
  var pivots: Array = wings.get("wing_pivots")
  var flap := sin(clock*(7.2 if moving else 2.0))*(0.62 if moving else 0.12)
  for i in range(pivots.size()):
   var side := -1.0 if i == 0 else 1.0
   pivots[i].rotation.z = side*flap
 if is_instance_valid(legs):
  var leg_nodes: Array = legs.get("legs")
  for i in range(leg_nodes.size()):
   leg_nodes[i].rotation.x = sin(clock*8.0+(PI if i%2==0 else 0.0))*(0.28 if moving else 0.035)
 if is_instance_valid(tail):
  var pivot: Node3D = tail.get("tail_pivot")
  if is_instance_valid(pivot):
   pivot.rotation.y = sin(clock*2.0)*0.16
