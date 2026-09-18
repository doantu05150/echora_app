import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../playback/playback_timeline.dart';

/// Rung nhẹ mỗi khi sang câu mới. Người học nhìn chữ chứ không nhìn đồng hồ,
/// nên một cú chạm giúp bắt nhịp câu kế tiếp mà không phải rời mắt.
class SentenceHaptics extends StatefulWidget {
  const SentenceHaptics({
    super.key,
    required this.timeline,
    required this.elapsedMs,
    required this.enabled,
    required this.child,
  });

  final PlaybackTimeline timeline;
  final int elapsedMs;
  final bool enabled;
  final Widget child;

  @override
  State<SentenceHaptics> createState() => _SentenceHapticsState();
}

class _SentenceHapticsState extends State<SentenceHaptics> {
  late int _sentenceIndex = widget.timeline.sentenceIndexAt(widget.elapsedMs);

  @override
  void didUpdateWidget(SentenceHaptics oldWidget) {
    super.didUpdateWidget(oldWidget);

    final index = widget.timeline.sentenceIndexAt(widget.elapsedMs);
    if (index == _sentenceIndex) return;

    final movedForward = index == _sentenceIndex + 1;
    _sentenceIndex = index;
    // Tua hay đổi tốc độ cũng nhảy index; chỉ rung khi chữ chạy sang câu kế.
    if (widget.enabled && movedForward) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
