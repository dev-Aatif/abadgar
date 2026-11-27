import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/enums.dart';
import '../../core/models/transaction.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_helpers.dart';

/// Single-containment hairline panel used across all screens.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = color ?? tokens.surface;
    final border = borderColor ?? tokens.hairline;

    final body =
        padding != null ? Padding(padding: padding!, child: child) : child;

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      );
    }

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: body),
    );
  }
}

/// Sentence-case section heading with an optional trailing action.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Compact, hairline-aligned transaction row shared across Dashboard and Ledger.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool> Function()? confirmDelete;
  final bool showDivider;
  final double horizontalPadding;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currencyFormat,
    required this.onTap,
    required this.onDelete,
    this.confirmDelete,
    this.showDivider = false,
    this.horizontalPadding = AppSpace.md,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isRevenue = transaction.type == TransactionType.revenue ||
        transaction.type == TransactionType.yield_;
    final amountColor = isRevenue
        ? AppColors.revenueFor(context)
        : AppColors.expenseFor(context);
    final categoryName =
        L10nHelpers.categoryLabel(context, transaction.category);
    final categoryColor =
        AppColors.forCategory(transaction.category ?? 'Other');
    final dateText = DateFormat('d MMM', L10nHelpers.intlLocaleFor(context))
        .format(transaction.date);
    final note = transaction.notes?.trim();

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpace.lg),
        color: AppColors.expenseFor(context),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFDFCF9),
          size: 20,
        ),
      ),
      confirmDismiss: confirmDelete != null ? (_) => confirmDelete!() : null,
      onDismissed: (_) => onDelete(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: AppSpace.compact),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          note != null && note.isNotEmpty
                              ? '$dateText · $note'
                              : dateText,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    '${isRevenue ? '+' : '−'}${currencyFormat.format(transaction.amount)}',
                    style: AppTheme.tabular(
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              indent: horizontalPadding,
              endIndent: horizontalPadding,
              color: tokens.hairline,
            ),
        ],
      ),
    );
  }
}

/// Calm, hairline-framed empty state with a single clear action.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tokens.well,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: tokens.hairline, width: 1),
              ),
              child: Icon(icon, size: 24, color: tokens.inkMuted),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.xxs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.md),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
