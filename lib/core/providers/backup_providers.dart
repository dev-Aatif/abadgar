import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_provider.dart';
import '../services/autosave_service.dart';
import '../services/export_service.dart';

part 'backup_providers.g.dart';

class BackupStatus {
  final bool autoBackupEnabled;
  final DateTime? lastAutoBackupAt;
  final DateTime? lastExternalBackupAt;

  const BackupStatus({
    required this.autoBackupEnabled,
    required this.lastAutoBackupAt,
    required this.lastExternalBackupAt,
  });

  bool get isExternalBackupOverdue {
    if (lastExternalBackupAt == null) return true;
    return DateTime.now().difference(lastExternalBackupAt!).inDays >= 14;
  }
}

@riverpod
class BackupStatusNotifier extends _$BackupStatusNotifier {
  @override
  Future<BackupStatus> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AutoSaveService.autoBackupEnabledKey) ?? true;
    final lastAutoRaw = prefs.getString(AutoSaveService.lastAutoBackupKey);
    final lastExtRaw = prefs.getString(ExportService.lastExternalBackupKey);
    return BackupStatus(
      autoBackupEnabled: enabled,
      lastAutoBackupAt:
          lastAutoRaw != null ? DateTime.tryParse(lastAutoRaw) : null,
      lastExternalBackupAt:
          lastExtRaw != null ? DateTime.tryParse(lastExtRaw) : null,
    );
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AutoSaveService.autoBackupEnabledKey, enabled);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

@Riverpod(keepAlive: true)
class AutoSaveController extends _$AutoSaveController {
  StreamSubscription<dynamic>? _changeSub;
  Timer? _debounce;
  bool _disposed = false;

  @override
  void build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      _changeSub?.cancel();
    });

    unawaited(_attachDatabaseWatcher());
  }

  Future<void> _attachDatabaseWatcher() async {
    final db = await ref.read(localDatabaseProvider.future);
    if (_disposed) return;

    _changeSub = db.onChange(
      const {'seasons', 'transactions', 'yield_logs', 'lands'},
      triggerImmediately: false,
    ).listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 3), () {
        unawaited(triggerNow());
      });
    });
  }

  Future<void> triggerNow({bool force = false}) async {
    if (_disposed) return;
    final db = await ref.read(localDatabaseProvider.future);
    if (_disposed) return;
    final wrote = await AutoSaveService(db).triggerBackup(force: force);
    if (wrote && !_disposed) {
      ref.read(backupStatusNotifierProvider.notifier).refresh();
    }
  }
}
