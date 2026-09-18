import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/screen_wakelock.dart';
import '../../data/models/passage.dart';
import '../../data/local/progress_repository.dart';
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
  late final ProgressRepository _progress;

  Timer? _autosave;
  DateTime? _playingSince;
  Duration _practised = Duration.zero;

  /// Bản sao state cuối cùng. `onDispose` không được đọc `state` nên lần lưu
  /// cuối lấy số liệu từ đây.
  PlayerState? _latest;

  @override
  Future<PlayerState> build() async {
    _wakelock = ref.read(screenWakelockProvider);
    _progress = ref.read(progressRepositoryProvider);
    clock.addListener(_onClockChanged);
    _autosave = Timer.periodic(const Duration(seconds: 5), (_) {
      if (clock.isPlaying) _savePosition();
    });

    ref.onDispose(() {
      _autosave?.cancel();
      clock.removeListener(_onClockChanged);
      _accumulatePractice();
      _savePosition(notify: false);
      _recordSession();
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

    final saved = await _progress.progressOf(passageId);
    if (saved != null && !saved.isCompleted && saved.positionMs > 0) {
      clock.seekTo(saved.positionMs.clamp(0, timeline.totalMs));
    }

    return _latest = PlayerState(
      passage: passage,
      timeline: timeline,
      preferences: preferences,
    );
  }

  PlayerState get _current => state.requireValue;

  void _emit(PlayerState value) {
    _latest = value;
    state = AsyncData(value);
  }

  void _onClockChanged() {
    _syncWakelock();

    if (clock.isPlaying) {
      _playingSince ??= DateTime.now();
    } else {
      _accumulatePractice();
      _savePosition();
    }
  }

  void _accumulatePractice() {
    final since = _playingSince;
    if (since == null) return;
    _practised += DateTime.now().difference(since);
    _playingSince = null;
  }

  /// `notify: false` khi gọi từ `onDispose` — Riverpod cấm đụng provider khác
  /// trong life-cycle, và lúc đó cũng không còn màn nào cần cập nhật.
  void _savePosition({bool notify = true}) {
    final current = _latest;
    if (current == null) return;

    final elapsed = clock.elapsedMs;
    _progress.savePosition(
      passageId,
      elapsed,
      completed: elapsed >= current.timeline.totalMs,
    );

    if (!notify) return;
    ref.invalidate(progressByPassageProvider);
    ref.invalidate(resumableProgressProvider);
  }

  /// Một buổi luyện quá ngắn không đáng vào lịch sử và làm hỏng chuỗi ngày.
  void _recordSession() {
    final current = _latest;
    if (current == null || _practised.inSeconds < 5) return;

    _progress.recordSession(
      PracticeSession(
        passageId: passageId,
        startedAt: DateTime.now().subtract(_practised),
        durationSec: _practised.inSeconds,
        wpm: current.wpm,
        displayMode: current.displayMode,
      ),
    );
  }

  Future<void> toggleBookmark() async {
    await _progress.toggleBookmark(passageId);
    ref.invalidate(bookmarkedIdsProvider);
  }

  void _syncWakelock() {
    final keepOn = _latest?.keepScreenOn ?? false;
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
    _emit(current.copyWith(timeline: timeline, preferences: preferences));
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
    _emit(_current.copyWith(preferences: preferences));
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
