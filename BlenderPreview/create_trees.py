import bpy, math, os, random
from mathutils import Vector

OUT = os.path.abspath("output")
os.makedirs(OUT, exist_ok=True)
random.seed(23)

def mat(name, color, rough=0.85):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = rough
    return m

bark = mat("Bark_Warm_Brown", (0.19, 0.075, 0.032))
bark_light = mat("Bark_Highlights", (0.29, 0.13, 0.055))
leaf1 = mat("Leaves_Deep_Green", (0.075, 0.24, 0.095))
leaf2 = mat("Leaves_Mid_Green", (0.13, 0.34, 0.12))
leaf3 = mat("Leaves_Sunlit_Green", (0.28, 0.46, 0.16))
pine1 = mat("Pine_Dark_Green", (0.035, 0.18, 0.12))
pine2 = mat("Pine_Light_Green", (0.07, 0.28, 0.16))
groundmat = mat("Preview_Ground", (0.16, 0.20, 0.12))

def smooth(obj):
    if obj.type == "MESH":
        for p in obj.data.polygons: p.use_smooth = True
    return obj

def cylinder_between(name, a, b, r1, r2, material, vertices=10):
    d = Vector(b) - Vector(a)
    mid = (Vector(a) + Vector(b)) / 2
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=d.length, location=mid)
    o = bpy.context.object
    o.name = name
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = d.to_track_quat("Z", "Y")
    o.data.materials.append(material)
    return smooth(o)

def blob(name, loc, scale, material, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    o.data.materials.append(material)
    return smooth(o)

def broadleaf(label, height, crown, seed):
    random.seed(seed)
    objs = []
    objs.append(cylinder_between(label+"_Trunk", (0,0,0), (0,0,height*0.72), 0.34, 0.13, bark, 12))
    # visible roots
    for i in range(5):
        ang = i*math.tau/5
        end = (math.cos(ang)*0.72, math.sin(ang)*0.72, 0.05)
        objs.append(cylinder_between(label+"_Root", (0,0,0.48), end, 0.14, 0.035, bark_light, 8))
    for i in range(7):
        ang = i*math.tau/7 + 0.2
        z = height*(0.48 + random.random()*0.20)
        end = (math.cos(ang)*crown*0.72, math.sin(ang)*crown*0.72, z+crown*0.35)
        objs.append(cylinder_between(label+"_Branch", (0,0,z), end, 0.12, 0.035, bark, 8))
    for i in range(15):
        ang = random.random()*math.tau
        rad = crown*math.sqrt(random.random())*0.78
        z = height*0.69 + random.uniform(-crown*0.22, crown*0.52)
        loc = (math.cos(ang)*rad, math.sin(ang)*rad, z)
        sc = random.uniform(0.48,0.78)*crown
        objs.append(blob(label+"_LeafCluster", loc, (sc,sc*0.88,sc*0.78), random.choice([leaf1,leaf2,leaf3]), 2))
    objs.append(blob(label+"_CrownTop",(0,0,height*0.82),(crown*0.55,crown*0.52,crown*0.48),leaf2,2))
    return objs

def pine(label, height, width, seed):
    random.seed(seed)
    objs=[cylinder_between(label+"_Trunk",(0,0,0),(0,0,height),0.24,0.07,bark,10)]
    levels=6
    for i in range(levels):
        z=height*(0.28+i*0.115)
        radius=width*(1-i/(levels+0.8))
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=radius, radius2=0.05, depth=height*0.32, location=(0,0,z))
        o=bpy.context.object; o.name=label+"_NeedleLayer"; o.data.materials.append(random.choice([pine1,pine2])); smooth(o); objs.append(o)
    return objs

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def setup_preview():
    bpy.ops.mesh.primitive_plane_add(size=9, location=(0,0,-0.04))
    bpy.context.object.data.materials.append(groundmat)
    bpy.ops.object.camera_add(location=(6,-9,5.0))
    cam=bpy.context.object
    target=Vector((0,0,2.3))
    cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
    cam.data.type="ORTHO"; cam.data.ortho_scale=8.5
    bpy.context.scene.camera=cam
    for loc, power, size in [((4,-5,8),1100,5),((-5,-2,5),700,4),((1,5,7),900,3)]:
        bpy.ops.object.light_add(type="AREA", location=loc)
        l=bpy.context.object; l.data.energy=power; l.data.shape="DISK"; l.data.size=size
        l.rotation_euler=(Vector((0,0,2))-l.location).to_track_quat("-Z","Y").to_euler()
    sc=bpy.context.scene
    sc.render.engine="BLENDER_EEVEE"
    sc.eevee.use_gtao=True
    sc.eevee.gtao_distance=3
    sc.render.resolution_x=900; sc.render.resolution_y=900; sc.render.resolution_percentage=100
    sc.render.image_settings.file_format="PNG"
    sc.world.color=(0.12,0.12,0.12)

variants=[
 ("Tree_Old_Oak", lambda: broadleaf("OldOak",5.8,2.3,11)),
 ("Tree_Young_Birch", lambda: broadleaf("YoungBirch",4.6,1.65,22)),
 ("Tree_Wide_Ancient", lambda: broadleaf("AncientWide",6.2,3.0,33)),
 ("Tree_Pine", lambda: pine("Pine",6.0,1.8,44)),
]

for name, build in variants:
    clear_scene()
    asset_objects=build()
    # Export only the model mesh, excluding preview camera, lights and ground.
    bpy.ops.object.select_all(action="DESELECT")
    for o in asset_objects: o.select_set(True)
    bpy.context.view_layer.objects.active=asset_objects[0]
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+".glb"), export_format="GLB", use_selection=True)
    # Add studio preview elements after GLB export.
    bpy.ops.object.select_all(action="DESELECT")
    setup_preview()
    bpy.context.scene.render.filepath=os.path.join(OUT,name+".png")
    bpy.ops.render.render(write_still=True)

print("Created 4 tree GLBs and 4 PNG previews in", OUT)
