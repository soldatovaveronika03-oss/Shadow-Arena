# ATLAS WILDS ARENA

Основной проект переводится на **Unreal Engine 5.5**.

## Структура
- `AtlasWildsArena.uproject` — файл проекта Unreal Engine.
- `Source/AtlasWildsArena` — C++ модуль и базовый персонаж от третьего лица с камерой.
- `Config/` — настройки проекта и Android (Landscape, ARM64, пакет com.atlaswilds.arena).
- `UnityProject/` — сохранённая прежняя заготовка Unity.
- `assets/` — общая папка ресурсов; сохраняется для переноса совместимых моделей и текстур.

## Первый запуск
1. Установить Unreal Engine 5.5 на Windows.
2. Установить Android SDK, NDK и JDK, совместимые с UE 5.5 (через Android Studio/Turnkey).
3. Открыть `AtlasWildsArena.uproject`, сгенерировать файлы проекта и собрать C++ модуль.
4. Создать стартовую карту и Blueprint-наследник `AtlasPlayerCharacter`, назначить его Default Pawn в GameMode.
5. Настроить экранное управление и проверить проект на Android.

## Важно
Обычный GitHub Actions runner не содержит Unreal Engine. APK-сборку нельзя запустить на нём без отдельного установленного UE build environment и Android toolchain. Текущий репозиторий содержит стартовую основу UE5, а не готовую игру или APK.
