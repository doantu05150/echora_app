import 'package:flutter/material.dart';

import '../../../ui/theme/app_theme.dart';
import '../playback/playback_timeline.dart';

const double _sentenceGap = AppSpacing.sm;
const double _sentencePaddingV = AppSpacing.md;
const double _sentencePaddingH = AppSpacing.lg;

/// Toàn bộ text trôi đều từ dưới lên, câu đang đọc nằm giữa màn. Không đánh dấu
/// câu hiện tại. Vị trí cuộn suy ra từ `elapsedMs` qua bảng timing — renderer
/// không giữ bộ đếm riêng.
class ScrollTextView extends StatelessWidget {
  const ScrollTextView({
    super.key,
    required this.timeline,
    required this.elapsedMs,
    required this.fontSizeSp,
  });

  final PlaybackTimeline timeline;
  final int elapsedMs;
  final double fontSizeSp;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.practice(
      fontSizeSp,
    ).copyWith(color: context.colors.ink);

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
                    for (final sentence in timeline.sentences)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _sentenceGap),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _sentencePaddingH,
                            vertical: _sentencePaddingV,
                          ),
                          child: Text(
                            sentence.text,
                            textAlign: TextAlign.center,
                            style: style,
                          ),
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
    final contentWidth = maxWidth - _sentencePaddingH * 2;
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
