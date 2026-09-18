import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_dimens.dart';
export 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const c = AppColors.light;
    final t = AppTypography.standard;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: c.paper,
      splashFactory: InkSparkle.splashFactory,
      // M3 sinh color scheme từ seed thì không khớp token, nên chỉ định tay.
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5B4BD8),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFFB8471F),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1A1726),
        outline: Color(0xFFE8E2D8),
      ),
      textTheme: TextTheme(
        displayLarge: t.displayLarge,
        displayMedium: t.displayMedium,
        displaySmall: t.displaySmall,
        titleMedium: t.title,
        bodyLarge: t.body,
        bodyMedium: t.bodySmall,
        labelLarge: t.label,
        labelSmall: t.caption,
      ).apply(bodyColor: c.ink, displayColor: c.ink),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.surface
              : c.inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.violet.base
              : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.violet.base
              : c.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.violet.base,
        inactiveTrackColor: c.surfaceMuted,
        thumbColor: c.violet.base,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      extensions: [c, t],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get typography => Theme.of(this).extension<AppTypography>()!;
}
