# ATLAS WILDS

Мобильный 3D survival/adventure-прототип на Godot 4.

## Состав
- `project.godot` — настройки проекта и управления.
- `scenes/Main.tscn` — главная сцена.
- `scripts/Main.gd` — окружение, ландшафт, деревья и существа.
- `scripts/Player.gd` — персонаж, движение, прыжок и камера.
- `scripts/MobileHUD.gd` — экранные кнопки.
- `scripts/Creature.gd` — поведение существ.
- `.github/workflows/build-android.yml` — сборка Android APK через GitHub Actions.

## Сборка APK
Открой вкладку Actions и запусти workflow **Build ATLAS WILDS Android APK**. После успешной сборки скачай artifact `atlas-wilds-android-debug`.

Движок: Godot 4.4.1 в CI. Целевая архитектура Android: ARM64.
