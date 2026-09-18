import 'package:flutter/material.dart';

import '../../../ui/theme/app_theme.dart';
import '../playback/playback_timeline.dart';

const _transition = Duration(milliseconds: 250);

/// Text đứng yên, snap sang câu kế tiếp khi hết thời lượng câu đó.
/// Câu trước và câu sau hiện mờ để người học biết mình đang ở đâu trong bài.
class LineTextView extends StatelessWidget {
  const LineTextView({
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
    final index = timeline.sentenceIndexAt(elapsedMs);
    final sentences = timeline.sentences;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedSwitcher(
        duration: _transition,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(index),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (index > 0)
              _Neighbour(
                text: sentences[index - 1].text,
                style: style,
                color: colors.ink.withValues(alpha: 0.26),
              ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.lgPlus),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.mdPlus,
              ),
              decoration: BoxDecoration(
                color: accent.tint,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border(
                  left: BorderSide(width: 3, color: accent.base),
                ),
              ),
              child: Text(
                sentences[index].text,
                textAlign: TextAlign.center,
                style: style.copyWith(color: colors.ink),
              ),
            ),
            if (index < sentences.length - 1)
              _Neighbour(
                text: sentences[index + 1].text,
                style: style,
                color: colors.ink.withValues(alpha: 0.45),
              ),
          ],
        ),
      ),
    );
  }
}

class _Neighbour extends StatelessWidget {
  const _Neighbour({
    required this.text,
    required this.style,
    required this.color,
  });

  final String text;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(color: color, fontSize: style.fontSize! * 0.72),
    );
  }
}
