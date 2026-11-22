#!/usr/bin/env python3
"""Prepare the supplied Godot 4.2 project for Android and wire in the saved GLB animals."""
from pathlib import Path
import shutil
import zipfile

ROOT = Path.cwd()
ARCHIVE = ROOT / "dragon_realm_godot_v3.zip"
if not ARCHIVE.exists():
    raise SystemExit("Missing dragon_realm_godot_v3.zip")

WORK = ROOT / "build_project"
if WORK.exists():
    shutil.rmtree(WORK)
WORK.mkdir(parents=True)

with zipfile.ZipFile(ARCHIVE) as zf:
    zf.extractall(WORK)

PROJECT = WORK / "dragon_realm_v3"
if not (PROJECT / "project.godot").exists():
    raise SystemExit("The archive does not contain dragon_realm_v3/project.godot")

ASSETS = PROJECT / "assets"
ASSETS.mkdir(exist_ok=True)
source_assets = {
    "brown bear 3d model.glb": "bear.glb",
    "wild chestnut stallion 3d model.glb": "horse.glb",
    "Бизон1.glb": "bison.glb",
    "dragon 3d model.glb": "dragon.glb",
}
for src, dst in source_assets.items():
    source = ROOT / "assets" / src
    if not source.exists():
        raise SystemExit(f"Missing required saved model: {source}")
    shutil.copy2(source, ASSETS / dst)

# Connect the saved bear, horse and bison models to the existing quadruped spawn system.
qpath = PROJECT / "quadruped.gd"
q = qpath.read_text(encoding="utf-8")
if "var using_glb := false" not in q:
    q = q.replace(
        "var neck_y := 0.0\n",
        "var neck_y := 0.0\nvar using_glb := false\n",
        1,
    )
    needle = "\tkind = k\n\tP = PARAMS[k]\n"
    injected = """\tkind = k
\tP = PARAMS[k]
\tusing_glb = false
\tvar saved_models := {
\t\t"bear": ["res://assets/bear.glb", 2.65],
\t\t"horse": ["res://assets/horse.glb", 2.35],
\t\t"bison": ["res://assets/bison.glb", 2.75],
\t}
\tif saved_models.has(k):
\t\tvar model_info: Array = saved_models[k]
\t\tvar packed := load(str(model_info[0])) as PackedScene
\t\tif packed != null:
\t\t\tvar imported := packed.instantiate() as Node3D
\t\t\tif imported != null:
\t\t\t\tadd_child(imported)
\t\t\t\tbody = imported
\t\t\t\t_fit_imported_model(imported, float(model_info[1]))
\t\t\t\tbase_y = imported.position.y
\t\t\t\t_play_imported_idle(imported)
\t\t\t\tusing_glb = true
\t\t\t\treturn
"""
    if needle not in q:
        raise SystemExit("Could not find Quadruped.build insertion point")
    q = q.replace(needle, injected, 1)
    animate_needle = "func animate(delta: float, speed: float, mode: String, mt: float) -> void:\n\tt += delta\n"
    animate_injected = """func animate(delta: float, speed: float, mode: String, mt: float) -> void:
\tif using_glb:
\t\tt += delta
\t\tif body != null:
\t\t\tbody.position.y = base_y + sin(t * 2.0) * 0.018
\t\treturn
\tt += delta
"""
    if animate_needle not in q:
        raise SystemExit("Could not find Quadruped.animate insertion point")
    q = q.replace(animate_needle, animate_injected, 1)
    q += """
\nfunc _fit_imported_model(root: Node3D, target_height: float) -> void:
\tvar meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
\tif root is MeshInstance3D:
\t\tmeshes.append(root)
\tvar min_y := INF
\tvar max_y := -INF
\tfor node in meshes:
\t\tvar mesh_node := node as MeshInstance3D
\t\tvar aabb := mesh_node.get_aabb()
\t\tfor corner in 8:
\t\t\tvar point := root.to_local(mesh_node.to_global(aabb.get_endpoint(corner)))
\t\t\tmin_y = minf(min_y, point.y)
\t\t\tmax_y = maxf(max_y, point.y)
\tif max_y > min_y:
\t\tvar factor := target_height / (max_y - min_y)
\t\troot.scale = Vector3.ONE * factor
\t\troot.position.y = -min_y * factor

func _play_imported_idle(root: Node3D) -> void:
\tvar players: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
\tfor node in players:
\t\tvar player := node as AnimationPlayer
\t\tvar names := player.get_animation_list()
\t\tif names.is_empty():
\t\t\tcontinue
\t\tvar chosen := str(names[0])
\t\tfor animation_name in names:
\t\t\tif str(animation_name).to_lower().contains("idle"):
\t\t\t\tchosen = str(animation_name)
\t\t\t\tbreak
\t\tplayer.play(chosen)
"""
qpath.write_text(q, encoding="utf-8")

# Use the saved dragon GLB for the dragon boss; retain the existing combat AI and fire effect.
epath = PROJECT / "enemy.gd"
e = epath.read_text(encoding="utf-8")
old = """\tif k == "dragon":
\t\trig_d = DragonRig.new()
\t\tmodel.add_child(rig_d)
\t\tif not rig_d.build():
\t\t\trig_d.queue_free()
\t\t\trig_d = null
\t\t\tmodel.add_child(Fx.box(Vector3(6, 4, 14), Color(0.2, 0.5, 0.25), Vector3(0, 3, 0)))
\t\tfire = Fx.fire_emitter(16.0, 9.0, 110, 0.55)
\t\tmodel.add_child(fire)
"""
new = """\tif k == "dragon":
\t\tvar dragon_scene := load("res://assets/dragon.glb") as PackedScene
\t\tif dragon_scene != null:
\t\t\tvar dragon_model := dragon_scene.instantiate() as Node3D
\t\t\tif dragon_model != null:
\t\t\t\tmodel.add_child(dragon_model)
\t\t\t\t_fit_imported_dragon(dragon_model, 8.0)
\t\t\t\t_play_dragon_idle(dragon_model)
\t\telse:
\t\t\tmodel.add_child(Fx.box(Vector3(6, 4, 14), Color(0.2, 0.5, 0.25), Vector3(0, 3, 0)))
\t\tfire = Fx.fire_emitter(16.0, 9.0, 110, 0.55)
\t\tmodel.add_child(fire)
"""
if old in e:
    e = e.replace(old, new, 1)
elif 'load("res://assets/dragon.glb")' not in e:
    raise SystemExit("Could not find Enemy dragon setup block")
old_fire = """func _update_fire() -> void:
\tif fire == null:
\t\treturn
\tvar head := rig_d.part("Head")
\tif head == null:
\t\treturn
\tvar fwd := Vector3(sin(rotation.y), -0.12, cos(rotation.y)).normalized()
\tfire.global_position = head.global_position + fwd * 1.8 + Vector3(0, -0.5, 0)
\tfire.look_at(fire.global_position - fwd)
"""
new_fire = """func _update_fire() -> void:
\tif fire == null:
\t\treturn
\tvar fwd := Vector3(sin(rotation.y), -0.12, cos(rotation.y)).normalized()
\tif rig_d == null:
\t\tfire.global_position = global_position + Vector3(0, height * 0.55, 0) + fwd * 2.0
\t\tfire.look_at(fire.global_position + fwd)
\t\treturn
\tvar head := rig_d.part("Head")
\tif head == null:
\t\treturn
\tfire.global_position = head.global_position + fwd * 1.8 + Vector3(0, -0.5, 0)
\tfire.look_at(fire.global_position - fwd)

func _fit_imported_dragon(root: Node3D, target_height: float) -> void:
\tvar meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
\tif root is MeshInstance3D:
\t\tmeshes.append(root)
\tvar min_y := INF
\tvar max_y := -INF
\tfor node in meshes:
\t\tvar mesh_node := node as MeshInstance3D
\t\tvar aabb := mesh_node.get_aabb()
\t\tfor corner in 8:
\t\t\tvar point := root.to_local(mesh_node.to_global(aabb.get_endpoint(corner)))
\t\t\tmin_y = minf(min_y, point.y)
\t\t\tmax_y = maxf(max_y, point.y)
\tif max_y > min_y:
\t\tvar factor := target_height / (max_y - min_y)
\t\troot.scale = Vector3.ONE * factor
\t\troot.position.y = -min_y * factor

func _play_dragon_idle(root: Node3D) -> void:
\tvar players: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
\tfor node in players:
\t\tvar player := node as AnimationPlayer
\t\tvar names := player.get_animation_list()
\t\tif names.is_empty():
\t\t\tcontinue
\t\tvar chosen := str(names[0])
\t\tfor animation_name in names:
\t\t\tif str(animation_name).to_lower().contains("idle"):
\t\t\t\tchosen = str(animation_name)
\t\t\t\tbreak
\t\tplayer.play(chosen)
"""
if old_fire not in e:
    raise SystemExit("Could not find Enemy._update_fire block")
e = e.replace(old_fire, new_fire, 1)
epath.write_text(e, encoding="utf-8")

# Android debug APK preset: arm64 for modern Android phones.
preset = '''[preset.0]
name="Android"
platform="Android"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/ATLAS_WILDS_ARENA.apk"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]
custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=false
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
package/unique_name="com.atlaswilds.arena"
package/name="ATLAS WILDS ARENA"
package/signed=true
version/code=1
version/name="1.0"
screen/immersive_mode=true
'''
(PROJECT / "export_presets.cfg").write_text(preset, encoding="utf-8")
print("Prepared project:", PROJECT)
print("Connected GLB models: bison, horse, bear, dragon")
