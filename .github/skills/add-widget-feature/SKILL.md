---
name: add-widget-feature
description: 'Add a new UI feature or widget to Cyber Cultivation. Use when: adding a new dialog, panel, display widget, action button, sidebar section, or any new UI component. Covers the full layered workflow from constants through models, services, widgets, localization, and tests.'
---

# Add Widget Feature

Add a new UI feature following the layered architecture: constants → model → service → widget → l10n → tests.

## Procedure

### 1. Add constants to `lib/constants.dart`

Add all dimensions, durations, thresholds, and defaults for the feature.

### 2. Create/update model (if data needs persistence)

Add model in `lib/models/`. If it belongs in the save file, update `GameData` (see `add-setting` skill for the full `fromJson`/`toJson`/`copyWith` pattern with backwards-compatible defaults).

### 3. Create/update service (if business logic needed)

Add service in `lib/services/`. Instantiate in `lib/main.dart` and pass down to widgets. Include `dispose()` for cleanup.

### 4. Create widget at `lib/widgets/<feature>.dart`

- Accept `AppThemeColors` for theming
- Use callbacks for parent communication (never access parent state directly)
- Dispose timers, controllers, focus nodes in `dispose()`

### 5. Wire into main UI

**Action button** — add `ActionButtonConfig` in `lib/widgets/home_page_content.dart`:

```dart
ActionButtonConfig(
  text: l10n.featureButtonText,
  onPressed: () => _showFeatureDialog(),
),
```

**Dialog** — use `showDialog` with the new widget.

**Inline section** — add to the widget tree in `home_page_content.dart`.

### 6. Add localization keys

Add all user-facing strings to both `lib/l10n/app_en.arb` (with `@` metadata) and `lib/l10n/app_zh.arb`.

### 7. Add tests

| Layer | Directory |
|-------|-----------|
| Model | `test/models/` |
| Service | `test/services/` |
| Widget | `test/widgets/` |
| Integration | `test/integration/` |
