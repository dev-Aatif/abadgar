# Abadgar

Local-first offline financial and harvest tracker for Rice and Wheat farmers, built with Flutter, Riverpod, GoRouter, and local SQLite (`sqlite_async`). Supports English (`en`), Urdu (`ur`), and Sindhi (`sd`) RTL localization, encrypted backups (`.abadgar` AES-256-GCM), plain JSON export/import, and automatic rolling local backups.

## Setup

1. **Install dependencies & generate code:**
   ```bash
   flutter pub get
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Android Release Signing:**
   Create `android/key.properties` (gitignored) with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` before running `flutter build apk --release`.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
dart run custom_lint
flutter test
```
