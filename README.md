# SHADOW ARENA — Godot 4 Android prototype

A mobile-first dark-fantasy 3D action game.

## Open-world update
- Expanded playable terrain to approximately **1000 × 1000 world units**.
- Procedural rolling landscape with vertex-coloured ground, two lakes, distant rune spires and rocky outcrops.
- Forest canopy and grass are rendered with MultiMesh instancing to reduce draw-call overhead on mobile devices.
- Camera follows the player across the expanded map.
- Wildlife: roaming wolf packs, territorial bears and two large dragon creatures.
- Creatures use simple roaming, aggro and attack behaviours and can be damaged by the player's basic attack.
- Player movement is no longer restricted to the original small arena.

## Hero collection
- 30 original heroes, six combat roles and many elemental themes.
- Every hero has a designed first skill, second skill and ultimate.
- A procedural 3D hero gallery lets players inspect each model and read their abilities.

## Android setup
1. Install Godot 4 Android Editor.
2. Download and extract this branch ZIP.
3. Import the folder containing project.godot.
4. Press Play.

## Important testing notes
This is a procedural prototype, not a finished photorealistic open-world release. Terrain, vegetation, wildlife and creature AI are generated from Godot primitives and scripts. The world update has been committed but has **not** been run through the Godot editor or profiled on the target phone in this environment. Large scenes can be demanding; lower-end devices may need fewer trees, grass instances, shadows or creatures. No APK has been built or verified from this update.

## Unity portability
The world layout, creature concepts, hero roster, balance data and design can be reused. Godot GDScript will need to be rewritten in C# for Unity.
