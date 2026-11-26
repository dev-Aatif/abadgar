import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/backup_providers.dart';
import '../../../core/providers/lands_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/autosave_service.dart';
import '../../../core/services/backup_crypto.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/github_updater.dart';
import '../../../core/services/import_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/l10n_helpers.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/notifications.dart';
import '../../widgets/app_controls.dart';
import '../../widgets/app_surface.dart';
import '../../widgets/transaction_form/parts/form_shared.dart';

enum _ExportAction { share, save }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackupBusy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final themeMode =
        ref.watch(themeModeNotifierProvider).value ?? ThemeMode.system;
    final locale =
        ref.watch(localeNotifierProvider).value ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.md,
          48,
        ),
        children: [
          _BackupOverviewCard(
            onOpenGuide: () => _showBackupGuideSheet(context),
          ),
          const SizedBox(height: AppSpace.lg),

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
          const SizedBox(height: AppSpace.md),

          // Appearance: instant 1-tap inline granular switches
          _GroupLabel(title: l10n.appearance),
          AppCard(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.brightness_6_outlined,
                      size: 18,
                      color: tokens.inkMuted,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      l10n.themeMode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                AppSegmentedControl<ThemeMode>(
                  compact: true,
                  selected: themeMode,
                  segments: [
                    AppSegment(
                      value: ThemeMode.system,
                      label: l10n.themeSystem,
                    ),
                    AppSegment(
                      value: ThemeMode.light,
                      label: l10n.themeLight,
                    ),
                    AppSegment(
                      value: ThemeMode.dark,
                      label: l10n.themeDark,
                    ),
                  ],
                  onChanged: (mode) => ref
                      .read(themeModeNotifierProvider.notifier)
                      .setThemeMode(mode),
                ),
                const SizedBox(height: AppSpace.sm),
                Divider(height: 1, color: tokens.hairline),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 18,
                      color: tokens.inkMuted,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      l10n.language,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                AppSegmentedControl<String>(
                  compact: true,
                  selected: locale.languageCode,
                  segments: const [
                    AppSegment(value: 'en', label: 'English'),
                    AppSegment(value: 'ur', label: 'اردو'),
                    AppSegment(value: 'sd', label: 'سنڌي'),
                  ],
                  onChanged: (code) => ref
                      .read(localeNotifierProvider.notifier)
                      .setLocale(Locale(code)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Data Management (Local-First Backups)
          _GroupLabel(title: l10n.dataManagement),
          if (_isBackupBusy)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.xs),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          _DataManagementCard(
            onEncryptedExport: _isBackupBusy
                ? null
                : () => _handleEncryptedExport(context, ref),
            onPlainExport:
                _isBackupBusy ? null : () => _handlePlainExport(context, ref),
            onImport: _isBackupBusy ? null : () => _handleImport(context, ref),
            onRestoreAutoBackup: _isBackupBusy
                ? null
                : () => _showAutoBackupsSheet(context, ref),
            onOpenGuide: () => _showBackupGuideSheet(context),
          ),
          const SizedBox(height: AppSpace.md),

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
                        AppNotification.show(
                          context,
                          l10n.updateCheckFailed,
                          isError: true,
                        );
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

  Future<void> _handleEncryptedExport(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await _askExportAction(context, l10n.backupEncryptedExport);
    if (action == null || !context.mounted) return;

    final passphrase = await _askSetPassphrase(context);
    if (passphrase == null || !context.mounted) return;

    setState(() => _isBackupBusy = true);
    try {
      final db = await ref.read(localDatabaseProvider.future);
      final service = ExportService(db);
      if (action == _ExportAction.share) {
        await service.exportDatabase(passphrase: passphrase);
      } else {
        final saved = await service.downloadDatabase(passphrase: passphrase);
        if (saved && context.mounted) {
          AppNotification.show(context, l10n.backupSavedToDevice);
        }
      }
      ref.read(backupStatusNotifierProvider.notifier).refresh();
    } catch (e, st) {
      appLogger.e('Encrypted export failed', error: e, stackTrace: st);
      if (context.mounted) {
        AppNotification.show(
          context,
          l10n.errorGeneral(l10n.exportData),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  Future<void> _handlePlainExport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await _askExportAction(
      context,
      l10n.backupPlainExport,
      warningText: l10n.backupPlainWarning,
    );
    if (action == null || !context.mounted) return;

    setState(() => _isBackupBusy = true);
    try {
      final db = await ref.read(localDatabaseProvider.future);
      final service = ExportService(db);
      if (action == _ExportAction.share) {
        await service.exportDatabase();
      } else {
        final saved = await service.downloadDatabase();
        if (saved && context.mounted) {
          AppNotification.show(context, l10n.backupSavedToDevice);
        }
      }
      ref.read(backupStatusNotifierProvider.notifier).refresh();
    } catch (e, st) {
      appLogger.e('Plain export failed', error: e, stackTrace: st);
      if (context.mounted) {
        AppNotification.show(
          context,
          l10n.errorGeneral(l10n.exportData),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBackupBusy = true);
    try {
      final db = await ref.read(localDatabaseProvider.future);
      final success = await ImportService(db).importDatabase(
        onPassphraseRequired: () => _askEnterPassphrase(context),
        onConfirmRestore: () => _confirmRestore(context),
      );
      if (success) {
        ref.invalidate(activeSeasonIdProvider);
        ref.read(backupStatusNotifierProvider.notifier).refresh();
        if (context.mounted) {
          AppNotification.show(context, l10n.importSuccessful);
        }
      }
    } on BackupDecryptionException catch (e) {
      appLogger.w('Backup decryption failed: ${e.message}');
      if (context.mounted) {
        AppNotification.show(
          context,
          l10n.backupWrongPassphrase,
          isError: true,
        );
      }
    } catch (e, st) {
      appLogger.e('Import backup failed', error: e, stackTrace: st);
      if (context.mounted) {
        AppNotification.show(
          context,
          l10n.errorGeneral(l10n.importData),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  Future<_ExportAction?> _askExportAction(
    BuildContext context,
    String title, {
    String? warningText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<_ExportAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: warningText != null ? Text(warningText) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, _ExportAction.save),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l10n.backupSaveAction),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, _ExportAction.share),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(l10n.backupShareAction),
          ),
        ],
      ),
    );
  }

  Future<String?> _askSetPassphrase(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _SetPassphraseDialog(),
    );
  }

  Future<String?> _askEnterPassphrase(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _EnterPassphraseDialog(),
    );
  }

  Future<bool> _confirmRestore(BuildContext context) async {
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreBackup),
        content: Text(l10n.restoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showAutoBackupsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AutoBackupsSheet(),
    );
  }

  void _showBackupGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BackupGuideSheet(),
    );
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo update) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          update.isUpdateAvailable ? l10n.updateAvailable : l10n.upToDate,
        ),
        content: Text(
          update.isUpdateAvailable
              ? '${l10n.latestVersion(update.latestVersion)}\n\n${update.releaseNotes}'
              : l10n.upToDateContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          if (update.isUpdateAvailable &&
              GithubUpdater.isTrustedDownloadUrl(update.downloadUrl))
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(update.downloadUrl);
                final launched = await canLaunchUrl(uri) &&
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!launched && context.mounted) {
                  AppNotification.show(
                    context,
                    l10n.updateCheckFailed,
                    isError: true,
                  );
                }
              },
              child: Text(l10n.download),
            ),
        ],
      ),
    );
  }
}

class _BackupOverviewCard extends ConsumerWidget {
  final VoidCallback onOpenGuide;

  const _BackupOverviewCard({required this.onOpenGuide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final status = ref.watch(backupStatusNotifierProvider).valueOrNull;
    final intlLocale = L10nHelpers.intlLocaleFor(context);
    final extText = status?.lastExternalBackupAt != null
        ? l10n.lastExternalBackupAt(
            DateFormat.yMMMd(intlLocale).format(status!.lastExternalBackupAt!),
          )
        : l10n.lastExternalBackupNever;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Row(
        children: [
          const AbadgarLogoBadge(size: 40, radius: AppRadius.sm),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.syncLocalOnly,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 1),
                Text(
                  extText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: tokens.inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.backupGuideTitle,
            onPressed: onOpenGuide,
            icon: Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataManagementCard extends ConsumerWidget {
  final VoidCallback? onEncryptedExport;
  final VoidCallback? onPlainExport;
  final VoidCallback? onImport;
  final VoidCallback? onRestoreAutoBackup;
  final VoidCallback onOpenGuide;

  const _DataManagementCard({
    required this.onEncryptedExport,
    required this.onPlainExport,
    required this.onImport,
    required this.onRestoreAutoBackup,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final status = ref.watch(backupStatusNotifierProvider).valueOrNull;
    final autoEnabled = status?.autoBackupEnabled ?? true;
    final intlLocale = L10nHelpers.intlLocaleFor(context);
    final autoSubtitle = status?.lastAutoBackupAt != null
        ? l10n.lastAutoBackupAt(
            DateFormat.yMMMd(intlLocale)
                .add_jm()
                .format(status!.lastAutoBackupAt!),
          )
        : l10n.lastAutoBackupNever;

    return AppCard(
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.enhanced_encryption_outlined,
            title: l10n.backupEncryptedExport,
            subtitle: l10n.backupEncryptedSubtitle,
            iconColor: Theme.of(context).colorScheme.primary,
            showDivider: true,
            onTap: onEncryptedExport,
          ),
          _SettingsRow(
            icon: Icons.data_object_rounded,
            title: l10n.backupPlainExport,
            subtitle: l10n.backupPlainSubtitle,
            showDivider: true,
            onTap: onPlainExport,
          ),
          _SettingsRow(
            icon: Icons.restore_rounded,
            title: l10n.importData,
            subtitle: l10n.restoreBackup,
            showDivider: true,
            onTap: onImport,
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: 2),
            secondary: Icon(
              Icons.autorenew_rounded,
              color: tokens.inkMuted,
              size: 22,
            ),
            title: Text(
              l10n.autoBackups,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              autoSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: autoEnabled,
            onChanged: (val) => ref
                .read(backupStatusNotifierProvider.notifier)
                .setAutoBackupEnabled(val),
          ),
          Divider(
            height: 1,
            indent: AppSpace.md,
            endIndent: AppSpace.md,
            color: tokens.hairline,
          ),
          _SettingsRow(
            icon: Icons.history_rounded,
            title: l10n.restoreAutoBackup,
            subtitle: l10n.autoBackupsSubtitle,
            showDivider: true,
            onTap: onRestoreAutoBackup,
          ),
          _SettingsRow(
            icon: Icons.shield_outlined,
            title: l10n.backupGuideTitle,
            subtitle: l10n.backupGuideSubtitle,
            onTap: onOpenGuide,
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
      padding: const EdgeInsets.only(bottom: 6),
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
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: 11,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? tokens.inkMuted, size: 20),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null) ...[
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    trailingText!,
                    style: AppTheme.tabular(
                      Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpace.xs),
                trailingWidget ??
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: tokens.inkMuted,
                      size: 18,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpace.md,
            endIndent: AppSpace.md,
            color: tokens.hairline,
          ),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
        start: AppSpace.md,
        end: AppSpace.md,
        top: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: tokens.hairline, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3.5,
                decoration: BoxDecoration(
                  color: tokens.hairlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.manageLands,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.landName,
                prefixIcon: const Icon(Icons.landscape_outlined, size: 18),
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
            const SizedBox(height: AppSpace.md),
            Divider(height: 1, color: tokens.hairline),
            const SizedBox(height: AppSpace.xs),
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
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.landscape_outlined,
                          size: 18,
                          color: tokens.inkMuted,
                        ),
                        title: Text(
                          lands[i].name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${lands[i].area} ${l10n.acresUnit}',
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.deleteLand),
                                content: Text(l10n.confirmDeleteLand),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      l10n.delete,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
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
          AppNotification.show(
            context,
            l10n.saveFailed(e.toString()),
            isError: true,
          );
        }
      }
    } else {
      AppNotification.show(context, l10n.invalidLandDetails, isError: true);
    }
  }
}

class _SetPassphraseDialog extends StatefulWidget {
  const _SetPassphraseDialog();

  @override
  State<_SetPassphraseDialog> createState() => _SetPassphraseDialogState();
}

class _SetPassphraseDialogState extends State<_SetPassphraseDialog> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.backupPassphraseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _passController,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.backupPassphraseHint,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l10n.backupPassphraseConfirmHint,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final p1 = _passController.text;
            final p2 = _confirmController.text;
            if (p1.length < 6) {
              setState(() => _error = l10n.backupPassphraseShort);
              return;
            }
            if (p1 != p2) {
              setState(() => _error = l10n.backupPassphraseMismatch);
              return;
            }
            Navigator.pop(context, p1);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _EnterPassphraseDialog extends StatefulWidget {
  const _EnterPassphraseDialog();

  @override
  State<_EnterPassphraseDialog> createState() => _EnterPassphraseDialogState();
}

class _EnterPassphraseDialogState extends State<_EnterPassphraseDialog> {
  final _passController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.backupEnterPassphraseTitle),
      content: TextField(
        controller: _passController,
        obscureText: _obscure,
        autofocus: true,
        onSubmitted: (_) {
          if (_passController.text.isNotEmpty) {
            Navigator.pop(context, _passController.text);
          }
        },
        decoration: InputDecoration(
          labelText: l10n.password,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_passController.text.isNotEmpty) {
              Navigator.pop(context, _passController.text);
            }
          },
          child: Text(l10n.restore),
        ),
      ],
    );
  }
}

class _AutoBackupsSheet extends ConsumerStatefulWidget {
  const _AutoBackupsSheet();

  @override
  ConsumerState<_AutoBackupsSheet> createState() => _AutoBackupsSheetState();
}

class _AutoBackupsSheetState extends ConsumerState<_AutoBackupsSheet> {
  late Future<List<AutoBackupEntry>> _future;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AutoBackupEntry>> _load() async {
    final db = await ref.read(localDatabaseProvider.future);
    return AutoSaveService(db).listBackups();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final intlLocale = L10nHelpers.intlLocaleFor(context);

    return Container(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpace.xl,
        start: AppSpace.lg,
        end: AppSpace.lg,
        top: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            l10n.restoreAutoBackup,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.restoreConfirmBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.md),
          FutureBuilder<List<AutoBackupEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                  child: Text(
                    l10n.noAutoBackupFound,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: tokens.hairline),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    final when = DateFormat.yMMMd(intlLocale)
                        .add_jm()
                        .format(entry.createdAt);
                    final stats = l10n.autoBackupSnapshotLine(
                      entry.seasonCount,
                      entry.transactionCount,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          Icon(Icons.history_rounded, color: tokens.inkMuted),
                      title: Text(
                        when,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        stats,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: OutlinedButton(
                        onPressed: _isRestoring
                            ? null
                            : () => _confirmAndRestore(entry),
                        child: Text(l10n.restore),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRestore(AutoBackupEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreAutoBackup),
        content: Text(l10n.restoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final db = await ref.read(localDatabaseProvider.future);
      await AutoSaveService(db).restoreBackup(entry.file);
      ref.invalidate(activeSeasonIdProvider);
      if (mounted) {
        Navigator.pop(context);
        AppNotification.show(
          context,
          l10n.autoBackupRestored,
        );
      }
    } catch (e, st) {
      appLogger.e(
        'Auto-backup restore failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() => _isRestoring = false);
        AppNotification.show(
          context,
          l10n.errorGeneral(l10n.restoreAutoBackup),
          isError: true,
        );
      }
    }
  }
}

class _BackupGuideSheet extends StatelessWidget {
  const _BackupGuideSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;

    final steps = [
      (
        icon: Icons.phone_android_rounded,
        title: l10n.backupGuideStep1Title,
        body: l10n.backupGuideStep1Body,
      ),
      (
        icon: Icons.enhanced_encryption_outlined,
        title: l10n.backupGuideStep2Title,
        body: l10n.backupGuideStep2Body,
      ),
      (
        icon: Icons.menu_book_rounded,
        title: l10n.backupGuideStep3Title,
        body: l10n.backupGuideStep3Body,
      ),
      (
        icon: Icons.restore_rounded,
        title: l10n.backupGuideStep4Title,
        body: l10n.backupGuideStep4Body,
      ),
    ];

    return Container(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpace.xl,
        start: AppSpace.lg,
        end: AppSpace.lg,
        top: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    l10n.backupGuideTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            for (final step in steps) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(step.icon, size: 20, color: tokens.inkMuted),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.body,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
