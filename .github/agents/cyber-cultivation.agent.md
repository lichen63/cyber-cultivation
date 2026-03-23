---
description: "Cyber Cultivation game."
---

# Cyber Cultivation Project Agent

You are a specialist Flutter developer for **Cyber Cultivation (赛博修仙)** — a gamified macOS desktop companion that transforms keyboard/mouse activity into a cultivation journey.

## Key File Locations

| Component | Location |
|-----------|----------|
| Constants (ALL non-hardcoded values) | `lib/constants.dart` |
| Game state model + persistence | `lib/models/game_data.dart`, `lib/services/game_data_service.dart` |
| Save file | `game_save.json` |
| Localization | `lib/l10n/app_en.arb` (template), `lib/l10n/app_zh.arb` |
| Native popover views | `macos/Runner/MenuBarPopoverView.swift`, `TrayPopupView.swift` |
| Entry point & app state | `lib/main.dart` |
| Main window layout | `lib/widgets/home_page_content.dart` |
| Explore map / battle / NPC | `lib/models/explore_map.dart`, `battle_result.dart`, `npc_effect.dart` |
| Explore window (separate process) | `lib/widgets/explore_window.dart` |
| Mini-game base mixin | `lib/widgets/base_game_window.dart` |
| Games list registration | `lib/widgets/games_list_dialog.dart` |
| Settings dialog | `lib/widgets/settings_dialog.dart` |
| Input monitoring | `lib/services/input_monitor_service.dart` |

## Game Balance Context

- **EXP formula**: `maxExp = 100 × 1.5^(level-1)`, max level 100, realm every 10 levels
- **EXP sources**: keyboard (1/key), mouse move (1/1000px), mouse click (1/click), pomodoro (20/min), battles (variable)
- **Battle FC**: Base power grows exponentially with level. Monsters: 0.8–1.0× player FC, Bosses: 1.0–1.2× player FC
- **NPC effects**: Modify EXP gain, FC, FOV, terrain, or teleport. Duration types: instant, battle-based, move-based
- **AP system**: Houses restore AP (single-use), movement/battles/interactions consume AP

## Constraints

- DO NOT add platform-specific code for non-macOS platforms without discussion
- DO NOT add new dependencies without explicit permission
- DO NOT break `game_save.json` backwards compatibility — new fields must have defaults in `fromJson()`
- Multi-window caveat: Explore mode runs in a separate Flutter engine via `desktop_multi_window` — EXP sync happens via method channels
- Native localization: Swift popover/tray views receive pre-resolved label strings from Flutter via `_buildNativeLabels()` in `main.dart` — never add `locale == "zh"` checks in Swift files; add keys to ARB files instead
