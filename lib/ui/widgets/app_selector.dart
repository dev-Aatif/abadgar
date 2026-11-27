import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Option model for [showAppSelectorSheet].
class AppSelectorOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final String? badge;

  const AppSelectorOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.badge,
  });
}

/// Compact tactile selector trigger replacing bulky Material dropdowns.
class AppSelectorTrigger extends StatelessWidget {
  final String label;
  final String? badge;
  final Widget? leading;
  final VoidCallback onTap;
  final bool compact;

  const AppSelectorTrigger({
    super.key,
    required this.label,
    required this.onTap,
    this.badge,
    this.leading,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: tokens.hairlineStrong, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 40 : 44),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 6 : 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: compact ? 6 : AppSpace.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: compact ? 13 : 14,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.well,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: tokens.hairline, width: 1),
                      ),
                      child: Text(
                        badge!,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.tabular(
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: tokens.inkMuted,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: compact ? 15 : 16,
                  color: tokens.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a tactile bottom-sheet selector with crisp hairline rows.
Future<T?> showAppSelectorSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppSelectorOption<T>> options,
  T? selectedValue,
  Widget? headerAction,
}) {
  final tokens = context.tokens;

  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.xs,
            AppSpace.md,
            AppSpace.md,
          ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (headerAction != null) headerAction,
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Divider(height: 1, color: tokens.hairline),
              const SizedBox(height: AppSpace.xs),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: tokens.hairline),
                  itemBuilder: (_, index) {
                    final opt = options[index];
                    final isSelected = opt.value == selectedValue;
                    final primary = Theme.of(context).colorScheme.primary;

                    return Material(
                      color: isSelected
                          ? primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(sheetCtx, opt.value);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              if (opt.leading != null) ...[
                                opt.leading!,
                                const SizedBox(width: AppSpace.sm),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? primary
                                                : tokens.ink,
                                          ),
                                    ),
                                    if (opt.subtitle != null) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        opt.subtitle!,
                                        style: AppTheme.tabular(
                                          Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (opt.badge != null) ...[
                                const SizedBox(width: AppSpace.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.well,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.xs),
                                    border: Border.all(color: tokens.hairline),
                                  ),
                                  child: Text(
                                    opt.badge!,
                                    style: AppTheme.tabular(
                                      Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: AppSpace.xs),
                              SizedBox(
                                width: 20,
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: primary,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
