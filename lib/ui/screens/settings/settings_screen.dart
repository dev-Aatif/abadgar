import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/github_updater.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/lands_provider.dart';
import '../../../core/models/land.dart';

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
          _SectionHeader(title: 'FARM PROFILE'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.landscape_rounded),
              title: const Text('Manage Lands'),
              subtitle: const Text('Define your farm area'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showManageLandsSheet(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: AppLocalizations.of(context)!.appearance.toUpperCase()),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: Text(AppLocalizations.of(context)!.themeMode, overflow: TextOverflow.ellipsis),
                  subtitle: Text(themeMode.value?.name.toUpperCase() ?? '...', overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  onTap: () => _showThemeDialog(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(AppLocalizations.of(context)!.language, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_getLocaleName(locale.value ?? const Locale('en')), overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  onTap: () => _showLanguageDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _SectionHeader(title: AppLocalizations.of(context)!.dataManagement.toUpperCase()),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(AppLocalizations.of(context)!.exportData, overflow: TextOverflow.ellipsis),
                  subtitle: const Text('Share backup', overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    final db = await ref.read(powerSyncDatabaseProvider.future);
                    await ExportService(db).exportDatabase();
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(AppLocalizations.of(context)!.downloadData, overflow: TextOverflow.ellipsis),
                  subtitle: const Text('Save to device', overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    final db = await ref.read(powerSyncDatabaseProvider.future);
                    await ExportService(db).downloadDatabase();
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(AppLocalizations.of(context)!.importData, overflow: TextOverflow.ellipsis),
                  subtitle: const Text('Restore backup', overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    final db = await ref.read(powerSyncDatabaseProvider.future);
                    final success = await ImportService(db).importDatabase();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Successful!')));
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: Text(AppLocalizations.of(context)!.manualSync, overflow: TextOverflow.ellipsis),
                  subtitle: dbAsync.when(
                    data: (db) => Text(AppLocalizations.of(context)!.connected, overflow: TextOverflow.ellipsis),
                    loading: () => Text(AppLocalizations.of(context)!.connecting, overflow: TextOverflow.ellipsis),
                    error: (_, __) => Text(AppLocalizations.of(context)!.offline, overflow: TextOverflow.ellipsis),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: AppLocalizations.of(context)!.about.toUpperCase()),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.system_update_rounded),
                  title: Text(AppLocalizations.of(context)!.checkUpdates, overflow: TextOverflow.ellipsis),
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
                const Divider(height: 1, indent: 56),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(AppLocalizations.of(context)!.version, overflow: TextOverflow.ellipsis),
                      subtitle: Text(snapshot.data?.version ?? 'Loading...', overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    );
                  },
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManageLandsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManageLandsContent(),
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
        title: Text(AppLocalizations.of(context)!.language),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(label: 'English', locale: const Locale('en')),
              _LanguageOption(label: 'Urdu (اردو)', locale: const Locale('ur')),
              _LanguageOption(label: 'Sindhi (سنڌي)', locale: const Locale('sd')),
            ],
          ),
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
               groupValue: ref.watch(themeModeNotifierProvider).value,
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

class _ManageLandsContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManageLandsContent> createState() => _ManageLandsContentState();
}

class _ManageLandsContentState extends ConsumerState<_ManageLandsContent> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final landsAsync = ref.watch(landsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Manage Lands', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Add New Land Form
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Land Name', prefixIcon: Icon(Icons.title))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _areaController, 
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                    decoration: const InputDecoration(labelText: 'Area', suffixText: 'Acres', prefixIcon: Icon(Icons.square_foot)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _add, 
                    child: const Text('Add Land'),
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 32),
          
          // List of Lands
          landsAsync.when(
            data: (lands) => Column(
              children: lands.map((l) => ListTile(
                leading: const Icon(Icons.landscape),
                title: Text(l.name),
                subtitle: Text('${l.area} Acres'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => ref.read(landsNotifierProvider.notifier).deleteLand(l.id),
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }

  void _add() {
    final name = _nameController.text;
    final area = double.tryParse(_areaController.text) ?? 0;
    if (name.isNotEmpty && area > 0) {
      ref.read(landsNotifierProvider.notifier).addLand(name: name, area: area);
      _nameController.clear();
      _areaController.clear();
    }
  }
}

class _LanguageOption extends ConsumerWidget {
  final String label;
  final Locale locale;

  const _LanguageOption({required this.label, required this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RadioListTile<Locale>(
      title: Text(label),
      value: locale,
      groupValue: ref.watch(localeNotifierProvider).value,
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
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8, top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
