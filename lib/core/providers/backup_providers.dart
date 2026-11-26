import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_provider.dart';
import '../services/autosave_service.dart';
import '../services/export_service.dart';
import '../utils/logger.dart';

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
  Future<void>? _inFlight;
  bool _hasPendingChanges = false;
  bool _disposed = false;

  @override
  void build() {
    _disposed = false;
    _hasPendingChanges = false;
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      _changeSub?.cancel();
    });

    unawaited(_attachDatabaseWatcher());
  }

  Future<void> _attachDatabaseWatcher() async {
    try {
      final db = await ref.read(localDatabaseProvider.future);
      if (_disposed) return;

      _changeSub = db.onChange(
        const {'seasons', 'transactions', 'yield_logs', 'lands'},
        triggerImmediately: false,
      ).listen((_) {
        _hasPendingChanges = true;
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 3), () {
          unawaited(triggerNow());
        });
      });
    } catch (e, st) {
      appLogger.e('Failed to attach autosave watcher',
          error: e, stackTrace: st);
    }
  }

  Future<void> triggerNow({bool force = false}) {
    if (_disposed) return Future.value();
    if (!force && !_hasPendingChanges) return Future.value();

    _debounce?.cancel();
    _debounce = null;

    if (_inFlight != null) {
      return _inFlight!;
    }

    final task = _runBackup(force: force);
    _inFlight = task.whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  Future<void> _runBackup({required bool force}) async {
    if (_disposed) return;
    _hasPendingChanges = false;
    try {
      final db = await ref.read(localDatabaseProvider.future);
      if (_disposed) return;
      final wrote = await AutoSaveService(db).triggerBackup(force: force);
      if (wrote && !_disposed) {
        ref.read(backupStatusNotifierProvider.notifier).refresh();
      }
    } catch (e, st) {
      _hasPendingChanges = true;
      appLogger.w('Autosave trigger failed', error: e, stackTrace: st);
    }
  }
}
