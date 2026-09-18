import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/passage.dart';
import '../../data/providers.dart';
import 'display_mode.dart';
import 'playback/playback_clock.dart';
import 'playback/playback_timeline.dart';

@immutable
class PlayerState {
  const PlayerState({
    required this.passage,
    required this.timeline,
    required this.wpm,
    required this.displayMode,
    required this.fontSizeSp,
  });

  final Passage passage;
  final PlaybackTimeline timeline;
  final int wpm;
  final DisplayMode displayMode;
  final double fontSizeSp;

  PlayerState copyWith({
    PlaybackTimeline? timeline,
    int? wpm,
    DisplayMode? displayMode,
    double? fontSizeSp,
  }) => PlayerState(
    passage: passage,
    timeline: timeline ?? this.timeline,
    wpm: wpm ?? this.wpm,
    displayMode: displayMode ?? this.displayMode,
    fontSizeSp: fontSizeSp ?? this.fontSizeSp,
  );
}

class PlayerController extends AsyncNotifier<PlayerState> {
  PlayerController(this.passageId);

  final String passageId;
  final clock = PlaybackClock();

  @override
  Future<PlayerState> build() async {
    ref.onDispose(clock.dispose);

    final passage = await ref.watch(passageProvider(passageId).future);
    if (passage == null) {
      throw StateError('Không tìm thấy bài $passageId');
    }

    const wpm = kReferenceWpm;
    final timeline = PlaybackTimeline.of(passage, wpm);
    clock.setTotalMs(timeline.totalMs);

    return PlayerState(
      passage: passage,
      timeline: timeline,
      wpm: wpm,
      displayMode: DisplayMode.scroll,
      fontSizeSp: 29,
    );
  }

  PlayerState get _current => state.requireValue;

  /// Đổi WPM giữa chừng: giữ nguyên vị trí từ đang đọc, dựng lại bảng timing
  /// rồi dời mốc thời gian sang bảng mới. Tiến độ không được reset.
  void setWpm(int wpm) {
    final current = _current;
    if (current.wpm == wpm) return;

    final wordPosition = current.timeline.wordPositionAt(clock.elapsedMs);
    final timeline = PlaybackTimeline.of(current.passage, wpm);

    clock.rebase(
      elapsedMs: timeline.msAtWordPosition(wordPosition),
      totalMs: timeline.totalMs,
    );
    state = AsyncData(current.copyWith(wpm: wpm, timeline: timeline));
  }

  void setDisplayMode(DisplayMode mode) {
    if (_current.displayMode == mode) return;
    state = AsyncData(_current.copyWith(displayMode: mode));
  }

  void setFontSizeSp(double value) {
    if (_current.fontSizeSp == value) return;
    state = AsyncData(_current.copyWith(fontSizeSp: value));
  }

  void togglePlay() => clock.toggle();

  /// Tua theo thời gian rồi kéo về đầu câu — tua vào giữa câu thì không
  /// shadowing được.
  void seekBy(Duration delta) {
    final timeline = _current.timeline;
    final target = clock.elapsedMs + delta.inMilliseconds;
    clock.seekTo(timeline.snapToSentenceStart(target.clamp(0, timeline.totalMs)));
  }

  void seekToSentence(int index) {
    final sentences = _current.timeline.sentences;
    if (index < 0 || index >= sentences.length) return;
    clock.seekTo(sentences[index].startMs);
  }
}

final playerControllerProvider =
    AsyncNotifierProvider.family<PlayerController, PlayerState, String>(
      PlayerController.new,
      isAutoDispose: true,
    );
