import 'package:flutter/material.dart';

/// Granular spacing scale (4pt base with micro & compact nudges).
class AppSpace {
  AppSpace._();
  static const double micro = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double compact = 10;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Crisp, architectural corner radii per containment level.
class AppRadius {
  AppRadius._();
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double sheet = 20;
}

/// Motion discipline: brisk, silent, state-driven transitions.
class AppMotion {
  AppMotion._();
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 180);
  static const Curve curve = Curves.easeOutCubic;
}

/// Tonal surface, hairline, and ink tokens exposed via ThemeExtension.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color canvas;
  final Color surface;
  final Color well;
  final Color surfaceDeep;
  final Color hairline;
  final Color hairlineStrong;
  final Color ink;
  final Color inkMuted;
  final Color instrument;

  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.well,
    required this.surfaceDeep,
    required this.hairline,
    required this.hairlineStrong,
    required this.ink,
    required this.inkMuted,
    required this.instrument,
  });

  /// Console Paper: warm alabaster ground for comfortable daylight legibility.
  static const light = AppTokens(
    canvas: Color(0xFFF6F4EE),
    surface: Color(0xFFFDFCF9),
    well: Color(0xFFEDEAE1),
    surfaceDeep: Color(0xFFE4E0D5),
    hairline: Color(0xFFDEDAD0),
    hairlineStrong: Color(0xFFC9C3B5),
    ink: Color(0xFF1B1A17),
    inkMuted: Color(0xFF656158),
    instrument: Color(0xFF2F638D),
  );

  /// Console Graphite: matte slate-graphite stepped in three lightness levels.
  static const dark = AppTokens(
    canvas: Color(0xFF15171A),
    surface: Color(0xFF1C1F24),
    well: Color(0xFF101214),
    surfaceDeep: Color(0xFF252930),
    hairline: Color(0xFF2B3038),
    hairlineStrong: Color(0xFF3D4450),
    ink: Color(0xFFECEEF2),
    inkMuted: Color(0xFF949CA8),
    instrument: Color(0xFF6CA5D4),
  );

  @override
  AppTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? well,
    Color? surfaceDeep,
    Color? hairline,
    Color? hairlineStrong,
    Color? ink,
    Color? inkMuted,
    Color? instrument,
  }) {
    return AppTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      well: well ?? this.well,
      surfaceDeep: surfaceDeep ?? this.surfaceDeep,
      hairline: hairline ?? this.hairline,
      hairlineStrong: hairlineStrong ?? this.hairlineStrong,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      instrument: instrument ?? this.instrument,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      well: Color.lerp(well, other.well, t)!,
      surfaceDeep: Color.lerp(surfaceDeep, other.surfaceDeep, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      instrument: Color.lerp(instrument, other.instrument, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppTokens.dark
          : AppTokens.light);
}

class AppTheme {
  static const Color primaryAmber = Color(0xFFB45F16);
  static const Color primaryAmberDark = Color(0xFFE09846);

  static final ThemeData light = _base(Brightness.light);
  static final ThemeData dark = _base(Brightness.dark);

  /// Applies tabular numerals for aligned financial & weight figures.
  static TextStyle tabular(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tokens = isDark ? AppTokens.dark : AppTokens.light;
    final primary = isDark ? primaryAmberDark : primaryAmber;
    final onPrimary =
        isDark ? const Color(0xFF17130E) : const Color(0xFFFDFCF9);

    final baseTextTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: tokens.ink,
        height: 1.28,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        color: tokens.ink,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: tokens.ink,
        height: 1.32,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: tokens.ink,
        height: 1.32,
      ),
      titleMedium: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
        height: 1.28,
      ),
      titleSmall: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: tokens.inkMuted,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 15.5,
        fontWeight: isDark ? FontWeight.w400 : FontWeight.w400,
        color: tokens.ink,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: tokens.inkMuted,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: tokens.inkMuted,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.inkMuted,
      ),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: isDark ? 0.16 : 0.10),
      onPrimaryContainer: isDark ? primary : const Color(0xFF7D3F0B),
      secondary: tokens.instrument,
      onSecondary: isDark ? const Color(0xFF0E161E) : const Color(0xFFFDFCF9),
      surface: tokens.surface,
      onSurface: tokens.ink,
      onSurfaceVariant: tokens.inkMuted,
      surfaceContainerHighest: tokens.well,
      outline: tokens.hairlineStrong,
      outlineVariant: tokens.hairline,
      error: isDark ? const Color(0xFFE0786E) : const Color(0xFFB5443A),
      onError: isDark ? const Color(0xFF1E0D0C) : const Color(0xFFFDFCF9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      extensions: [tokens],
      textTheme: baseTextTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.hairline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.hairline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.well,
        isDense: true,
        hintStyle: TextStyle(color: tokens.inkMuted.withValues(alpha: 0.7)),
        labelStyle: TextStyle(color: tokens.inkMuted, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ink,
          backgroundColor: tokens.surface,
          minimumSize: const Size(0, 44),
          side: BorderSide(color: tokens.hairlineStrong, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(40, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.well,
        selectedColor: primary.withValues(alpha: isDark ? 0.18 : 0.11),
        side: BorderSide(color: tokens.hairline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        labelStyle: baseTextTheme.labelMedium?.copyWith(color: tokens.ink),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.padded,
          minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primary.withValues(alpha: isDark ? 0.18 : 0.12);
            }
            return tokens.well;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return tokens.inkMuted;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(
                  color: primary.withValues(alpha: 0.45), width: 1);
            }
            return BorderSide(color: tokens.hairline, width: 1);
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF252930) : const Color(0xFF1B1A17),
        contentTextStyle: const TextStyle(
          color: Color(0xFFECEEF2),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: isDark ? const Color(0xFF3D4450) : const Color(0xFF33302A),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.hairline, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
    );
  }
}
