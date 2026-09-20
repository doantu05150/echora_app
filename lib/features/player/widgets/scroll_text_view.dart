import 'package:flutter/material.dart';

import '../../../ui/theme/app_theme.dart';
import '../playback/playback_timeline.dart';

const double _sentenceGap = AppSpacing.sm;
const double _sentencePaddingV = AppSpacing.md;
const double _sentencePaddingH = AppSpacing.lg;

/// Toàn bộ text trôi đều từ dưới lên, câu đang đọc nằm giữa màn. Không đánh dấu
/// câu hiện tại. Vị trí cuộn suy ra từ `elapsedMs` qua bảng timing — renderer
/// không giữ bộ đếm riêng.
class ScrollTextView extends StatefulWidget {
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
  State<ScrollTextView> createState() => _ScrollTextViewState();
}

/// Widget này rebuild mỗi frame nên mọi thứ không đổi theo thời gian đều phải
/// tính sẵn: đo chiều cao câu bằng `TextPainter` và dựng cây câu chữ. Làm lại
/// hai việc đó ở nhịp 120Hz là đủ để rớt frame.
class _ScrollTextViewState extends State<ScrollTextView> {
  _SentenceMetrics? _metrics;
  Widget? _sentences;

  double _forWidth = 0;
  double _forFontSize = 0;
  TextScaler _forScaler = TextScaler.noScaling;
  List<SentenceSpan>? _forSentences;

  void _measure(double maxWidth, TextStyle style, TextScaler scaler) {
    final sentences = widget.timeline.sentences;
    final fresh =
        _metrics != null &&
        _forWidth == maxWidth &&
        _forFontSize == widget.fontSizeSp &&
        _forScaler == scaler &&
        // Đổi WPM dựng lại timeline nhưng câu chữ không đổi, không cần đo lại.
        _sameTexts(_forSentences, sentences);
    if (fresh) return;

    _forWidth = maxWidth;
    _forFontSize = widget.fontSizeSp;
    _forScaler = scaler;
    _forSentences = sentences;

    _metrics = _SentenceMetrics.measure(
      sentences: sentences,
      style: style,
      maxWidth: maxWidth,
      textScaler: scaler,
    );

    _sentences = RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final sentence in sentences)
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
    );
  }

  static bool _sameTexts(List<SentenceSpan>? a, List<SentenceSpan> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < b.length; i++) {
      if (a[i].text != b[i].text) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.practice(
      widget.fontSizeSp,
    ).copyWith(color: context.colors.ink);

    return LayoutBuilder(
      builder: (context, constraints) {
        _measure(
          constraints.maxWidth,
          style,
          MediaQuery.textScalerOf(context),
        );
        final metrics = _metrics!;

        final current = widget.timeline.sentenceIndexAt(widget.elapsedMs);
        final span = widget.timeline.sentences[current];
        final spanMs = (span.endMs - span.startMs).clamp(1, 1 << 30);
        final progressInSentence =
            ((widget.elapsedMs - span.startMs) / spanMs).clamp(0.0, 1.0);

        final readingY =
            metrics.tops[current] + progressInSentence * metrics.heights[current];
        final translateY = constraints.maxHeight / 2 - readingY;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // Dời bằng Transform chứ không bằng `top`: đây là việc của lúc
                // vẽ, không kéo theo một vòng layout mỗi frame.
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: _sentences,
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
