import 'package:flutter/material.dart';

/// Granular spacing scale (4pt base).
class AppSpace {
  AppSpace._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Consistent corner radii per containment level.
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double sheet = 24;
}

/// Tonal surface & ink tokens exposed via ThemeExtension.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color canvas;
  final Color surface;
  final Color well;
  final Color hairline;
  final Color ink;
  final Color inkMuted;

  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.well,
    required this.hairline,
    required this.ink,
    required this.inkMuted,
  });

  static const light = AppTokens(
    canvas: Color(0xFFF5F6F3),
    surface: Color(0xFFFCFDFB),
    well: Color(0xFFEAECE6),
    hairline: Color(0xFFD7DBD2),
    ink: Color(0xFF16201D),
    inkMuted: Color(0xFF5A6661),
  );

  static const dark = AppTokens(
    canvas: Color(0xFF0F1412),
    surface: Color(0xFF171F1C),
    well: Color(0xFF202B27),
    hairline: Color(0xFF2A3732),
    ink: Color(0xFFECF1EE),
    inkMuted: Color(0xFF98A6A0),
  );

  @override
  AppTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? well,
    Color? hairline,
    Color? ink,
    Color? inkMuted,
  }) {
    return AppTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      well: well ?? this.well,
      hairline: hairline ?? this.hairline,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      well: Color.lerp(well, other.well, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
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
  static const Color primaryTeal = Color(0xFF0D7377);
  static const Color primaryTealDark = Color(0xFF2BA89F);

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
    final primary = isDark ? primaryTealDark : primaryTeal;
    final onPrimary =
        isDark ? const Color(0xFF081C1A) : const Color(0xFFF6FAF9);

    final baseTextTheme = TextTheme(
      headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
          height: 1.15),
      headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
          height: 1.2),
      headlineSmall: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
          height: 1.25),
      titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: tokens.ink,
          height: 1.25),
      titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: tokens.ink,
          height: 1.3),
      titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tokens.inkMuted,
          height: 1.3),
      bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: tokens.ink,
          height: 1.45),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: tokens.inkMuted,
          height: 1.45),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: tokens.inkMuted,
          height: 1.4),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: tokens.ink),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: tokens.inkMuted),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: isDark ? 0.18 : 0.10),
      onPrimaryContainer: isDark ? primary : const Color(0xFF094F52),
      secondary: const Color(0xFFB45309),
      onSecondary: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.ink,
      onSurfaceVariant: tokens.inkMuted,
      surfaceContainerHighest: tokens.well,
      outline: tokens.inkMuted.withValues(alpha: 0.4),
      outlineVariant: tokens.hairline,
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFC83E3B),
      onError: isDark ? const Color(0xFF1F0A0A) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      extensions: [tokens],
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge
            ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
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
        hintStyle: TextStyle(color: tokens.inkMuted),
        labelStyle: TextStyle(color: tokens.inkMuted),
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ink,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: tokens.hairline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.well,
        selectedColor: primary.withValues(alpha: isDark ? 0.22 : 0.12),
        side: BorderSide(color: tokens.hairline, width: 1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        labelStyle: baseTextTheme.labelMedium?.copyWith(color: tokens.ink),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: tokens.surface,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: isDark ? 0.20 : 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 22);
          }
          return IconThemeData(color: tokens.inkMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                color: primary, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return TextStyle(
              color: tokens.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF24302C) : const Color(0xFF1A2421),
        contentTextStyle: const TextStyle(
            color: Color(0xFFF5F7F6),
            fontSize: 14,
            fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
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
