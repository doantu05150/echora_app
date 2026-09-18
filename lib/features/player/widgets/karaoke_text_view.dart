import 'package:flutter/material.dart';

import '../../../ui/theme/app_theme.dart';
import '../playback/playback_timeline.dart';

/// Câu đứng yên, highlight chạy theo từng từ. Từ đã đọc đổi sang màu topic,
/// từ chưa tới giữ màu chữ mờ.
class KaraokeTextView extends StatelessWidget {
  const KaraokeTextView({
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
    final colors = context.colors;
    final style = AppTypography.practice(fontSizeSp);
    final sentence = timeline.sentences[timeline.sentenceIndexAt(elapsedMs)];
    final currentWord = timeline.wordIndexInSentenceAt(elapsedMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < sentence.words.length; i++)
                TextSpan(
                  text: i == sentence.words.length - 1
                      ? sentence.words[i].text
                      : '${sentence.words[i].text} ',
                  style: style.copyWith(
                    color: switch (i.compareTo(currentWord)) {
                      < 0 => accent.base,
                      0 => colors.ink,
                      _ => colors.ink.withValues(alpha: 0.3),
                    },
                    backgroundColor: i == currentWord ? accent.tint : null,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
