import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The single theme of the app.
///
/// The design uses Be Vietnam Pro. The app falls back to the system font when
/// the font asset is absent, which keeps the layout correct.
abstract final class AppTheme {
  static const fontFamily = 'BeVietnamPro';

  /// The height of a primary and a secondary button.
  static const buttonHeight = 56.0;

  /// The radius of a card.
  static const cardRadius = 14.0;

  /// The radius of a button and a small tile.
  static const controlRadius = 12.0;

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryDark,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      dividerColor: AppColors.divider,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted),
        bodySmall: TextStyle(fontSize: 13, color: AppColors.muted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface,
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(AppColors.primary),
      ),
    );
  }
}
