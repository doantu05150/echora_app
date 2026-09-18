import 'package:flutter/material.dart';

/// Hai font đều là variable font nên phải set `fontVariations`;
/// `fontWeight` một mình không đổi nét trên mọi nền tảng.
TextStyle _bricolage(double size, {double weight = 800}) => TextStyle(
  fontFamily: 'BricolageGrotesque',
  fontSize: size,
  fontWeight: FontWeight.w800,
  fontVariations: [FontVariation('wght', weight)],
  letterSpacing: size * -0.02,
  height: 1.16,
);

TextStyle _manrope(double size, {double weight = 400, double height = 1.4}) =>
    TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight)],
      height: height,
    );

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.title,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.caption,
    required this.numeric,
  });

  /// Tên màn hình.
  final TextStyle displayLarge;

  /// Tên chủ đề, số stat.
  final TextStyle displayMedium;
  final TextStyle displaySmall;

  /// Tiêu đề thẻ / list item.
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodySmall;

  /// Chữ trong chip, nút.
  final TextStyle label;
  final TextStyle caption;

  /// Đồng hồ trong Player — chữ số đều bề rộng.
  final TextStyle numeric;

  static final standard = AppTypography(
    displayLarge: _bricolage(27),
    displayMedium: _bricolage(24),
    displaySmall: _bricolage(22),
    title: _manrope(17, weight: 700, height: 1.3),
    body: _manrope(15),
    bodySmall: _manrope(13),
    label: _manrope(13, weight: 600, height: 1.2),
    caption: _manrope(11, weight: 600, height: 1.2),
    numeric: _manrope(
      13,
      weight: 700,
      height: 1.2,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
  );

  /// Text luyện tập: cỡ chữ do người dùng chỉnh (20–40sp).
  static TextStyle practice(double fontSize) =>
      _manrope(fontSize, weight: 700, height: 1.32);

  @override
  AppTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? numeric,
  }) {
    return AppTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      title: title ?? this.title,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      numeric: numeric ?? this.numeric,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) => other ?? this;
}
