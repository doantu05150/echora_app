import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/screen_wakelock.dart';
import '../../data/models/passage.dart';
import '../../data/providers.dart';
import '../../data/user_preferences.dart';
import 'display_mode.dart';
import 'playback/playback_clock.dart';
import 'playback/playback_timeline.dart';

@immutable
class PlayerState {
  const PlayerState({
    required this.passage,
    required this.timeline,
    required this.preferences,
  });

  final Passage passage;
  final PlaybackTimeline timeline;
  final UserPreferences preferences;

  int get wpm => preferences.wpm;
  DisplayMode get displayMode => preferences.displayMode;
  double get fontSizeSp => preferences.fontSizeSp;
  bool get keepScreenOn => preferences.keepScreenOn;

  PlayerState copyWith({
    PlaybackTimeline? timeline,
    UserPreferences? preferences,
  }) => PlayerState(
    passage: passage,
    timeline: timeline ?? this.timeline,
    preferences: preferences ?? this.preferences,
  );
}

class PlayerController extends AsyncNotifier<PlayerState> {
  PlayerController(this.passageId);

  final String passageId;
  final clock = PlaybackClock();
  late final ScreenWakelock _wakelock;

  @override
  Future<PlayerState> build() async {
    _wakelock = ref.read(screenWakelockProvider);
    clock.addListener(_syncWakelock);
    ref.onDispose(() {
      clock.removeListener(_syncWakelock);
      clock.dispose();
      _wakelock.setEnabled(false);
    });

    final passage = await ref.watch(passageProvider(passageId).future);
    if (passage == null) {
      throw StateError('Không tìm thấy bài $passageId');
    }

    final preferences = await ref.read(preferencesRepositoryProvider).load();
    final timeline = PlaybackTimeline.of(passage, preferences.wpm);
    clock.setTotalMs(timeline.totalMs);

    return PlayerState(
      passage: passage,
      timeline: timeline,
      preferences: preferences,
    );
  }

  PlayerState get _current => state.requireValue;

  void _syncWakelock() {
    final keepOn = state.value?.keepScreenOn ?? false;
    _wakelock.setEnabled(keepOn && clock.isPlaying);
  }

  void _persist(UserPreferences preferences) {
    ref.read(preferencesProvider.notifier).save(preferences);
  }

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

    final preferences = current.preferences.copyWith(wpm: wpm);
    state = AsyncData(
      current.copyWith(timeline: timeline, preferences: preferences),
    );
    _persist(preferences);
  }

  void setDisplayMode(DisplayMode mode) => _updatePreferences(
    (p) => p.copyWith(displayMode: mode),
  );

  void setFontSizeSp(double value) => _updatePreferences(
    (p) => p.copyWith(fontSizeSp: value),
  );

  /// Bộ lọc cho bài kế tiếp, không đụng vào bài đang chạy.
  void setPreferredDurationMin(int value) => _updatePreferences(
    (p) => p.copyWith(preferredDurationMin: value),
  );

  void setKeepScreenOn(bool value) {
    _updatePreferences((p) => p.copyWith(keepScreenOn: value));
    _syncWakelock();
  }

  void _updatePreferences(UserPreferences Function(UserPreferences) transform) {
    final preferences = transform(_current.preferences);
    state = AsyncData(_current.copyWith(preferences: preferences));
    _persist(preferences);
  }

  void togglePlay() => clock.toggle();

  /// Tua theo thời gian rồi kéo về đầu câu — tua vào giữa câu thì không
  /// shadowing được.
  void seekBy(Duration delta) {
    final timeline = _current.timeline;
    final target = clock.elapsedMs + delta.inMilliseconds;
    clock.seekTo(
      timeline.snapToSentenceStart(target.clamp(0, timeline.totalMs)),
    );
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
