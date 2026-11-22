import bpy, math, os
from mathutils import Vector
OUT="/tmp/atlas_world_assets"; os.makedirs(OUT,exist_ok=True)
def clear():
 bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
def mat(n,c,r=.85):
 m=bpy.data.materials.new(n); m.diffuse_color=(*c,1); m.use_nodes=True; p=m.node_tree.nodes.get("Principled BSDF"); p.inputs["Base Color"].default_value=(*c,1); p.inputs["Roughness"].default_value=r; return m
GRASS=mat("Meadow grass",(.19,.34,.12)); DARKGRASS=mat("Forest pine",(.07,.22,.10)); LEAF=mat("Leaf green",(.13,.31,.12)); LEAF2=mat("Sunlit leaves",(.25,.40,.15)); BARK=mat("Bark",(.25,.13,.065)); ROCK=mat("Granite",(.32,.35,.34)); MOSS=mat("Mossy stone",(.22,.29,.20)); WATER=mat("Clear blue water",(.035,.32,.48),.18); FOAM=mat("Water foam",(.72,.88,.89),.3); DEER=mat("Deer coat",(.42,.22,.10)); CREAM=mat("Cream markings",(.78,.63,.42)); DARK=mat("Hooves",(.045,.035,.025)); WOLF=mat("Wolf silver",(.29,.33,.36)); RABBIT=mat("Rabbit fur",(.72,.67,.56)); BIRD=mat("Blue bird",(.055,.18,.31)); EYE=mat("Amber eyes",(.95,.42,.04),.28)
def finish(o,n,m): o.name=n; o.data.materials.append(m); return o
def ico(n,l,s,m,sub=1):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=l); o=bpy.context.object; o.scale=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return finish(o,n,m)
def uv(n,l,s,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,radius=1,location=l); o=bpy.context.object; o.scale=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return finish(o,n,m)
def cone(n,l,r,d,m,rot=None,v=7):
 bpy.ops.mesh.primitive_cone_add(vertices=v,radius1=r,radius2=0,depth=d,location=l); o=bpy.context.object
 if rot:o.rotation_euler=rot
 return finish(o,n,m)
def cyl(n,l,r,d,m,v=8):
 bpy.ops.mesh.primitive_cylinder_add(vertices=v,radius=r,depth=d,location=l); return finish(bpy.context.object,n,m)
def export(n):
 bpy.ops.object.select_all(action="DESELECT")
 for o in bpy.context.scene.objects:
  if o.type in {"MESH","ARMATURE"}:o.select_set(True)
 sel=bpy.context.selected_objects
 if not sel:raise RuntimeError("No objects: "+n)
 bpy.context.view_layer.objects.active=sel[0]
 bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,n+".glb"),export_format="GLB",use_selection=True,export_apply=True,export_animations=True,export_skins=True,export_materials="EXPORT",export_yup=True)
 clear()
# Rolling, triangulated hill tile
verts=[];faces=[];N=24;size=32
for z in range(N+1):
 for x in range(N+1):
  xx=(x/N-.5)*size;zz=(z/N-.5)*size; yy=.8*math.sin(xx*.22)*math.cos(zz*.18)+.25*math.sin((xx+zz)*.5);verts.append((xx,yy,zz))
for z in range(N):
 for x in range(N):
  a=z*(N+1)+x;b=a+1;c=a+N+1;d=c+1;faces.extend([(a,c,b),(b,c,d)])
me=bpy.data.meshes.new("HillMesh");me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new("Meadow_Hill_Tile",me);bpy.context.collection.objects.link(o);me.materials.append(GRASS)
for i in range(9):ico("Hill_Rock",(-13+(i*3.1)%26,.5,-11+(i*5.7)%22),(.8,.5,.7),ROCK)
export("atlas_hills")
# Oak
cyl("Oak_Trunk",(0,2.7,0),.42,5.4,BARK)
for l,s,m in [((0,5.2,0),(2,2.2,1.8),LEAF),((-1,4.8,.2),(1.35,1.5,1.3),LEAF2),((1,4.7,-.2),(1.4,1.5,1.3),LEAF)]:ico("Oak_Canopy",l,s,m,2)
export("atlas_oak_tree")
# Pine
cone("Pine_Trunk",(0,2.4,0),.34,4.8,BARK)
for z,r in [(2,2),(3.3,1.65),(4.5,1.25),(5.5,.82)]:cone("Pine_Foliage",(0,z,0),r,2.7,DARKGRASS,v=8)
export("atlas_pine_tree")
# Bush and fern
ico("Bush_Core",(0,.75,0),(1.05,.85,.9),LEAF,2)
for i in range(7):
 a=i*math.tau/7;ico("Bush_Leaf",(math.cos(a)*.65,.75+.2*math.sin(a*2),math.sin(a)*.65),(.55,.42,.5),LEAF2 if i%3==0 else LEAF,1)
for i in range(5):
 a=i*math.tau/5;cone("Fern_Frond",(math.cos(a)*.35,.65,math.sin(a)*.35),.12,1.2,GRASS,(math.cos(a)*.5,0,math.sin(a)*.5),5)
export("atlas_bush_fern")
# Rocks
ico("Boulder_Large",(0,.9,0),(2.1,1.4,1.7),ROCK,1);ico("Boulder_Small",(2,.45,.6),(.8,.65,.7),MOSS,1);ico("Standing_Stone",(-2.1,1.4,-.5),(.65,1.7,.7),ROCK,1)
for i in range(8):ico("Pebble",(-3.5+(i%4)*2.2,.2,2+(i//4)*1.5),(.35,.22,.3),MOSS,1)
export("atlas_rock_cluster")
# Pond
bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=5.8,depth=.55,location=(0,.25,0));finish(bpy.context.object,"Pond_Bank",GRASS)
bpy.ops.mesh.primitive_circle_add(vertices=48,radius=5.1,fill_type="NGON",location=(0,.56,0));finish(bpy.context.object,"Pond_Water",WATER)
for i in range(12):
 a=i*math.tau/12;ico("Pond_Rim_Stone",(math.cos(a)*5.25,.62,math.sin(a)*5.25),(.55,.32,.48),ROCK,1)
export("atlas_pond")
# Waterfall
ico("Waterfall_Cliff",(0,3.4,0),(4.2,3.5,1.4),ROCK,2)
bpy.ops.mesh.primitive_plane_add(size=1,location=(0,2.3,1));sheet=finish(bpy.context.object,"Waterfall_Sheet",WATER);sheet.scale=(2,3,1);sheet.rotation_euler[0]=math.radians(90)
ico("Waterfall_Foam",(0,.22,1.2),(2.5,.32,1.1),FOAM,2)
export("atlas_waterfall")
# Stylized quadruped/deer with distinctive silhouette
def leg(n,x,y,z,h,m):
 o=cyl(n,(x,y,z),.115,h,m,7);return o
uv("Deer_Body",(0,0,1.15),(.55,.9,.55),DEER);uv("Deer_Chest",(0,-.48,1.1),(.48,.5,.58),DEER);uv("Deer_Neck",(0,-.76,1.62),(.25,.28,.72),DEER);uv("Deer_Head",(0,-.95,2.05),(.32,.42,.36),DEER);uv("Deer_Muzzle",(0,-1.25,1.92),(.22,.24,.17),CREAM)
for s in (-1,1):
 uv("Deer_Eye",(s*.27,-1.05,2.16),(.055,.07,.06),EYE);cone("Deer_Ear",(s*.25,-.82,2.32),.12,.42,DEER,(0,s*.6,0),6);cyl("Deer_Antler",(s*.22,-.82,2.62),.055,.75,CREAM,6);cone("Deer_Antler_Tine",(s*.38,-.82,2.85),.05,.42,CREAM,(0,s*.7,.4),6)
 for y in (-.45,.48):leg("Deer_Leg",s*.3,y,.55,.85,DEER);uv("Deer_Hoof",(s*.3,y,.1),(.15,.18,.12),DARK)
uv("Deer_Tail",(0,.88,1.28),(.16,.24,.18),CREAM);export("atlas_deer")
# Wolf
uv("Wolf_Body",(0,0,.95),(.55,.9,.55),WOLF);uv("Wolf_Shoulder",(0,-.52,1.05),(.5,.55,.55),WOLF);uv("Wolf_Head",(0,-.93,1.25),(.38,.43,.36),WOLF);uv("Wolf_Snout",(0,-1.28,1.13),(.22,.34,.18),CREAM)
for s in (-1,1):
 cone("Wolf_Ear",(s*.23,-.82,1.62),.18,.48,WOLF,(s*.15,0,1),6);uv("Wolf_Eye",(s*.31,-1.05,1.34),(.05,.06,.05),EYE)
 for y in (-.55,.48):leg("Wolf_Leg",s*.31,y,.43,.78,WOLF)
uv("Wolf_Tail",(0,.88,1.1),(.22,.62,.22),WOLF);export("atlas_wolf")
# Rabbit
uv("Rabbit_Body",(0,0,.48),(.38,.58,.36),RABBIT);uv("Rabbit_Head",(0,-.48,.78),(.32,.34,.31),RABBIT)
for s in (-1,1):
 uv("Rabbit_Ear",(s*.16,-.42,1.28),(.11,.42,.12),RABBIT);uv("Rabbit_Eye",(s*.27,-.59,.86),(.045,.055,.045),EYE);leg("Rabbit_HindLeg",s*.25,.38,.25,.42,RABBIT);leg("Rabbit_FrontLeg",s*.22,-.32,.22,.36,RABBIT)
uv("Rabbit_Tail",(0,.55,.55),(.18,.18,.18),CREAM);export("atlas_rabbit")
# Bird
uv("Bird_Body",(0,0,.55),(.3,.48,.32),BIRD);uv("Bird_Head",(0,-.34,.82),(.25,.25,.24),BIRD);cone("Bird_Beak",(0,-.64,.78),.13,.34,CREAM,(math.radians(90),0,0),5)
for s in (-1,1):uv("Bird_Wing",(s*.31,.02,.58),(.12,.42,.24),BIRD);uv("Bird_Eye",(s*.2,-.47,.88),(.04,.045,.04),EYE)
cone("Bird_Tail",(0,.47,.58),.16,.6,BIRD,(math.radians(90),0,0),5);export("atlas_bird")
print("ATLAS_WORLD_ASSETS_OK",sorted(os.listdir(OUT)))
