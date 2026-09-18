import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../playback/playback_clock.dart';

/// Lấy nhịp mỗi frame từ [PlaybackClock] khi đang chạy, và rebuild một lần
/// khi clock đổi trạng thái (play / pause / seek). Clock không tự phát tick
/// nên đây là chỗ duy nhất quyết định tần suất vẽ lại.
class ClockBuilder extends StatefulWidget {
  const ClockBuilder({super.key, required this.clock, required this.builder});

  final PlaybackClock clock;
  final Widget Function(BuildContext context, int elapsedMs) builder;

  @override
  State<ClockBuilder> createState() => _ClockBuilderState();
}

class _ClockBuilderState extends State<ClockBuilder>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  @override
  void initState() {
    super.initState();
    widget.clock.addListener(_onClockChanged);
    _syncTicker();
  }

  @override
  void didUpdateWidget(ClockBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock) {
      oldWidget.clock.removeListener(_onClockChanged);
      widget.clock.addListener(_onClockChanged);
      _syncTicker();
    }
  }

  @override
  void dispose() {
    widget.clock.removeListener(_onClockChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (widget.clock.isFinished) {
      widget.clock.finish();
      return;
    }
    setState(() {});
  }

  void _onClockChanged() {
    if (mounted) setState(_syncTicker);
  }

  void _syncTicker() {
    if (widget.clock.isPlaying && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.clock.isPlaying && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.clock.elapsedMs);
}
