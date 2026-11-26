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

/// Tactile selector trigger replacing stock Material DropdownButton widgets.
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: tokens.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
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
                        fontSize: compact ? 13 : 15,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  flex: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.well,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      badge!,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tabular(
                        Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(width: compact ? 4 : AppSpace.xs),
              Icon(
                Icons.unfold_more_rounded,
                size: compact ? 16 : 18,
                color: tokens.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a clean, tactile bottom-sheet selector with 56dp+ hit targets.
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
              AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
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
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  if (headerAction != null) headerAction,
                ],
              ),
              const SizedBox(height: AppSpace.sm),
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
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(sheetCtx, opt.value);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: 14,
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
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.subtitle!,
                                        style: AppTheme.tabular(
                                            Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (opt.badge != null) ...[
                                const SizedBox(width: AppSpace.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tokens.well,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    opt.badge!,
                                    style: AppTheme.tabular(
                                        Theme.of(context).textTheme.bodySmall),
                                  ),
                                ),
                              ],
                              const SizedBox(width: AppSpace.xs),
                              SizedBox(
                                width: 24,
                                child: isSelected
                                    ? Icon(Icons.check_rounded,
                                        color: primary, size: 20)
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
