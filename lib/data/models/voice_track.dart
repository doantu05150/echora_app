import 'package:flutter/foundation.dart';

@immutable
class VoiceSentence {
  const VoiceSentence({
    required this.index,
    required this.startMs,
    required this.endMs,
  });

  final int index;

  /// Mốc trong file audio ở tốc độ gốc, chưa nhân tốc độ phát.
  final int startMs;
  final int endMs;

  factory VoiceSentence.fromJson(Map<String, dynamic> json) => VoiceSentence(
    index: json['index'] as int,
    startMs: json['startMs'] as int,
    endMs: json['endMs'] as int,
  );
}

/// Giọng đọc mẫu của một bài: file audio + mốc thời gian thật của từng câu,
/// đo từ số mẫu audio lúc render (`tool/generate_voice.py`). Nhờ vậy chữ và
/// giọng không cần dò khớp lúc chạy.
@immutable
class VoiceTrack {
  const VoiceTrack({
    required this.passageId,
    required this.audioAsset,
    required this.voice,
    required this.nativeWpm,
    required this.totalMs,
    required this.sentences,
  });

  final String passageId;
  final String audioAsset;

  /// Tên giọng Kokoro đã render, chỉ để tra cứu khi render lại.
  final String voice;

  /// Tốc độ đọc thật của file, đo sau khi render. Là mốc `1.0×` khi phát.
  final int nativeWpm;
  final int totalMs;
  final List<VoiceSentence> sentences;

  /// Tốc độ phát để giọng đọc khớp `wpm` người dùng chọn.
  double speedAt(int wpm) => wpm / nativeWpm;

  factory VoiceTrack.fromJson(Map<String, dynamic> json) => VoiceTrack(
    passageId: json['passageId'] as String,
    audioAsset: json['audio'] as String,
    voice: json['voice'] as String,
    nativeWpm: json['nativeWpm'] as int,
    totalMs: json['totalMs'] as int,
    sentences: (json['sentences'] as List<dynamic>)
        .map((e) => VoiceSentence.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
