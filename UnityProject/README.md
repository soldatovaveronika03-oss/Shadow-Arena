# ATLAS WILDS ARENA — Unity Edition

This is a separate Unity project. The existing Godot project remains untouched at the repository root.

## Open
1. Install Unity Hub and a Unity 6 LTS Editor.
2. In Unity Hub choose **Add > Add project from disk** and select the `UnityProject` folder.
3. If Unity asks to install a matching editor version, use the Unity 6 LTS version selected for this project.
4. Wait for the first import to finish. The editor setup script creates a starter arena scene automatically.

## Android modules
In Unity Hub > Installs > (Editor) > Add modules, install:
- Android Build Support
- Android SDK & NDK Tools
- OpenJDK

## Current milestone
The project setup creates a simple 3D arena prototype to verify that the Unity project opens and runs. It is not yet the finished MOBA. Gameplay, art, animations, multiplayer, and production Android build configuration will be developed in later milestones.

## Important
Do not delete the Godot files at the repository root. Do not commit the `Library`, `Temp`, `Obj`, `Logs`, or `Build` folders.
