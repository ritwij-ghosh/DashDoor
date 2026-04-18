import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_typography.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: AppPalette.primary,
    brightness: Brightness.light,
  );

  final scheme = baseScheme.copyWith(
    primary: AppPalette.primary,
    onPrimary: AppPalette.deepNavy,
    secondary: AppPalette.sunRewards,
    onSecondary: AppPalette.deepNavy,
    tertiary: AppPalette.successMint,
    onTertiary: AppPalette.deepNavy,
    error: AppPalette.urgency,
    onError: AppPalette.deepNavy,
    surface: AppPalette.surfaceWhite,
    onSurface: AppPalette.deepNavy,
    surfaceContainerHighest: AppPalette.border,
  );

  final textTheme = AppTypography.textTheme(textColor: AppPalette.deepNavy);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppTypography.fontFamily,
    scaffoldBackgroundColor: AppPalette.creamBackground,
    canvasColor: AppPalette.creamBackground,
    dividerColor: AppPalette.border,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.surfaceWhite,
      foregroundColor: AppPalette.deepNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppPalette.surfaceWhite,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppPalette.deepNavy,
        fontWeight: FontWeight.w700,
      ),
    ),
    iconTheme: const IconThemeData(color: AppPalette.neutral700),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.deepNavy,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.deepNavy,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPalette.primary,
      foregroundColor: AppPalette.deepNavy,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primary,
        side: const BorderSide(color: AppPalette.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surfaceWhite,
      hintStyle: const TextStyle(color: AppPalette.neutral500),
      labelStyle: const TextStyle(color: AppPalette.neutral700),
      helperStyle: const TextStyle(color: AppPalette.neutral500),
      errorStyle: const TextStyle(color: AppPalette.coralUrgency),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.urgency),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.urgency, width: 2),
      ),
    ),
    extensions: const [
      AppColors(
        info: AppPalette.skyInfo,
        urgency: AppPalette.urgency,
        rewards: AppPalette.sunRewards,
        premium: AppPalette.grapePremium,
        neutral900: AppPalette.neutral900,
        neutral700: AppPalette.neutral700,
        neutral500: AppPalette.neutral500,
        neutral200: AppPalette.border,
      ),
      AppTextStyles(
        h1: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: AppPalette.deepNavy,
        ),
        h2: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: AppPalette.deepNavy,
        ),
        h3: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: AppPalette.deepNavy,
        ),
        body: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
          color: AppPalette.deepNavy,
        ),
        bodyStrong: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: AppPalette.deepNavy,
        ),
        small: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: AppPalette.neutral700,
        ),
        smallStrong: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppPalette.deepNavy,
        ),
        caption: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w400,
          color: AppPalette.neutral700,
        ),
      ),
    ],
  );
});

class AppPalette {
  AppPalette._();

  // Brand (nibbl.*)
  static const Color primary = Color(0xFFFF4D2E); // nibbl.coral
  static const Color creamBackground = Color(0xFFF6F6F2); // nibbl.cream
  static const Color deepNavy = Color(0xFF111111); // nibbl.black
  static const Color neutral500 = Color(0xFF6F6F6F); // nibbl.gray
  static const Color neutral400 = Color(0xFF9E9E9E);
  static const Color neutral100 = Color(0xFFF1F1F1);

  // Accents (nibbl.*)
  static const Color sunRewards = Color(0xFFFFD93D); // nibbl.yellow
  static const Color successMint = Color(0xFF6BCB77); // nibbl.green
  // We intentionally keep the palette *small* in the UI. If we need "info" or
  // "premium" styling, we reuse coral rather than introducing more hues.
  static const Color grapePremium = primary;
  static const Color skyInfo = primary;

  // UI (nibbl.*)
  static const Color surfaceWhite = Color(0xFFFFFFFF); // nibbl.surface
  static const Color border = Color(0xFFE5E5E0); // nibbl.border

  // Semantics
  // "Urgency" isn't explicitly defined in nibbl.*; map it to coral to stay
  // within the simplified palette.
  static const Color urgency = primary;

  // Neutrals
  static const Color neutral900 = deepNavy;
  static const Color neutral700 = deepNavy;
  static const Color neutral200 = border;

  // Backwards-compat aliases (older screens still reference these)
  static const Color primaryLime = successMint;
  static const Color coralUrgency = urgency;

  // Animations & Micro-interactions
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 400);
  static const Duration slowDuration = Duration(milliseconds: 800);

  static Curve standardCurve = Curves.easeInOutQuart;
  static Curve bounceCurve = Curves.elasticOut;
  static Curve springCurve = Curves.easeOutBack;
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.info,
    required this.urgency,
    required this.rewards,
    required this.premium,
    required this.neutral900,
    required this.neutral700,
    required this.neutral500,
    required this.neutral200,
  });

  final Color info;
  final Color urgency;
  final Color rewards;
  final Color premium;

  final Color neutral900;
  final Color neutral700;
  final Color neutral500;
  final Color neutral200;

  @override
  AppColors copyWith({
    Color? info,
    Color? urgency,
    Color? rewards,
    Color? premium,
    Color? neutral900,
    Color? neutral700,
    Color? neutral500,
    Color? neutral200,
  }) {
    return AppColors(
      info: info ?? this.info,
      urgency: urgency ?? this.urgency,
      rewards: rewards ?? this.rewards,
      premium: premium ?? this.premium,
      neutral900: neutral900 ?? this.neutral900,
      neutral700: neutral700 ?? this.neutral700,
      neutral500: neutral500 ?? this.neutral500,
      neutral200: neutral200 ?? this.neutral200,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      info: Color.lerp(info, other.info, t)!,
      urgency: Color.lerp(urgency, other.urgency, t)!,
      rewards: Color.lerp(rewards, other.rewards, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
    );
  }
}
