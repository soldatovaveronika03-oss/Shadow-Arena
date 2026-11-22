import bpy, math
from mathutils import Vector

# ATLAS WILDS ARENA — original mobile-friendly dragon
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
    pass

def mat(name, color, metallic=0.0, rough=0.55):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    bs=m.node_tree.nodes.get("Principled BSDF"); bs.inputs["Base Color"].default_value=(*color,1)
    bs.inputs["Metallic"].default_value=metallic; bs.inputs["Roughness"].default_value=rough
    return m
scale_mat=mat("Dragon scales | deep emerald",(0.055,0.20,0.13),0.18,0.42)
belly_mat=mat("Warm bronze belly",(0.42,0.25,0.12),0.12,0.55)
wing_mat=mat("Dark jade wing membrane",(0.025,0.105,0.085),0.08,0.62)
horn_mat=mat("Ivory horns",(0.82,0.72,0.48),0.05,0.38)
eye_mat=mat("Amber eyes",(1.0,0.38,0.025),0.25,0.22)
claw_mat=mat("Obsidian claws",(0.025,0.03,0.035),0.2,0.32)

# Armature rest pose; dragon faces -Y, Z is up.
adata=bpy.data.armatures.new("AtlasDragon_Rig")
arm=bpy.data.objects.new("AtlasDragon_Rig",adata); bpy.context.collection.objects.link(arm)
bpy.context.view_layer.objects.active=arm; arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bones={}
def bone(name, head, tail, parent=None, connected=False):
    b=adata.edit_bones.new(name); b.head=head; b.tail=tail
    if parent: b.parent=adata.edit_bones[parent]; b.use_connect=connected
    bones[name]=b
bone("Root",(0,0,0),(0,0,0.8))
bone("Spine",(0,0,0.8),(0,-0.9,1.05),"Root")
bone("Neck",(0,-0.9,1.05),(0,-1.55,1.22),"Spine")
bone("Head",(0,-1.55,1.22),(0,-2.15,1.25),"Neck")
bone("Wing.L",(-0.38,-0.72,1.35),(-1.8,-0.9,1.65),"Spine")
bone("Wing.R",(0.38,-0.72,1.35),(1.8,-0.9,1.65),"Spine")
bone("ForeLeg.L",(-0.38,-0.72,0.9),(-0.55,-0.9,0.25),"Spine")
bone("ForeLeg.R",(0.38,-0.72,0.9),(0.55,-0.9,0.25),"Spine")
bone("HindLeg.L",(-0.42,0.55,0.82),(-0.62,0.35,0.2),"Root")
bone("HindLeg.R",(0.42,0.55,0.82),(0.62,0.35,0.2),"Root")
bone("Tail.01",(0,0.75,0.95),(0,1.55,0.83),"Root")
bone("Tail.02",(0,1.55,0.83),(0,2.35,0.68),"Tail.01",True)
bone("Tail.03",(0,2.35,0.68),(0,3.05,0.55),"Tail.02",True)
bpy.ops.object.mode_set(mode='OBJECT'); arm.show_in_front=True

def bind(obj, bone_name, material):
    obj.data.materials.append(material)
    vg=obj.vertex_groups.new(name=bone_name); vg.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
    mod=obj.modifiers.new("Dragon skeleton","ARMATURE"); mod.object=arm
    obj.parent=arm
    return obj

def uv(name, loc, scl, material, bone_name, seg=12, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scl
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return bind(o,bone_name,material)

def cone(name, loc, radius, depth, material, bone_name, direction=(0,0,1), vertices=8):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0.0, depth=depth, location=loc)
    o=bpy.context.object; o.name=name; o.rotation_mode='QUATERNION'
    o.rotation_quaternion=Vector((0,0,1)).rotation_difference(Vector(direction).normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return bind(o,bone_name,material)

def cyl(name, loc, radius, depth, material, bone_name, direction=(0,0,1), vertices=10):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    o=bpy.context.object; o.name=name
    o.rotation_mode='QUATERNION'; o.rotation_quaternion=Vector((0,0,1)).rotation_difference(Vector(direction).normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return bind(o,bone_name,material)

# Torso, chest, belly, neck and skull
uv("Dragon_Body",(0,0.0,0.98),(0.62,1.05,0.60),scale_mat,"Spine",16,10)
uv("Dragon_Chest",(0,-0.65,1.05),(0.57,0.55,0.58),scale_mat,"Spine",14,9)
uv("Dragon_Belly",(0,-0.05,0.62),(0.43,0.88,0.30),belly_mat,"Spine",14,8)
cyl("Dragon_Neck",(0,-1.18,1.18),0.30,0.78,scale_mat,"Neck",(0,-1,0),12)
uv("Dragon_Head",(0,-1.78,1.25),(0.43,0.52,0.36),scale_mat,"Head",14,9)
uv("Dragon_Muzzle",(0,-2.08,1.10),(0.31,0.38,0.19),belly_mat,"Head",12,8)
for s in (-1,1):
    uv("Dragon_Eye",(s*0.335,-1.91,1.39),(0.075,0.11,0.09),eye_mat,"Head",10,6)
    cone("Dragon_Horn",(s*0.23,-1.55,1.58),0.13,0.55,horn_mat,"Head",(s*0.30,0.10,1),8)
    cone("Dragon_Nostril",(s*0.17,-2.30,1.22),0.045,0.09,claw_mat,"Head",(0,-1,0),6)

# Four muscular legs, feet and claws
for s,side in [(-1,"L"),(1,"R")]:
    cyl("Dragon_ForeLeg_"+side,(s*0.48,-0.72,0.53),0.19,0.68,scale_mat,"ForeLeg."+side,(s*0.12,0,-1),10)
    uv("Dragon_ForeFoot_"+side,(s*0.52,-0.83,0.18),(0.25,0.28,0.14),scale_mat,"ForeLeg."+side,10,6)
    cyl("Dragon_HindLeg_"+side,(s*0.52,0.50,0.48),0.25,0.72,scale_mat,"HindLeg."+side,(s*0.15,-0.1,-1),10)
    uv("Dragon_HindFoot_"+side,(s*0.62,0.30,0.16),(0.30,0.34,0.15),scale_mat,"HindLeg."+side,10,6)
    for j in range(3):
        cone("Dragon_Claw_"+side+"_"+str(j),(s*(0.39+j*0.13),-0.99,0.12),0.055,0.19,claw_mat,"ForeLeg."+side,(0,-1,-0.15),6)
        cone("Dragon_Talon_"+side+"_"+str(j),(s*(0.46+j*0.15),0.10,0.12),0.065,0.22,claw_mat,"HindLeg."+side,(0,-1,-0.15),6)

# Long segmented tail and spines
uv("Dragon_TailBase",(0,1.05,0.87),(0.34,0.75,0.34),scale_mat,"Tail.01",12,8)
uv("Dragon_TailMid",(0,1.95,0.72),(0.22,0.72,0.23),scale_mat,"Tail.02",10,7)
cone("Dragon_TailTip",(0,2.82,0.58),0.20,0.62,scale_mat,"Tail.03",(0,1,0.12),8)
for i in range(6):
    y=-0.95+i*0.47
    cone("Dragon_BackSpine_"+str(i),(0,y,1.56 if y<0.6 else 1.25),0.10,0.28,horn_mat,"Spine",(0,0,1),6)

# Triangular wing membranes: low-poly, each skinned to its animated wing bone.
def wing(side, label):
    s=side
    verts=[
      (s*0.34,-0.70,1.40),(s*1.72,-0.82,1.66),(s*2.45,-0.30,1.02),
      (s*1.70,0.12,0.82),(s*0.85,0.02,1.03)
    ]
    faces=[(0,1,2),(0,2,3),(0,3,4)]
    mesh=bpy.data.meshes.new("WingMembraneMesh_"+label); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new("Dragon_Wing_"+label,mesh); bpy.context.collection.objects.link(o)
    # Add a subtle thickness modifier for a visible silhouette.
    bind(o,"Wing."+label,wing_mat)
    solid=o.modifiers.new("Thin membrane","SOLIDIFY"); solid.thickness=0.025
    return o
wing(-1,"L"); wing(1,"R")
for s,label in [(-1,"L"),(1,"R")]:
    cyl("Dragon_Wing_Bone_"+label,(s*1.10,-0.79,1.53),0.065,1.55,horn_mat,"Wing."+label,(s,0.04,0.16),8)
    cone("Dragon_Wing_Thumb_"+label,(s*2.34,-0.29,1.02),0.07,0.32,horn_mat,"Wing."+label,(s,0.2,-0.8),6)

# Animation actions on rig; exported as distinct GLB clips.
def action(name, frames):
    bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); bpy.context.view_layer.objects.active=arm
    arm.animation_data_create()
    new_action=bpy.data.actions.new(name)
    arm.animation_data.action=new_action
    bpy.ops.object.mode_set(mode='POSE')
    for p in arm.pose.bones: p.rotation_mode='XYZ'
    bpy.context.scene.frame_start=1; bpy.context.scene.frame_end=max(f for _,f,_ in frames)
    for bone_name, frame, rot in frames:
        p=arm.pose.bones[bone_name]; p.rotation_euler=rot; p.keyframe_insert(data_path="rotation_euler",frame=frame,group=bone_name)
    bpy.ops.object.mode_set(mode='OBJECT')
    a=arm.animation_data.action; a.name=name
    for fc in a.fcurves:
        for kp in fc.keyframe_points: kp.interpolation='BEZIER'
    return a

# Wing flap loop
frames=[]
for f,ang in [(1,0.05),(7,-0.72),(13,0.05),(19,0.78),(25,0.05)]:
    frames += [("Wing.L",f,(0,ang,0)),("Wing.R",f,(0,-ang,0))]
action("Dragon_Fly_WingFlaps",frames)
# Ground run loop
frames=[]
for f,a in [(1,0.45),(7,-0.45),(13,0.45),(19,-0.45),(25,0.45)]:
    frames += [("ForeLeg.L",f,(a,0,0)),("ForeLeg.R",f,(-a,0,0)),("HindLeg.L",f,(-a,0,0)),("HindLeg.R",f,(a,0,0)),("Tail.01",f,(0,0.12*math.sin(f),0)),("Tail.02",f,(0,-0.12*math.sin(f),0))]
action("Dragon_Run",frames)
# Idle breathing and tail sway
frames=[]
for f,a in [(1,0),(13,0.08),(25,0),(37,-0.08),(49,0)]:
    frames += [("Spine",f,(a,0,0)),("Tail.01",f,(0,a,0)),("Tail.02",f,(0,-a,0))]
action("Dragon_Idle",frames)
# Bite / claw attack
frames=[]
for f,a in [(1,0),(5,-0.35),(9,0.55),(15,0)]:
    frames += [("Neck",f,(a,0,0)),("Head",f,(a*0.7,0,0)),("ForeLeg.L",f,(-a,0,0)),("ForeLeg.R",f,(-a,0,0))]
action("Dragon_Attack",frames)
# Death fall
frames=[]
for f,a in [(1,0),(8,0.35),(18,1.35),(30,1.48)]:
    frames += [("Spine",f,(0,0,a)),("Head",f,(0,0,-a*0.45)),("Wing.L",f,(0,-a*0.7,0)),("Wing.R",f,(0,a*0.7,0))]
action("Dragon_Death",frames)

# Select armature and export mesh + rig + all actions.
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.context.scene.objects:
    if o.type in {'MESH','ARMATURE'}: o.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.wm.save_as_mainfile(filepath="/tmp/atlas_dragon.blend")
bpy.ops.export_scene.gltf(filepath="/tmp/atlas_dragon.glb", export_format='GLB',
    use_selection=True, export_apply=True, export_animations=True,
    export_animation_mode='ACTIONS', export_nla_strips=False,
    export_skins=True, export_morph=False, export_materials='EXPORT',
    export_yup=True, export_image_format='AUTO')
print("ATLAS_DRAGON_EXPORT_OK")
