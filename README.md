# SHADOW ARENA — Godot mobile prototype

An original dark-fantasy arena action prototype, designed mobile-first.

## First playable build
- Procedurally created 3D arena with glowing rune marks, crystal pillars and a boundary ring.
- **Kairon, Rift Guardian**: melee hero with 260 HP, basic strike, a 65-damage area Rift Pulse and a short invulnerable dash.
- Three enemy shades with simple chase-and-attack AI.
- Touch-and-drag movement on the left half of the screen; Strike, Rift and Dash buttons on the right.
- Win by defeating all three shades. Lose when Kairon's health reaches zero.
- Visuals are generated from Godot primitives and materials; no paid assets are required.

## Open on Android
1. Install the official Godot 4 Android Editor.
2. Download this branch as a ZIP and extract it on your phone.
3. In Godot Android Editor, import the extracted folder containing `project.godot`.
4. Open the project and press Play.

## Current limitations
This is a first playable prototype, not a finished release. It has not yet been run in the Godot editor in this environment. Test it on your phone and send any error text; the next pass should add proper character models and animations, sound, a visible joystick, smarter enemies, menus, progression, performance tuning and Android APK export.

## Future Unity move
The character designs, rules, balance, arena layout and reusable art assets can be carried forward. Godot GDScript will need to be rewritten in C# for Unity.
