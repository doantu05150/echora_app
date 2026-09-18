import 'package:flutter/foundation.dart';

import '../../../data/models/passage.dart';

/// WPM tham chiếu: `wpm = 90` tương đương hệ số `1.0×`.
const int kReferenceWpm = 90;
const int kMinWpm = 50;
const int kMaxWpm = 160;
const int kWpmStep = 5;

double multiplierOf(int wpm) => (wpm / kReferenceWpm * 10).round() / 10;

@immutable
class WordSpan {
  const WordSpan({
    required this.text,
    required this.globalIndex,
    required this.startMs,
    required this.endMs,
  });

  final String text;

  /// Chỉ số từ tính trên toàn bài — dùng để giữ nguyên vị trí khi đổi WPM.
  final int globalIndex;
  final int startMs;
  final int endMs;
}

@immutable
class SentenceSpan {
  const SentenceSpan({
    required this.index,
    required this.text,
    required this.words,
    required this.startMs,
    required this.endMs,
  });

  final int index;
  final String text;
  final List<WordSpan> words;
  final int startMs;
  final int endMs;
}

/// Bảng timing tính sẵn một lần khi mở passage hoặc khi đổi WPM.
/// Renderer chỉ tra bảng theo `elapsedMs`, không tự tính thời gian.
@immutable
class PlaybackTimeline {
  const PlaybackTimeline({
    required this.wpm,
    required this.sentences,
    required this.totalMs,
    required this.wordCount,
  });

  final int wpm;
  final List<SentenceSpan> sentences;
  final int totalMs;
  final int wordCount;

  factory PlaybackTimeline.of(Passage passage, int wpm) {
    final msPerWord = 60000 / wpm;
    final sentences = <SentenceSpan>[];

    var globalIndex = 0;
    for (var i = 0; i < passage.body.length; i++) {
      final tokens = passage.body[i].split(RegExp(r'\s+'))
        ..removeWhere((t) => t.isEmpty);
      final words = <WordSpan>[];
      for (final token in tokens) {
        words.add(
          WordSpan(
            text: token,
            globalIndex: globalIndex,
            startMs: (globalIndex * msPerWord).round(),
            endMs: ((globalIndex + 1) * msPerWord).round(),
          ),
        );
        globalIndex++;
      }
      if (words.isEmpty) continue;

      sentences.add(
        SentenceSpan(
          index: sentences.length,
          text: passage.body[i],
          words: words,
          startMs: words.first.startMs,
          endMs: words.last.endMs,
        ),
      );
    }

    return PlaybackTimeline(
      wpm: wpm,
      sentences: sentences,
      totalMs: (globalIndex * msPerWord).round(),
      wordCount: globalIndex,
    );
  }

  int sentenceIndexAt(int elapsedMs) {
    if (sentences.isEmpty) return 0;
    var low = 0;
    var high = sentences.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (sentences[mid].startMs <= elapsedMs) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Chỉ số từ trong câu đang đọc. Trả về từ cuối khi đã qua hết câu.
  int wordIndexInSentenceAt(int elapsedMs) {
    final sentence = sentences[sentenceIndexAt(elapsedMs)];
    for (var i = sentence.words.length - 1; i >= 0; i--) {
      if (elapsedMs >= sentence.words[i].startMs) return i;
    }
    return 0;
  }

  /// Vị trí liên tục theo từ, phần thập phân là tiến độ trong từ hiện tại.
  /// Dùng làm cầu nối khi đổi WPM giữa chừng.
  double wordPositionAt(int elapsedMs) {
    if (wordCount == 0) return 0;
    final msPerWord = totalMs / wordCount;
    return (elapsedMs / msPerWord).clamp(0, wordCount.toDouble());
  }

  int msAtWordPosition(double wordPosition) {
    if (wordCount == 0) return 0;
    final msPerWord = totalMs / wordCount;
    return (wordPosition * msPerWord).round().clamp(0, totalMs);
  }

  /// Tua giữa câu thì không shadowing được, nên luôn kéo về đầu câu gần nhất.
  int snapToSentenceStart(int elapsedMs) {
    if (sentences.isEmpty) return 0;
    if (elapsedMs >= totalMs) return sentences.last.startMs;
    return sentences[sentenceIndexAt(elapsedMs.clamp(0, totalMs))].startMs;
  }

  double progressAt(int elapsedMs) =>
      totalMs == 0 ? 0 : (elapsedMs / totalMs).clamp(0.0, 1.0);
}
