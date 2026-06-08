import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme Context Extension ──────────────────────────────────────────────────
extension ThemeColorsExt on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

// ─── Design Tokens (ThemeExtension) ───────────────────────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceBright;

  final Color primary;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color primaryDim;
  final Color inversePrimary;
  final Color onPrimary;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  final Color secondary;
  final Color secondaryDim;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color secondaryContainer;
  final Color onSecondary;
  final Color onSecondaryFixed;
  final Color onSecondaryContainer;

  final Color tertiary;
  final Color tertiaryDim;
  final Color tertiaryFixed;
  final Color tertiaryFixedDim;
  final Color tertiaryContainer;

  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onBackground;

  final Color outline;
  final Color outlineVariant;

  final Color error;
  final Color errorDim;
  final Color errorContainer;
  final Color onError;
  final Color onErrorContainer;

  final LinearGradient brandGradient;
  final LinearGradient brandGradientH;

  final Color glassColor;
  final Color glassPanelColor;
  final Color topBarColor;
  final Color bottomNavColor;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;
  final List<BoxShadow> primaryGlow;

  AppColors({
    required this.background,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceBright,
    required this.primary,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.primaryDim,
    required this.inversePrimary,
    required this.onPrimary,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryDim,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.onSecondaryFixed,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.tertiaryDim,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
    required this.tertiaryContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onBackground,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.errorDim,
    required this.errorContainer,
    required this.onError,
    required this.onErrorContainer,
    required this.brandGradient,
    required this.brandGradientH,
    required this.glassColor,
    required this.glassPanelColor,
    required this.topBarColor,
    required this.bottomNavColor,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.primaryGlow,
  });

  @override
  ThemeExtension<AppColors> copyWith() => this;

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainerLowest: Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      primaryFixedDim: Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      inversePrimary: Color.lerp(inversePrimary, other.inversePrimary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      onPrimaryFixedVariant: Color.lerp(onPrimaryFixedVariant, other.onPrimaryFixedVariant, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryDim: Color.lerp(secondaryDim, other.secondaryDim, t)!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      secondaryFixedDim: Color.lerp(secondaryFixedDim, other.secondaryFixedDim, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSecondaryFixed: Color.lerp(onSecondaryFixed, other.onSecondaryFixed, t)!,
      onSecondaryContainer: Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryDim: Color.lerp(tertiaryDim, other.tertiaryDim, t)!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      tertiaryFixedDim: Color.lerp(tertiaryFixedDim, other.tertiaryFixedDim, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorDim: Color.lerp(errorDim, other.errorDim, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      brandGradient: brandGradient,
      brandGradientH: brandGradientH,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassPanelColor: Color.lerp(glassPanelColor, other.glassPanelColor, t)!,
      topBarColor: Color.lerp(topBarColor, other.topBarColor, t)!,
      bottomNavColor: Color.lerp(bottomNavColor, other.bottomNavColor, t)!,
      cardShadow: cardShadow,
      elevatedShadow: elevatedShadow,
      primaryGlow: primaryGlow,
    );
  }

  // ─── Light Theme Palette ───────────────────────────────────────────────────
  static final AppColors light = AppColors(
    background: const Color(0xFFF8F9FA),
    surface: const Color(0xFFFFFFFF),
    surfaceContainerLowest: const Color(0xFFF0F0F8),
    surfaceContainerLow: const Color(0xFFE8E8F4),
    surfaceContainer: const Color(0xFFEEEEF8),
    surfaceContainerHigh: const Color(0xFFE4E4F0),
    surfaceContainerHighest: const Color(0xFFD8D8EC),
    surfaceBright: const Color(0xFFFFFFFF),
    primary: const Color(0xFF6366F1),
    primaryFixed: const Color(0xFF6063EE),
    primaryFixedDim: const Color(0xFF5053D8),
    primaryDim: const Color(0xFF4F52C9),
    inversePrimary: const Color(0xFFA3A6FF),
    onPrimary: const Color(0xFFFFFFFF),
    onPrimaryFixed: const Color(0xFFFFFFFF),
    onPrimaryFixedVariant: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFE8EAFF),
    onPrimaryContainer: const Color(0xFF2A2D9E),
    secondary: const Color(0xFF9333EA),
    secondaryDim: const Color(0xFF7E22CE),
    secondaryFixed: const Color(0xFFF3E8FF),
    secondaryFixedDim: const Color(0xFFE9D5FF),
    secondaryContainer: const Color(0xFFF5F0FF),
    onSecondary: const Color(0xFFFFFFFF),
    onSecondaryFixed: const Color(0xFF6B21A8),
    onSecondaryContainer: const Color(0xFF4C1D95),
    tertiary: const Color(0xFF0EA5E9),
    tertiaryDim: const Color(0xFF0284C7),
    tertiaryFixed: const Color(0xFFE0F2FE),
    tertiaryFixedDim: const Color(0xFFBAE6FD),
    tertiaryContainer: const Color(0xFFE0F2FE),
    onSurface: const Color(0xFF1A1A2E),
    onSurfaceVariant: const Color(0xFF6B6B8A),
    onBackground: const Color(0xFF1A1A2E),
    outline: const Color(0xFFACACC8),
    outlineVariant: const Color(0xFFCACAE0),
    error: const Color(0xFFDC2626),
    errorDim: const Color(0xFFB91C1C),
    errorContainer: const Color(0xFFFEE2E2),
    onError: const Color(0xFFFFFFFF),
    onErrorContainer: const Color(0xFF7F1D1D),
    brandGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
    ),
    brandGradientH: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
    ),
    glassColor: const Color(0xB3FFFFFF),
    glassPanelColor: const Color(0xCCFFFFFF),
    topBarColor: const Color(0xD9F8F9FA),
    bottomNavColor: const Color(0xE6FFFFFF),
    cardShadow: const [
      BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    elevatedShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x1A000000), blurRadius: 32, offset: Offset(0, 12)),
    ],
    primaryGlow: [
      BoxShadow(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 8)),
    ],
  );

  // ─── Dark Theme Palette ────────────────────────────────────────────────────
  static final AppColors dark = AppColors(
    background: const Color(0xFF0F172A),          // deep dark blue
    surface: const Color(0xFF1E293B),             // soft cards
    surfaceContainerLowest: const Color(0xFF0B1121),
    surfaceContainerLow: const Color(0xFF0F172A),
    surfaceContainer: const Color(0xFF1E293B),
    surfaceContainerHigh: const Color(0xFF334155),
    surfaceContainerHighest: const Color(0xFF475569),
    surfaceBright: const Color(0xFF334155),
    primary: const Color(0xFFA855F7),             // violet neon
    primaryFixed: const Color(0xFFC084FC),
    primaryFixedDim: const Color(0xFFD8B4FE),
    primaryDim: const Color(0xFF9333EA),
    inversePrimary: const Color(0xFF6366F1),
    onPrimary: const Color(0xFFFFFFFF),
    onPrimaryFixed: const Color(0xFF1A1A2E),
    onPrimaryFixedVariant: const Color(0xFF1A1A2E),
    primaryContainer: const Color(0xFF3B0764),
    onPrimaryContainer: const Color(0xFFF3E8FF),
    secondary: const Color(0xFF38BDF8),
    secondaryDim: const Color(0xFF0284C7),
    secondaryFixed: const Color(0xFFBAE6FD),
    secondaryFixedDim: const Color(0xFFE0F2FE),
    secondaryContainer: const Color(0xFF075985),
    onSecondary: const Color(0xFFFFFFFF),
    onSecondaryFixed: const Color(0xFF1A1A2E),
    onSecondaryContainer: const Color(0xFFE0F2FE),
    tertiary: const Color(0xFFF43F5E),
    tertiaryDim: const Color(0xFFE11D48),
    tertiaryFixed: const Color(0xFFFECDD3),
    tertiaryFixedDim: const Color(0xFFFFE4E6),
    tertiaryContainer: const Color(0xFF881337),
    onSurface: const Color(0xFFF1F5F9),           // light gray/white text
    onSurfaceVariant: const Color(0xFF94A3B8),    // muted text
    onBackground: const Color(0xFFF1F5F9),
    outline: const Color(0xFF475569),
    outlineVariant: const Color(0xFF334155),
    error: const Color(0xFFEF4444),
    errorDim: const Color(0xFFDC2626),
    errorContainer: const Color(0xFF7F1D1D),
    onError: const Color(0xFFFFFFFF),
    onErrorContainer: const Color(0xFFFEF2F2),
    brandGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    ),
    brandGradientH: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    ),
    glassColor: const Color(0x660F172A),
    glassPanelColor: const Color(0x801E293B),
    topBarColor: const Color(0xD90F172A),
    bottomNavColor: const Color(0xF21E293B),
    cardShadow: const [
      BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
    elevatedShadow: const [
      BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 12)),
    ],
    primaryGlow: [
      BoxShadow(
          color: const Color(0xFFA855F7).withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 8)),
    ],
  );
}

// ─── Blur constants ───────────────────────────────────────────────────────────
abstract class AppBlur {
  static const double glass = 20;
  static const double xl   = 32;
  static const double lg   = 20;
  static const double md   = 12;
  static const double sm   = 6;
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.light.background,
      cardColor: AppColors.light.surface,
      dividerColor: AppColors.light.outlineVariant,
      extensions: [AppColors.light],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.light.onSurface,
        displayColor: AppColors.light.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.light.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.light.primary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.light.primary
              : AppColors.light.outlineVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.light.primary.withValues(alpha: 0.2)
              : AppColors.light.surfaceContainerHighest,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.primary, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.light.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.light.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.dark.background,
      cardColor: AppColors.dark.surface,
      dividerColor: AppColors.dark.outlineVariant,
      extensions: [AppColors.dark],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.dark.onSurface,
        displayColor: AppColors.dark.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.dark.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.dark.primary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.dark.primary
              : AppColors.dark.outlineVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.dark.primary.withValues(alpha: 0.2)
              : AppColors.dark.surfaceContainerHighest,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.primary, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.dark.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.dark.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
