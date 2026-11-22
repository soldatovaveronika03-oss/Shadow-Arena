#!/usr/bin/env python3
"""Prepare the supplied Godot 4.2 project for Android and wire in the saved GLB animals."""
from pathlib import Path
import shutil
import zipfile
import base64

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

# App icon generated from the user's uploaded dragon artwork (square 256x256 PNG).
icon_png = base64.b64decode("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")
(PROJECT / "icon.png").write_bytes(icon_png)
project_settings = PROJECT / "project.godot"
project_text = project_settings.read_text(encoding="utf-8")
if "config/icon=" not in project_text:
    project_text = project_text.replace("[application]", "[application]" + chr(10) + 'config/icon="res://icon.png"' + chr(10), 1)
    project_settings.write_text(project_text, encoding="utf-8")

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
launcher_icons/main_192x192="res://icon.png"
launcher_icons/adaptive_foreground_432x432="res://icon.png"
'''
(PROJECT / "export_presets.cfg").write_text(preset, encoding="utf-8")
print("Prepared project:", PROJECT)
print("Connected GLB models: bison, horse, bear, dragon")
