---
name: add-setting
description: 'Add a new user setting to Cyber Cultivation. Use when: adding a toggle, option, preference, configuration value, slider, dropdown, or any persistent setting. Covers GameData model update, JSON serialization with backwards compatibility, settings dialog UI wiring, constants, localization, and tests.'
---

# Add Setting

Add a persistent setting across the full stack: constant → model → dialog → main.dart wiring.

## Procedure

### 1. Add default constant in `lib/constants.dart`

```dart
static const bool defaultNewSettingEnabled = false;
```

### 2. Update `lib/models/game_data.dart`

Five touch points — all required:

```dart
// Field declaration
final bool isNewSettingEnabled;

// Constructor parameter with default
this.isNewSettingEnabled = AppConstants.defaultNewSettingEnabled,

// toJson()
'isNewSettingEnabled': isNewSettingEnabled,

// fromJson() — MUST use null-safe fallback for backwards compatibility
isNewSettingEnabled: json['isNewSettingEnabled'] as bool? ??
    AppConstants.defaultNewSettingEnabled,

// copyWith()
bool? isNewSettingEnabled,
// ...in body:
isNewSettingEnabled: isNewSettingEnabled ?? this.isNewSettingEnabled,
```

**Critical**: The `fromJson()` pattern `as Type? ?? default` ensures existing save files without this field load without error.

### 3. Add UI in `lib/widgets/settings_dialog.dart`

Add constructor parameter + callback, local state in `initState()`, and the control widget.

For boolean toggle use `_buildSwitchTile`:

```dart
_buildSwitchTile(
  title: l10n.newSettingText,
  value: _isNewSettingEnabled,
  onChanged: (value) {
    setState(() => _isNewSettingEnabled = value);
    widget.onNewSettingChanged(value);
  },
)
```

For integer +/- controls, use Row with IconButton + Text display (see existing refresh interval pattern).

### 4. Wire in `lib/main.dart`

Pass value to dialog, handle callback with `copyWith` + `_saveGameData()`:

```dart
onNewSettingChanged: (value) {
  setState(() {
    _gameData = _gameData.copyWith(isNewSettingEnabled: value);
  });
  _saveGameData();
},
```

### 5. Add localization keys

Add setting label to both `lib/l10n/app_en.arb` (with `@` metadata) and `lib/l10n/app_zh.arb`.

### 6. Add tests in `test/models/game_data_test.dart`

Cover: `toJson()` includes field, `fromJson()` reads correctly, `fromJson()` with missing field falls back to default, `copyWith()` updates field.
