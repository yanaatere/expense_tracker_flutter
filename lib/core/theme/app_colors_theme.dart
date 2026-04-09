import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Theme-aware color set
// ---------------------------------------------------------------------------

class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  final Color background;
  final Color cardBg;
  final Color inputBg;
  final Color inputBorder;
  final Color labelText;
  final Color bodyText;
  final Color placeholderText;
  final Color pageBg;

  const AppColorsTheme({
    required this.background,
    required this.cardBg,
    required this.inputBg,
    required this.inputBorder,
    required this.labelText,
    required this.bodyText,
    required this.placeholderText,
    required this.pageBg,
  });

  // ── Presets ──────────────────────────────────────────────────────────────

  static const light = AppColorsTheme(
    background: Color(0xFFFFFFFF),
    cardBg: Color(0xFFF0F0FF),
    inputBg: Color(0xFFF8F9FB),
    inputBorder: Color(0xFFE5E7EB),
    labelText: Color(0xFF111827),
    bodyText: Color(0xFF374151),
    placeholderText: Color(0xFFA3A3A3),
    pageBg: Color(0xFFF5F5FF),
  );

  static const dark = AppColorsTheme(
    background: Color(0xFF121212),
    cardBg: Color(0xFF1E1E2E),
    inputBg: Color(0xFF1E1E2E),
    inputBorder: Color(0xFF2D2D3F),
    labelText: Color(0xFFF9FAFB),
    bodyText: Color(0xFFD1D5DB),
    placeholderText: Color(0xFF6B7280),
    pageBg: Color(0xFF0F0F1A),
  );

  // ── ThemeData builders ───────────────────────────────────────────────────

  static ThemeData get lightThemeData => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: light.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        extensions: const [light],
      );

  static ThemeData get darkThemeData => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: dark.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        extensions: const [dark],
      );

  // ── ThemeExtension overrides ─────────────────────────────────────────────

  @override
  AppColorsTheme copyWith({
    Color? background,
    Color? cardBg,
    Color? inputBg,
    Color? inputBorder,
    Color? labelText,
    Color? bodyText,
    Color? placeholderText,
    Color? pageBg,
  }) =>
      AppColorsTheme(
        background: background ?? this.background,
        cardBg: cardBg ?? this.cardBg,
        inputBg: inputBg ?? this.inputBg,
        inputBorder: inputBorder ?? this.inputBorder,
        labelText: labelText ?? this.labelText,
        bodyText: bodyText ?? this.bodyText,
        placeholderText: placeholderText ?? this.placeholderText,
        pageBg: pageBg ?? this.pageBg,
      );

  @override
  AppColorsTheme lerp(AppColorsTheme? other, double t) {
    if (other == null) return this;
    return AppColorsTheme(
      background: Color.lerp(background, other.background, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      labelText: Color.lerp(labelText, other.labelText, t)!,
      bodyText: Color.lerp(bodyText, other.bodyText, t)!,
      placeholderText: Color.lerp(placeholderText, other.placeholderText, t)!,
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// BuildContext extension — usage: context.appColors.labelText
// ---------------------------------------------------------------------------

extension AppColorsX on BuildContext {
  AppColorsTheme get appColors =>
      Theme.of(this).extension<AppColorsTheme>() ?? AppColorsTheme.light;
}
