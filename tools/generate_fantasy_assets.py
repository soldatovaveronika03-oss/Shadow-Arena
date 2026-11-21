#!/usr/bin/env python3
"""Build original low-poly PBR GLTF assets for ATLAS WILDS ARENA.
Uses trimesh only; Blender is not required or claimed.
"""
import os, json, base64, collections
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

OUT = "assets/models"
os.makedirs(OUT, exist_ok=True)

def material(name, rgba, metallic=0.0, roughness=0.7):
    return PBRMaterial(name=name, baseColorFactor=np.array(rgba, dtype=np.uint8),
                       metallicFactor=metallic, roughnessFactor=roughness)

M = {
 "gold": material("Engraved gold", (220,169,65,255), .78,.24),
 "steel": material("Royal cobalt steel", (39,74,130,255), .72,.30),
 "leather": material("Dark leather", (42,37,34,255), .05,.82),
 "cloth": material("Crimson cloak", (130,39,48,255), .05,.75),
 "skin": material("Warm skin", (171,119,85,255), 0,.75),
 "crystal": material("Arcane crystal", (50,203,235,255), .28,.18),
 "stone": material("Limestone", (146,139,119,255), .05,.82),
 "grass": material("Emerald grass", (49,104,62,255), 0,.95),
 "leaf": material("Forest canopy", (43,105,55,255), 0,.9),
 "leaf2": material("Sunlit leaves", (77,137,70,255), 0,.88),
 "bark": material("Tree bark", (78,48,31,255), 0,.9),
 "water": material("River turquoise", (30,130,160,255), .18,.24),
}

def add(scene, name, mesh, mat, pos=(0,0,0), scale=None):
    mesh.visual = trimesh.visual.TextureVisuals(material=mat)
    if scale is not None: mesh.apply_scale(scale)
    mesh.apply_translation(pos)
    scene.add_geometry(mesh, node_name=name, geom_name=name)

def box(scene, name, size, pos, mat):
    add(scene,name,trimesh.creation.box(extents=size),mat,pos)
def ball(scene,name,r,pos,scale,mat):
    add(scene,name,trimesh.creation.icosphere(subdivisions=1,radius=r),mat,pos,scale)
def cylinder(scene,name,r,h,pos,mat):
    add(scene,name,trimesh.creation.cylinder(radius=r,height=h,sections=7),mat,pos)
def cone(scene,name,r,h,pos,mat):
    add(scene,name,trimesh.creation.cone(radius=r,height=h,sections=6),mat,pos)

def save_gltf(scene, path):
    grouped=collections.defaultdict(list)
    for mesh in scene.geometry.values():
        key=getattr(getattr(mesh.visual,"material",None),"name","material")
        grouped[key].append(mesh)
    compact=trimesh.Scene()
    for key, meshes in grouped.items():
        merged=trimesh.util.concatenate(meshes)
        merged.visual=meshes[0].visual
        compact.add_geometry(merged,node_name=key,geom_name=key)
    exported=compact.export(file_type="gltf")
    doc=None; binary={}
    for filename,data in exported.items():
        if filename.endswith(".gltf"):
            doc=json.loads(data.decode() if isinstance(data,bytes) else data)
        elif filename.endswith(".bin"):
            binary[filename]=data
    for buf in doc.get("buffers",[]):
        buf["uri"]="data:application/octet-stream;base64,"+base64.b64encode(binary[buf["uri"]]).decode()
    with open(path,"w",encoding="utf-8") as f:
        json.dump(doc,f,separators=(",",":"))
    print("GENERATED",path,os.path.getsize(path),"bytes",len(doc.get("meshes",[])),"PBR meshes")

# Original playable hero: Royal Vanguard, shield and sword silhouette.
s=trimesh.Scene()
cylinder(s,"gold base",.34,.16,(0,.08,0),M["gold"])
for x in (-.19,.19):
    box(s,"dark boots",(.23,.28,.42),(x,.22,-.02),M["leather"])
    box(s,"steel greaves",(.22,.48,.25),(x,.58,.02),M["steel"])
    ball(s,"knee guards",.16,(x,.91,0),(1,1.35,1),M["gold"])
ball(s,"under armor",.43,(0,1.42,0),(.95,1.35,.64),M["leather"])
ball(s,"cobalt cuirass",.43,(0,1.52,-.035),(1.05,1.25,.72),M["steel"])
box(s,"chest gold trim",(.47,.12,.07),(0,1.55,-.405),M["gold"])
ball(s,"arcane chest sigil",.13,(0,1.56,-.47),(.85,1.1,.38),M["crystal"])
for x in (-.53,.53):
    ball(s,"gold pauldron",.25,(x,1.94,0),(1.25,.9,.9),M["gold"])
    cylinder(s,"arm",.115,.58,(x*1.12,1.42,0),M["leather"])
    ball(s,"steel gauntlet",.16,(x*1.12,1.12,-.02),(1,1.1,1),M["steel"])
cylinder(s,"neck",.13,.18,(0,2.15,0),M["skin"])
ball(s,"face",.27,(0,2.42,0),(.9,1.12,.86),M["skin"])
ball(s,"gold helmet",.31,(0,2.59,.015),(1.12,.72,1.02),M["gold"])
box(s,"glowing visor",(.38,.09,.08),(0,2.42,-.255),M["crystal"])
cone(s,"helmet crest",.11,.4,(0,2.98,.04),M["gold"])
ball(s,"crimson cloak",.33,(0,1.45,.36),(1.25,1.8,.28),M["cloth"])
cylinder(s,"sword grip",.055,.52,(.78,1.12,-.02),M["leather"])
box(s,"sword guard",(.48,.08,.09),(.78,1.4,-.02),M["gold"])
box(s,"sword blade",(.13,.86,.055),(.78,1.86,-.02),M["stone"])
cone(s,"sword point",.085,.22,(.78,2.4,-.02),M["stone"])
ball(s,"sword pommel",.09,(.78,.82,-.02),(1,1,1),M["crystal"])
ball(s,"shield gold rim",.23,(-.82,1.38,-.02),(.85,1.35,.5),M["gold"])
ball(s,"shield cobalt face",.2,(-.82,1.4,-.075),(.8,1.25,.42),M["steel"])
ball(s,"shield crystal",.09,(-.82,1.4,-.25),(1,1,.45),M["crystal"])
box(s,"belt",(.65,.13,.42),(0,1.02,-.02),M["gold"])
save_gltf(s,os.path.join(OUT,"Royal_Vanguard.gltf"))

# A real 3D lane/forest tile: grass terrain, paving, river crossing, bridge,
# trees, layered bushes, rocks and individual grass blades.
s=trimesh.Scene()
box(s,"grass terrain",(64,.7,64),(0,-.35,0),M["grass"])
box(s,"stone lane",(62,.16,7.2),(0,.04,0),M["stone"])
for x in np.arange(-29,30,2.3):
    for z in (-2.25,0,2.25):
        box(s,"paving stones",(2.05,.12,1.9),(x,.16,z),M["stone"])
box(s,"river",(7,.08,64),(19,.01,0),M["water"])
box(s,"bridge deck",(9,.48,8),(19,.38,0),M["stone"])
for z in (-4.1,4.1):
    box(s,"bridge parapet",(9,.75,.28),(19,.82,z),M["stone"])
    for x in (15.5,18.5,21.5):
        box(s,"bridge gold posts",(.38,1,.48),(x,.9,z),M["gold"])
rng=np.random.default_rng(23)
for x,z,h in [(-26,-22,7),(-22,22,8),(-13,-25,6),(2,24,8),(29,22,7),(28,-22,8),(-29,5,7),(9,-27,6)]:
    cylinder(s,"tree trunk",.42,h*.62,(x,h*.31,z),M["bark"])
    for r,y,sy,mat in [(2.4,h*.68,1,M["leaf"]),(1.9,h*.94,.82,M["leaf2"]),(1.25,h*1.18,.67,M["leaf"])]:
        ball(s,"tree canopy",r,(x,y,z),(1,sy,1),mat)
for i in range(34):
    x=float(rng.uniform(-30,30)); z=float(rng.choice([-1,1])*rng.uniform(8,29))
    if 15<x<23: continue
    for j in range(3):
        ball(s,"bush leaves",.48,(x+float(rng.uniform(-.55,.55)),.35,z+float(rng.uniform(-.5,.5))),(.9,1.2,.9),M["leaf"] if j%2 else M["leaf2"])
for x,z,r in [(-20,-8,1.5),(-17,-11,1.1),(26,8,1.6),(28,11,1.1),(-4,27,1.4),(5,-28,1.6)]:
    ball(s,"limestone rocks",r,(x,r*.45,z),(1.35,.8,1),M["stone"])
for i in range(64):
    x=float(rng.uniform(-31,31)); z=float(rng.uniform(-31,31))
    if abs(z)<4.2 or 15<x<23: continue
    for j in range(2):
        cone(s,"grass blades",.09,float(rng.uniform(.35,.75)),(x+float(rng.uniform(-.2,.2)),.25,z+float(rng.uniform(-.2,.2))),M["leaf2"])
save_gltf(s,os.path.join(OUT,"Forest_Lane_Crossing.gltf"))
