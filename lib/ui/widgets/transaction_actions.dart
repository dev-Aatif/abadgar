import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../core/models/transaction.dart';
import '../../core/models/yield_log.dart';
import '../../core/providers/transaction_repository_provider.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/notifications.dart';
import 'transaction_form/transaction_bottom_sheet.dart';

/// Opens the unified entry sheet for creating or editing a transaction or harvest.
Future<void> showTransactionSheet(
  BuildContext context, {
  Transaction? transaction,
  YieldLog? yieldLog,
  TransactionMode? initialMode,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TransactionBottomSheet(
      transaction: transaction,
      yieldLog: yieldLog,
      initialMode: initialMode,
    ),
  );
}

/// Prompts for confirmation before deleting a record via swipe.
Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.delete,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Immediately deletes a transaction and offers a 5-second Undo snackbar.
Future<void> deleteTransactionWithUndo(
  BuildContext context,
  WidgetRef ref,
  Transaction tx,
) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = ref.read(transactionRepositoryProvider);
  final linkedYieldId = await repo.deleteTransaction(tx.id);
  if (!context.mounted) return;

  AppNotification.showUndo(
    context,
    message: l10n.transactionDeleted,
    undoLabel: l10n.undo,
    onUndo: () {
      unawaited(
        repo
            .restoreTransaction(
                transaction: tx, linkedYieldLogId: linkedYieldId)
            .catchError((Object e, StackTrace st) {
          appLogger.e('Failed to undo transaction delete',
              error: e, stackTrace: st);
        }),
      );
    },
  );
}

/// Immediately deletes a harvest log and offers a 5-second Undo snackbar.
Future<void> deleteYieldLogWithUndo(
  BuildContext context,
  WidgetRef ref,
  YieldLog log,
) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = ref.read(transactionRepositoryProvider);
  final linkedTx = await repo.deleteYieldLog(log.id);
  if (!context.mounted) return;

  AppNotification.showUndo(
    context,
    message: l10n.harvestDeleted,
    undoLabel: l10n.undo,
    onUndo: () {
      unawaited(
        repo
            .restoreYieldLog(log: log, linkedTransaction: linkedTx)
            .catchError((Object e, StackTrace st) {
          appLogger.e('Failed to undo harvest delete',
              error: e, stackTrace: st);
        }),
      );
    },
  );
}
