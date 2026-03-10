---
name: build-release
description: 'Build and release Cyber Cultivation for macOS. Use when: building DMG, creating a release, bumping version, packaging for distribution, running the build pipeline, or verifying the release process.'
---

# Build Release

Build a macOS DMG release via `tools/build_macos_dmg.sh`.

## Procedure

### 1. Bump version in `pubspec.yaml`

```yaml
version: X.Y.Z+BUILD
```

- **Patch** (`0.0.X`): Bug fixes, minor tweaks
- **Minor** (`0.X.0`): New features
- **Major** (`X.0.0`): Breaking changes

### 2. Pre-build checks

```bash
flutter test
flutter analyze
git status  # Ensure clean working tree
```

### 3. Build DMG

```bash
cd tools && bash build_macos_dmg.sh
```

The script extracts version from `pubspec.yaml`, runs `flutter clean && flutter pub get && flutter build macos --release`, ad-hoc code signs, and creates `dist/CyberCultivation-{VERSION}-macos.dmg`.

For CI mode (skip clean/pub get): `bash build_macos_dmg.sh --ci`

### 4. Verify

Mount DMG, launch app, verify version, test core features (EXP gain, settings, explore, games).

### 5. Release (optional)

Push version bump to `main`/`master` — `.github/workflows/build-macos.yml` auto-detects the change and creates a GitHub Release. Or trigger manually via workflow dispatch.
