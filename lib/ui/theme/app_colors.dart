import 'package:flutter/material.dart';

/// Bảng màu duy nhất của app. Không hardcode hex ngoài file này.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderSubtle,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.violet,
    required this.clay,
    required this.teal,
    required this.amber,
    required this.rose,
  });

  final Color paper;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderSubtle;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;

  final AccentColor violet;
  final AccentColor clay;
  final AccentColor teal;
  final AccentColor amber;
  final AccentColor rose;

  static const light = AppColors(
    paper: Color(0xFFFBF8F3),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF2EDE4),
    border: Color(0xFFE8E2D8),
    borderSubtle: Color(0xFFF0EBE2),
    ink: Color(0xFF1A1726),
    inkMuted: Color(0xFF6B6579),
    inkFaint: Color(0xFFA8A2B2),
    violet: AccentColor(
      base: Color(0xFF5B4BD8),
      tint: Color(0xFFEFECFC),
      onTint: Color(0xFF3A2DA8),
      tintBorder: Color(0xFFDAD4F7),
    ),
    clay: AccentColor(
      base: Color(0xFFB8471F),
      tint: Color(0xFFFDEAE2),
      onTint: Color(0xFF8A5A45),
      tintBorder: Color(0xFFF6D6C8),
    ),
    teal: AccentColor(
      base: Color(0xFF0F7566),
      tint: Color(0xFFDFF1EE),
      onTint: Color(0xFF3C6D64),
      tintBorder: Color(0xFFC4E4DE),
    ),
    amber: AccentColor(
      base: Color(0xFF96661A),
      tint: Color(0xFFFBEFD6),
      onTint: Color(0xFF7A5314),
      tintBorder: Color(0xFFF0DDB4),
    ),
    rose: AccentColor(
      base: Color(0xFFC2185B),
      tint: Color(0xFFFCE7EF),
      onTint: Color(0xFF8E1044),
      tintBorder: Color(0xFFF7CEDF),
    ),
  );

  AccentColor byToken(String token) => switch (token) {
    'violet' => violet,
    'clay' => clay,
    'teal' => teal,
    'amber' => amber,
    'rose' => rose,
    _ => violet,
  };

  @override
  AppColors copyWith({
    Color? paper,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? borderSubtle,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    AccentColor? violet,
    AccentColor? clay,
    AccentColor? teal,
    AccentColor? amber,
    AccentColor? rose,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      violet: violet ?? this.violet,
      clay: clay ?? this.clay,
      teal: teal ?? this.teal,
      amber: amber ?? this.amber,
      rose: rose ?? this.rose,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) => other ?? this;
}

@immutable
class AccentColor {
  const AccentColor({
    required this.base,
    required this.tint,
    required this.onTint,
    required this.tintBorder,
  });

  /// Màu đậm: nền nút, viền trái câu đang đọc, icon active.
  final Color base;

  /// Nền nhạt của thẻ / band.
  final Color tint;

  /// Chữ đặt trên `tint`.
  final Color onTint;

  /// Viền của thẻ dùng `tint`.
  final Color tintBorder;
}
