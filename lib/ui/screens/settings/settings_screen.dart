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
import '../../../core/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final dbAsync = ref.watch(powerSyncDatabaseProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(context, ref),
          const SizedBox(height: 32),

          _SectionHeader(title: AppLocalizations.of(context)!.farmProfile.toUpperCase()),
          _buildSettingsTile(
            context: context,
            icon: Icons.landscape_rounded,
            color: Colors.green,
            title: AppLocalizations.of(context)!.manageLands,
            subtitle: AppLocalizations.of(context)!.defineFarmArea,
            onTap: () => _showManageLandsSheet(context, ref),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: AppLocalizations.of(context)!.appearance.toUpperCase()),
          _buildSettingsTile(
            context: context,
            icon: Icons.dark_mode_rounded,
            color: Colors.purple,
            title: AppLocalizations.of(context)!.themeMode,
            subtitle: _getThemeModeName(context, themeMode.value ?? ThemeMode.system),
            onTap: () => _showThemeDialog(context, ref),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context: context,
            icon: Icons.language_rounded,
            color: Colors.blue,
            title: AppLocalizations.of(context)!.language,
            subtitle: _getLocaleName(locale.value ?? const Locale('en')),
            onTap: () => _showLanguageDialog(context, ref),
          ),
          const SizedBox(height: 24),
          
          _SectionHeader(title: AppLocalizations.of(context)!.dataManagement.toUpperCase()),
          _buildSettingsTile(
            context: context,
            icon: Icons.file_upload_outlined,
            color: Colors.orange,
            title: AppLocalizations.of(context)!.exportData,
            subtitle: AppLocalizations.of(context)!.shareBackup,
            onTap: () async {
              final db = await ref.read(powerSyncDatabaseProvider.future);
              await ExportService(db).exportDatabase();
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context: context,
            icon: Icons.download_rounded,
            color: Colors.teal,
            title: AppLocalizations.of(context)!.downloadData,
            subtitle: AppLocalizations.of(context)!.saveToDevice,
            onTap: () async {
              final db = await ref.read(powerSyncDatabaseProvider.future);
              await ExportService(db).downloadDatabase();
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context: context,
            icon: Icons.file_download_outlined,
            color: Colors.redAccent,
            title: AppLocalizations.of(context)!.importData,
            subtitle: AppLocalizations.of(context)!.restoreBackup,
            onTap: () async {
              final db = await ref.read(powerSyncDatabaseProvider.future);
              final success = await ImportService(db).importDatabase();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.importSuccessful)));
              }
            },
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: AppLocalizations.of(context)!.about.toUpperCase()),
          _buildSettingsTile(
            context: context,
            icon: Icons.system_update_rounded,
            color: Colors.deepOrange,
            title: AppLocalizations.of(context)!.checkUpdates,
            onTap: () async {
              try {
                final update = await GithubUpdater.checkForUpdates();
                if (context.mounted) {
                  _showUpdateDialog(context, update);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.updateCheckFailed)));
                }
              }
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              return _buildSettingsTile(
                context: context,
                icon: Icons.info_outline_rounded,
                color: Colors.blueGrey,
                title: AppLocalizations.of(context)!.version,
                subtitle: snapshot.data?.version ?? AppLocalizations.of(context)!.loading,
                trailing: const SizedBox.shrink(),
              );
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState?.user;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.account,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email != null 
                    ? AppLocalizations.of(context)!.loggedInAs(user!.email!)
                    : AppLocalizations.of(context)!.guestUser,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              onPressed: () {
                ref.read(authStateProvider.notifier).signOut();
              },
              tooltip: AppLocalizations.of(context)!.signOut,
            )
          else
            TextButton(
              onPressed: () => context.push('/auth'),
              child: Text(AppLocalizations.of(context)!.signIn),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
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

  String _getThemeModeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return AppLocalizations.of(context)!.themeSystem;
      case ThemeMode.light: return AppLocalizations.of(context)!.themeLight;
      case ThemeMode.dark: return AppLocalizations.of(context)!.themeDark;
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.language),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(label: 'English', locale: Locale('en')),
              _LanguageOption(label: 'Urdu (اردو)', locale: Locale('ur')),
              _LanguageOption(label: 'Sindhi (سنڌي)', locale: Locale('sd')),
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
        title: Text(AppLocalizations.of(context)!.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
             return RadioListTile<ThemeMode>(
               title: Text(_getThemeModeName(context, mode)),
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
        title: Text(update.isUpdateAvailable ? AppLocalizations.of(context)!.updateAvailable : AppLocalizations.of(context)!.upToDate),
        content: Text(update.isUpdateAvailable 
            ? '${AppLocalizations.of(context)!.latestVersion(update.latestVersion)}\n\n${update.releaseNotes}'
            : AppLocalizations.of(context)!.upToDateContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.close)),
          if (update.isUpdateAvailable)
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(update.downloadUrl)), 
              child: Text(AppLocalizations.of(context)!.download)
            ),
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
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

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
          Text(AppLocalizations.of(context)!.manageLands, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Add New Land Form
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _nameController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.landName, prefixIcon: const Icon(Icons.title))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _areaController, 
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.area, suffixText: AppLocalizations.of(context)!.acresUnit, prefixIcon: const Icon(Icons.square_foot)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _add, 
                    child: Text(AppLocalizations.of(context)!.addLand),
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
                subtitle: Text('${l.area} ${AppLocalizations.of(context)!.acresUnit}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.deleteLand),
                        content: Text(AppLocalizations.of(context)!.confirmDeleteLand),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(landsNotifierProvider.notifier).deleteLand(l.id);
                    }
                  },
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(AppLocalizations.of(context)!.errorGeneral(err.toString())),
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
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidLandDetails)));
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
