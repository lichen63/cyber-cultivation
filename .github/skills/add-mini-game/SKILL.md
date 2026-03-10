---
name: add-mini-game
description: 'Add a new mini-game to Cyber Cultivation. Use when: creating a new game, adding a mini-game, implementing an arcade game, building a puzzle game, adding a casual game with EXP rewards. Covers game widget creation with BaseGameWindow mixins, registration in games list dialog, EXP reward wiring, constants, localization, and tests.'
---

# Add Mini-Game

Follow the pattern established by Snake, Flappy Bird, and Sudoku.

## Procedure

### 1. Add constants to `lib/constants.dart`

Add game-specific values (board size, speeds, scoring, EXP rewards) in `GameConstants` or a new class.

### 2. Create game widget at `lib/widgets/<game_name>_game_window.dart`

Required constructor signature — must match existing games:

```dart
class NewGameWindow extends StatefulWidget {
  final AppThemeColors themeColors;
  final void Function(int expGained) onExpGained;
  const NewGameWindow({super.key, required this.themeColors, required this.onExpGained});
}
```

State class must use both mixins from `base_game_window.dart`:

```dart
class _NewGameWindowState extends State<NewGameWindow>
    with GameKeyboardMixin, GameRestartCooldownMixin {
```

- `GameKeyboardMixin` — call `handleCommonKeyEvent(event)` for ESC-to-close
- `GameRestartCooldownMixin` — call `startRestartCooldown()` on game start, use `tryRestart(callback)` for restart button
- `GameOverlayBuilder` — use `buildStartOverlay()` and `buildGameOverOverlay()` for consistent start/game-over screens
- Call `widget.onExpGained(exp)` on game over to grant EXP

### 3. Register in `lib/widgets/games_list_dialog.dart`

Add a `GameEntry` to the `_getGames()` list:

```dart
GameEntry(
  getTitle: (l10n) => l10n.newGameTitle,
  getDescription: (l10n) => l10n.newGameDescription,
  icon: Icons.chosen_icon,
  iconColor: Colors.chosen,
  buildGame: (colors, onExp) =>
      NewGameWindow(themeColors: colors, onExpGained: onExp),
),
```

### 4. Add localization keys

Add `<game>Title` and `<game>Description` keys to both `lib/l10n/app_en.arb` (with `@` metadata) and `lib/l10n/app_zh.arb`.

### 5. Add widget tests at `test/widgets/<game_name>_game_window_test.dart`

Cover: renders without error, initial waiting state, game start, game over calls `onExpGained`, ESC closes, restart cooldown.

## EXP Reward Scale

Simple/short: 10–50 · Medium: 50–200 · Long/difficult: 200–500 · Scale with performance.
