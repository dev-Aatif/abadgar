import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';

/// Option item for [AppSegmentedControl].
class AppSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? activeColor;

  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.activeColor,
  });
}

/// Compact, tactile segmented pill-track control (36dp visual height, 44dp+ hit area).
class AppSegmentedControl<T> extends StatelessWidget {
  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool compact;

  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final minHeight = compact ? 40.0 : 44.0;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: tokens.well,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: tokens.hairline, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final seg in segments)
                  Expanded(
                    child: _SegmentTile<T>(
                      segment: seg,
                      isSelected: seg.value == selected,
                      primary: seg.activeColor ?? primary,
                      enabled: enabled,
                      compact: compact,
                      onTap: () {
                        if (!enabled || seg.value == selected) return;
                        HapticFeedback.selectionClick();
                        onChanged(seg.value);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentTile<T> extends StatelessWidget {
  final AppSegment<T> segment;
  final bool isSelected;
  final Color primary;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const _SegmentTile({
    required this.segment,
    required this.isSelected,
    required this.primary,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = isSelected ? primary : tokens.inkMuted;

    return Semantics(
      selected: isSelected,
      button: true,
      enabled: enabled,
      child: Material(
        color: isSelected ? tokens.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          side: isSelected
              ? BorderSide(color: tokens.hairlineStrong, width: 1)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: compact ? 13 : 14, color: fg),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected ? tokens.ink : tokens.inkMuted,
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact 1-tap hairline filter pill with optional color dot.
class AppFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;
  final String? countBadge;

  const AppFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.countBadge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = dotColor ?? primary;

    return Material(
      color: selected ? accent.withValues(alpha: 0.11) : tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        side: BorderSide(
          color: selected ? accent.withValues(alpha: 0.5) : tokens.hairline,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? tokens.ink : tokens.inkMuted,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
                if (countBadge != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    countBadge!,
                    style: AppTheme.tabular(
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: selected ? accent : tokens.inkMuted,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand logo badge rendering the generated Swiss-grid Abadgar mark.
class AbadgarLogoBadge extends StatelessWidget {
  final double size;
  final double radius;

  const AbadgarLogoBadge({
    super.key,
    this.size = 32,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF17191C),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokens.hairlineStrong, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _FallbackMarkPainter(
            furrowColor: const Color(0xFFEDF0F4),
            spireColor: AppColors.amberDark,
          ),
        ),
      ),
    );
  }
}

class _FallbackMarkPainter extends CustomPainter {
  final Color furrowColor;
  final Color spireColor;

  _FallbackMarkPainter({
    required this.furrowColor,
    required this.spireColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = furrowColor;
    for (int i = 0; i < 3; i++) {
      final offset = i * w * 0.14;
      final path = Path()
        ..moveTo(w * 0.18 + offset, h * 0.80)
        ..lineTo(w * 0.44 + offset, h * 0.54)
        ..lineTo(w * 0.52 + offset, h * 0.54)
        ..lineTo(w * 0.26 + offset, h * 0.80)
        ..close();
      canvas.drawPath(path, paint);
    }

    paint.color = spireColor;
    final spire = Path()
      ..moveTo(w * 0.50, h * 0.16)
      ..lineTo(w * 0.58, h * 0.30)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.42, h * 0.30)
      ..close();
    canvas.drawPath(spire, paint);
  }

  @override
  bool shouldRepaint(covariant _FallbackMarkPainter oldDelegate) => false;
}

/// Crisp geometric crop glyph tuned to the Console aesthetic.
class CropGlyph extends StatelessWidget {
  final CropType cropType;
  final double size;

  const CropGlyph({
    super.key,
    required this.cropType,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final color = cropType == CropType.wheat
        ? AppColors.wheatFor(context)
        : AppColors.riceFor(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CropGlyphPainter(cropType: cropType, color: color),
      ),
    );
  }
}

class _CropGlyphPainter extends CustomPainter {
  final CropType cropType;
  final Color color;

  _CropGlyphPainter({required this.cropType, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.11).clamp(1.3, 2.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    if (cropType == CropType.wheat) {
      // Minimal architectural grain stem + 2 pairs of angled chevrons
      canvas.drawLine(
        Offset(cx, size.height * 0.88),
        Offset(cx, size.height * 0.16),
        paint,
      );
      canvas.drawLine(
        Offset(cx, size.height * 0.42),
        Offset(size.width * 0.24, size.height * 0.24),
        paint,
      );
      canvas.drawLine(
        Offset(cx, size.height * 0.42),
        Offset(size.width * 0.76, size.height * 0.24),
        paint,
      );
      canvas.drawLine(
        Offset(cx, size.height * 0.68),
        Offset(size.width * 0.24, size.height * 0.50),
        paint,
      );
      canvas.drawLine(
        Offset(cx, size.height * 0.68),
        Offset(size.width * 0.76, size.height * 0.50),
        paint,
      );
    } else {
      // Minimal river-rice droplet / curved panicle
      final drop = Path()
        ..moveTo(cx, size.height * 0.14)
        ..cubicTo(
          size.width * 0.82,
          size.height * 0.48,
          size.width * 0.82,
          size.height * 0.86,
          cx,
          size.height * 0.86,
        )
        ..cubicTo(
          size.width * 0.18,
          size.height * 0.86,
          size.width * 0.18,
          size.height * 0.48,
          cx,
          size.height * 0.14,
        );
      canvas.drawPath(drop, paint);
      canvas.drawLine(
        Offset(cx, size.height * 0.45),
        Offset(cx, size.height * 0.74),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropGlyphPainter oldDelegate) =>
      oldDelegate.cropType != cropType || oldDelegate.color != color;
}

/// Precision dual-ratio bar comparing revenue vs expenses on a single hairline rule.
class PrecisionRatioBar extends StatelessWidget {
  final double revenue;
  final double expenses;

  const PrecisionRatioBar({
    super.key,
    required this.revenue,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final total = revenue + expenses;
    final revRatio = total > 0 ? (revenue / total).clamp(0.0, 1.0) : 0.0;
    final expRatio = total > 0 ? (expenses / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: ColoredBox(
          color: tokens.well,
          child: total <= 0
              ? const SizedBox.expand()
              : Row(
                  children: [
                    if (revRatio > 0)
                      Expanded(
                        flex: (revRatio * 1000).round().clamp(1, 1000),
                        child: ColoredBox(
                          color: AppColors.revenueFor(context),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    if (revRatio > 0 && expRatio > 0)
                      SizedBox(
                        width: 2,
                        child: ColoredBox(color: tokens.canvas),
                      ),
                    if (expRatio > 0)
                      Expanded(
                        flex: (expRatio * 1000).round().clamp(1, 1000),
                        child: ColoredBox(
                          color: AppColors.expenseFor(context),
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Compact tactile stepper control for granular numeric increments (e.g. acres).
class CompactStepperCluster extends StatelessWidget {
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String stepLabel;

  const CompactStepperCluster({
    super.key,
    required this.onDecrement,
    required this.onIncrement,
    this.stepLabel = '0.5',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.well,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: tokens.hairline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
              ),
              VerticalDivider(width: 1, color: tokens.hairline),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  stepLabel,
                  style: AppTheme.tabular(
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, color: tokens.hairline),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(icon, size: 16, color: tokens.ink),
        ),
      ),
    );
  }
}
