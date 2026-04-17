import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/github_updater.dart';
import '../../../core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final dbAsync = ref.watch(powerSyncDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'APPEARANCE'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Theme Mode'),
                  subtitle: Text(themeMode.name.toUpperCase()),
                  onTap: () => _showThemeDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Language'),
                  subtitle: Text(_getLocaleName(locale)),
                  onTap: () => _showLanguageDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _SectionHeader(title: 'DATA MANAGEMENT'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Export Data (JSON)'),
                  subtitle: const Text('Save your data to a local file'),
                  onTap: () async {
                    final db = await ref.read(powerSyncDatabaseProvider.future);
                    await ExportService(db).exportDatabase();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Import Data (JSON)'),
                  subtitle: const Text('Restore data from a backup'),
                  onTap: () async {
                    final db = await ref.read(powerSyncDatabaseProvider.future);
                    final success = await ImportService(db).importDatabase();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Successful!')));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text('Manual Sync'),
                  subtitle: dbAsync.when(
                    data: (db) => const Text('Connected to PowerSync'),
                    loading: () => const Text('Connecting...'),
                    error: (_, __) => const Text('Offline / Error'),
                  ),
                  onTap: () {
                    // PowerSync handles sync automatically
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: 'ABOUT'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.system_update_rounded),
                  title: const Text('Check for Updates'),
                  onTap: () async {
                    try {
                      final update = await GithubUpdater.checkForUpdates();
                      if (context.mounted) {
                        _showUpdateDialog(context, update);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No updates found or failed to check.')));
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('App Version'),
                      subtitle: Text(snapshot.data?.version ?? 'Loading...'),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'ur': return 'Urdu (اردو)';
      case 'sd': return 'Sindhi (سنڌي)';
      default: return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(label: 'English', locale: const Locale('en'), ref: ref),
            _LanguageOption(label: 'Urdu (اردو)', locale: const Locale('ur'), ref: ref),
            _LanguageOption(label: 'Sindhi (سنڌي)', locale: const Locale('sd'), ref: ref),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
             return RadioListTile<ThemeMode>(
               title: Text(mode.name.toUpperCase()),
               value: mode,
               groupValue: ref.watch(themeModeNotifierProvider),
               onChanged: (val) {
                 ref.read(themeModeNotifierProvider.notifier).setThemeMode(val!);
                 Navigator.pop(context);
               },
             );
          }).toList(),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo update) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(update.isUpdateAvailable ? 'Update Available!' : 'You are up to date'),
        content: Text(update.isUpdateAvailable 
            ? 'Latest version: ${update.latestVersion}\n\n${update.releaseNotes}'
            : 'You are using the latest version of Abadgar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (update.isUpdateAvailable)
            ElevatedButton(onPressed: () {}, child: const Text('Download')),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final Locale locale;
  final WidgetRef ref;

  const _LanguageOption({required this.label, required this.locale, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<Locale>(
      title: Text(label),
      value: locale,
      groupValue: ref.watch(localeNotifierProvider),
      onChanged: (val) {
        ref.read(localeNotifierProvider.notifier).setLocale(val!);
        Navigator.pop(context);
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
