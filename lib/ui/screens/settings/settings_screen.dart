import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/lands_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/github_updater.dart';
import '../../../core/services/import_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/notifications.dart';
import '../../widgets/app_surface.dart';
import '../../widgets/transaction_form/parts/form_shared.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.sm, AppSpace.lg, 48),
        children: [
          _ProfileCard(),
          const SizedBox(height: AppSpace.xl),

          // Farm Profile
          _GroupLabel(title: l10n.farmProfile),
          AppCard(
            child: _SettingsRow(
              icon: Icons.landscape_outlined,
              title: l10n.manageLands,
              subtitle: l10n.defineFarmArea,
              onTap: () => _showManageLandsSheet(context),
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Appearance
          _GroupLabel(title: l10n.appearance),
          AppCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.brightness_6_outlined,
                  title: l10n.themeMode,
                  trailingText: _getThemeModeName(
                      context, themeMode.value ?? ThemeMode.system),
                  onTap: () => _showThemeDialog(context, ref),
                  showDivider: true,
                ),
                _SettingsRow(
                  icon: Icons.translate_rounded,
                  title: l10n.language,
                  trailingText:
                      _getLocaleName(locale.value ?? const Locale('en')),
                  onTap: () => _showLanguageDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Data Management
          _GroupLabel(title: l10n.dataManagement),
          AppCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.ios_share_rounded,
                  title: l10n.exportData,
                  subtitle: l10n.shareBackup,
                  showDivider: true,
                  onTap: () async {
                    try {
                      final db =
                          await ref.read(powerSyncDatabaseProvider.future);
                      await ExportService(db).exportDatabase();
                    } catch (e, st) {
                      appLogger.e('Export backup failed',
                          error: e, stackTrace: st);
                      if (context.mounted) {
                        AppNotification.show(
                            context, l10n.errorGeneral(l10n.exportData),
                            isError: true);
                      }
                    }
                  },
                ),
                _SettingsRow(
                  icon: Icons.download_outlined,
                  title: l10n.downloadData,
                  subtitle: l10n.saveToDevice,
                  showDivider: true,
                  onTap: () async {
                    try {
                      final db =
                          await ref.read(powerSyncDatabaseProvider.future);
                      await ExportService(db).downloadDatabase();
                    } catch (e, st) {
                      appLogger.e('Download backup failed',
                          error: e, stackTrace: st);
                      if (context.mounted) {
                        AppNotification.show(
                            context, l10n.errorGeneral(l10n.downloadData),
                            isError: true);
                      }
                    }
                  },
                ),
                _SettingsRow(
                  icon: Icons.restore_rounded,
                  title: l10n.importData,
                  subtitle: l10n.restoreBackup,
                  onTap: () async {
                    try {
                      final db =
                          await ref.read(powerSyncDatabaseProvider.future);
                      final success = await ImportService(db).importDatabase();
                      if (success) {
                        ref.invalidate(activeSeasonIdProvider);
                        if (context.mounted) {
                          AppNotification.show(context, l10n.importSuccessful);
                        }
                      }
                    } catch (e, st) {
                      appLogger.e('Import backup failed',
                          error: e, stackTrace: st);
                      if (context.mounted) {
                        AppNotification.show(
                            context, l10n.errorGeneral(l10n.importData),
                            isError: true);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // About
          _GroupLabel(title: l10n.about),
          AppCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.system_update_outlined,
                  title: l10n.checkUpdates,
                  showDivider: true,
                  onTap: () async {
                    try {
                      final update = await GithubUpdater.checkForUpdates();
                      if (context.mounted) _showUpdateDialog(context, update);
                    } catch (_) {
                      if (context.mounted) {
                        AppNotification.show(context, l10n.updateCheckFailed,
                            isError: true);
                      }
                    }
                  },
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: l10n.version,
                      trailingText: snapshot.data?.version ?? l10n.loading,
                      trailingWidget: const SizedBox.shrink(),
                      iconColor: tokens.inkMuted,
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

  void _showManageLandsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManageLandsContent(),
    );
  }

  String _getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'ur':
        return 'اردو';
      case 'sd':
        return 'سنڌي';
      default:
        return 'English';
    }
  }

  String _getThemeModeName(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale =
        ref.read(localeNotifierProvider).value ?? const Locale('en');
    const options = [
      (label: 'English', locale: Locale('en')),
      (label: 'Urdu (اردو)', locale: Locale('ur')),
      (label: 'Sindhi (سنڌي)', locale: Locale('sd')),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected =
                currentLocale.languageCode == opt.locale.languageCode;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(opt.label),
              trailing: isSelected
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(localeNotifierProvider.notifier).setLocale(opt.locale);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentMode =
        ref.read(themeModeNotifierProvider).value ?? ThemeMode.system;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            final isSelected = currentMode == mode;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_getThemeModeName(context, mode)),
              trailing: isSelected
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo update) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            update.isUpdateAvailable ? l10n.updateAvailable : l10n.upToDate),
        content: Text(
          update.isUpdateAvailable
              ? '${l10n.latestVersion(update.latestVersion)}\n\n${update.releaseNotes}'
              : l10n.upToDateContent,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
          if (update.isUpdateAvailable &&
              GithubUpdater.isTrustedDownloadUrl(update.downloadUrl))
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(update.downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(l10n.download),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final authState = ref.watch(authStateProvider);
    final user = authState?.user;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.account,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  user?.email != null
                      ? l10n.loggedInAs(user!.email!)
                      : l10n.guestUser,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: tokens.inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (user != null)
            IconButton(
              tooltip: l10n.signOut,
              icon: Icon(Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error),
              onPressed: () => ref.read(authStateProvider.notifier).signOut(),
            )
          else
            TextButton(
              onPressed: () => context.push('/auth'),
              child: Text(l10n.login),
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String title;
  const _GroupLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.iconColor,
    this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 4),
          leading: Icon(icon, color: iconColor ?? tokens.inkMuted, size: 22),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: subtitle != null
              ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: AppSpace.xs),
              ],
              trailingWidget ??
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: tokens.inkMuted,
                    size: 20,
                  ),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
              height: 1,
              indent: AppSpace.md,
              endIndent: AppSpace.md,
              color: tokens.hairline),
      ],
    );
  }
}

class _ManageLandsContent extends ConsumerStatefulWidget {
  const _ManageLandsContent();

  @override
  ConsumerState<_ManageLandsContent> createState() =>
      _ManageLandsContentState();
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
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final landsAsync = ref.watch(landsProvider);

    return Container(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
        start: AppSpace.lg,
        end: AppSpace.lg,
        top: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: tokens.hairline,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(l10n.manageLands,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.landName,
                prefixIcon: const Icon(Icons.landscape_outlined, size: 20),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [NormalizedDecimalFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.area,
                      suffixText: l10n.acresUnit,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                FilledButton(
                  onPressed: _add,
                  child: Text(l10n.addLand),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Divider(height: 1, color: tokens.hairline),
            const SizedBox(height: AppSpace.sm),
            landsAsync.when(
              data: (lands) {
                if (lands.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: Text(
                      l10n.noFarmLand,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < lands.length; i++) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.landscape_outlined,
                            color: tokens.inkMuted),
                        title: Text(lands[i].name,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text(
                          '${lands[i].area} ${l10n.acresUnit}',
                          style: AppTheme.tabular(
                              Theme.of(context).textTheme.bodySmall),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.deleteLand),
                                content: Text(l10n.confirmDeleteLand),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel)),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l10n.delete,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref
                                  .read(landsNotifierProvider.notifier)
                                  .deleteLand(lands[i].id);
                            }
                          },
                        ),
                      ),
                      if (i < lands.length - 1)
                        Divider(height: 1, color: tokens.hairline),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(l10n.errorGeneral(err.toString())),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final area = double.tryParse(_areaController.text) ?? 0;
    if (name.isNotEmpty && area > 0) {
      try {
        await ref
            .read(landsNotifierProvider.notifier)
            .addLand(name: name, area: area);
        if (!mounted) return;
        _nameController.clear();
        _areaController.clear();
        FocusScope.of(context).unfocus();
      } catch (e) {
        if (mounted) {
          AppNotification.show(context, l10n.saveFailed(e.toString()),
              isError: true);
        }
      }
    } else {
      AppNotification.show(context, l10n.invalidLandDetails, isError: true);
    }
  }
}
