import 'package:flutter/foundation.dart';

@immutable
class Passage {
  const Passage({
    required this.id,
    required this.topicId,
    required this.title,
    required this.level,
    required this.durationMin,
    required this.wordCount,
    required this.order,
    required this.body,
  });

  final String id;
  final String topicId;
  final String title;
  final String level;

  /// Độ dài ở WPM tham chiếu (90). Người dùng lọc theo giá trị này.
  /// Thời lượng thực tế phụ thuộc WPM đang chọn, xem `PlaybackTimeline`.
  final int durationMin;

  /// Tính sẵn khi tạo nội dung, không đếm lại lúc chạy.
  final int wordCount;
  final int order;

  /// Mảng câu đã tách sẵn. Tách ở runtime bằng regex là nguồn bug.
  final List<String> body;

  factory Passage.fromJson(Map<String, dynamic> json) => Passage(
    id: json['id'] as String,
    topicId: json['topicId'] as String,
    title: json['title'] as String,
    level: json['level'] as String,
    durationMin: json['durationMin'] as int,
    wordCount: json['wordCount'] as int,
    order: json['order'] as int,
    body: (json['body'] as List<dynamic>).cast<String>(),
  );
}
