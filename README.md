# Abadgar

Offline-first financial and harvest tracker for Rice and Wheat farmers, built with Flutter, Riverpod, GoRouter, PowerSync (SQLite), and Supabase. Supports English (`en`), Urdu (`ur`), and Sindhi (`sd`) RTL localization.

## Setup

1. **Install dependencies & generate code:**
   ```bash
   flutter pub get
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Configure environment (optional for local-only mode):**
   Pass values at build time via `--dart-define` (`.env` is not bundled into release APKs):
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key \
     --dart-define=POWERSYNC_URL=https://your-instance.powersync.com
   ```
   If credentials are omitted, Abadgar runs in local-only offline mode using PowerSync SQLite.

3. **Database Migrations:**
   Apply SQL migrations in `supabase/migrations/` (`001` through `005`) to your Supabase project before enabling cloud sync.

4. **Android Release Signing:**
   Create `android/key.properties` (gitignored) with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` before running `flutter build apk --release`.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
dart run custom_lint
flutter test
```
