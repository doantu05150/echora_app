import 'package:flutter/foundation.dart';

@immutable
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.colorToken,
    required this.levelRange,
    required this.order,
    required this.comingSoon,
  });

  final String id;
  final String title;
  final String description;

  /// Khớp với một `AccentColor` trong `AppColors.byToken`.
  final String colorToken;
  final String levelRange;
  final int order;
  final bool comingSoon;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    colorToken: json['colorToken'] as String,
    levelRange: json['levelRange'] as String,
    order: json['order'] as int,
    comingSoon: json['comingSoon'] as bool? ?? false,
  );
}
