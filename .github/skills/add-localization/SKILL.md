---
name: add-localization
description: 'Add or update localization strings in Cyber Cultivation. Use when: adding l10n keys, localizing UI text, translating strings, adding English and Chinese translations, updating ARB files, checking for hardcoded strings, running flutter gen-l10n, or auditing a file for missing localizations.'
---

# Add Localization

Add or update strings in both `lib/l10n/app_en.arb` (template) and `lib/l10n/app_zh.arb`.

## Procedure

### 1. Identify strings

Search target widget/dialog for hardcoded user-facing text (Text content, button labels, tooltips, dialog titles, error messages, placeholders).

### 2. Choose key names

- camelCase, grouped by feature: `snakeGameTitle`, `snakeGameDescription`
- Suffix patterns: `*Title`, `*Description`, `*Text`, `*Label`, `*Hint`, `*Button`, `*Error`, `*Message`
- Never reuse existing keys for different meanings

### 3. Add to English ARB (template)

Every key needs a `@` metadata entry with `description`:

```json
"featureTitle": "Feature Title",
"@featureTitle": {
  "description": "Title for the feature dialog"
}
```

### 4. Add to Chinese ARB

Same keys, Chinese translations. `@` metadata optional here:

```json
"featureTitle": "功能标题"
```

### 5. Use in code

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.featureTitle)
```

For callback contexts (e.g. `GameEntry`): `getTitle: (l10n) => l10n.featureTitle`

### 6. Verify key consistency

Every key in `app_en.arb` must exist in `app_zh.arb` and vice versa.

## Parameterized Strings

Use ICU message format for dynamic values:

```json
"levelDisplay": "Level {level}",
"@levelDisplay": {
  "description": "Display current level",
  "placeholders": {
    "level": { "type": "int" }
  }
}
```

Usage: `l10n.levelDisplay(playerLevel)`

## Native Swift Views (Popovers & Tray Popup)

Swift views in `macos/Runner/` (MenuBarPopoverView.swift, TrayPopupView.swift) do NOT do their own locale checks. Instead, Flutter pre-resolves strings and sends them as a `labels` dictionary via method channels.

To add a string used in a Swift view:

1. Add the key to both ARB files (prefix with `popover*` for popover strings)
2. Run `flutter gen-l10n`
3. Add the key to `_buildNativeLabels()` in `lib/main.dart`:
   ```dart
   'myNewLabel': l10n.popoverMyNewLabel,
   ```
4. Use it in Swift as `labels["myNewLabel"] ?? "Fallback"`

**Never** add `locale == "zh" ? ... : ...` patterns in Swift files.

## Pitfalls

- Keys in Chinese but not English → build failure (English is the template)
- Missing `@` metadata → gen-l10n warning
- Native Swift labels not updating → check `_buildNativeLabels()` includes the new key
- Trailing commas in JSON → parse error
