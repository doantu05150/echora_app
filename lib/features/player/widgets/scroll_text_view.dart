import 'package:flutter/material.dart';

import '../../../ui/theme/app_theme.dart';
import '../playback/playback_timeline.dart';

const double _sentenceGap = AppSpacing.sm;
const double _sentencePaddingV = AppSpacing.md;
const double _bandPaddingH = AppSpacing.lg;
const double _ruleWidth = 3;

/// Toàn bộ text trôi đều từ dưới lên, câu đang đọc nằm giữa màn trong band
/// màu của topic. Vị trí cuộn suy ra từ `elapsedMs` qua bảng timing — renderer
/// không giữ bộ đếm riêng.
class ScrollTextView extends StatelessWidget {
  const ScrollTextView({
    super.key,
    required this.timeline,
    required this.elapsedMs,
    required this.fontSizeSp,
    required this.accent,
  });

  final PlaybackTimeline timeline;
  final int elapsedMs;
  final double fontSizeSp;
  final AccentColor accent;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.practice(fontSizeSp);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _SentenceMetrics.measure(
          sentences: timeline.sentences,
          style: style,
          maxWidth: constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );

        final current = timeline.sentenceIndexAt(elapsedMs);
        final span = timeline.sentences[current];
        final spanMs = (span.endMs - span.startMs).clamp(1, 1 << 30);
        final progressInSentence =
            ((elapsedMs - span.startMs) / spanMs).clamp(0.0, 1.0);

        final readingY =
            metrics.tops[current] + progressInSentence * metrics.heights[current];
        final translateY = constraints.maxHeight / 2 - readingY;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: translateY,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < timeline.sentences.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _sentenceGap),
                        child: _SentenceBand(
                          text: timeline.sentences[i].text,
                          style: style,
                          accent: accent,
                          distance: (i - current).abs(),
                          isCurrent: i == current,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SentenceBand extends StatelessWidget {
  const _SentenceBand({
    required this.text,
    required this.style,
    required this.accent,
    required this.distance,
    required this.isCurrent,
  });

  final String text;
  final TextStyle style;
  final AccentColor accent;
  final int distance;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final opacity = switch (distance) {
      0 => 1.0,
      1 => 0.45,
      2 => 0.26,
      _ => 0.14,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent ? accent.tint : null,
          // Viền trái luôn chiếm chỗ dù trong suốt: nếu không, bề rộng chữ đổi
          // theo từng câu và chiều cao đo trước sẽ lệch layout thật.
          border: Border(
            left: BorderSide(
              width: _ruleWidth,
              color: isCurrent ? accent.base : Colors.transparent,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _bandPaddingH,
          vertical: _sentencePaddingV,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: colors.ink.withValues(alpha: opacity)),
        ),
      ),
    );
  }
}

/// Chiều cao từng câu tính bằng `TextPainter` với đúng style và bề rộng của
/// widget, nên vị trí cuộn khớp layout thật mà không cần đo sau khi vẽ.
class _SentenceMetrics {
  const _SentenceMetrics({required this.heights, required this.tops});

  final List<double> heights;
  final List<double> tops;

  static _SentenceMetrics measure({
    required List<SentenceSpan> sentences,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
  }) {
    final contentWidth = maxWidth - _ruleWidth - _bandPaddingH * 2;
    final heights = <double>[];
    final tops = <double>[];

    var offset = 0.0;
    for (final sentence in sentences) {
      final painter = TextPainter(
        text: TextSpan(text: sentence.text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textScaler: textScaler,
      )..layout(maxWidth: contentWidth);

      final height = painter.height + _sentencePaddingV * 2;
      painter.dispose();

      heights.add(height);
      tops.add(offset);
      offset += height + _sentenceGap;
    }

    return _SentenceMetrics(heights: heights, tops: tops);
  }
}
