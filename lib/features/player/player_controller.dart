import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/screen_wakelock.dart';
import '../../data/models/passage.dart';
import '../../data/models/voice_track.dart';
import '../../data/local/progress_repository.dart';
import '../../data/providers.dart';
import '../../data/user_preferences.dart';
import 'display_mode.dart';
import 'playback/playback_clock.dart';
import 'playback/playback_timeline.dart';
import 'playback/voice_playback.dart';
import 'playback/voice_player.dart';

@immutable
class PlayerState {
  const PlayerState({
    required this.passage,
    required this.timeline,
    required this.preferences,
    this.voiceTrack,
  });

  final Passage passage;
  final PlaybackTimeline timeline;
  final UserPreferences preferences;

  /// null khi bài chưa render giọng đọc mẫu.
  final VoiceTrack? voiceTrack;

  int get wpm => preferences.wpm;
  DisplayMode get displayMode => preferences.displayMode;
  double get fontSizeSp => preferences.fontSizeSp;
  bool get keepScreenOn => preferences.keepScreenOn;

  bool get hasVoice => voiceTrack != null;

  /// Chế độ đọc chỉ thật sự bật khi bài có giọng; thiếu file thì rơi về chạy
  /// chữ im lặng chứ không chặn người học.
  bool get isVoiceMode => displayMode.needsVoice && hasVoice;

  PlayerState copyWith({
    PlaybackTimeline? timeline,
    UserPreferences? preferences,
  }) => PlayerState(
    passage: passage,
    timeline: timeline ?? this.timeline,
    preferences: preferences ?? this.preferences,
    voiceTrack: voiceTrack,
  );
}

class PlayerController extends AsyncNotifier<PlayerState> {
  PlayerController(this.passageId);

  final String passageId;
  final clock = PlaybackClock();
  late final ScreenWakelock _wakelock;
  late final ProgressRepository _progress;
  late final VoicePlayback _voice;

  Timer? _autosave;
  Timer? _driftCheck;
  AppLifecycleListener? _lifecycle;
  DateTime? _playingSince;
  Duration _practised = Duration.zero;

  /// Bản sao state cuối cùng. `onDispose` không được đọc `state` nên lần lưu
  /// cuối lấy số liệu từ đây.
  PlayerState? _latest;

  @override
  Future<PlayerState> build() async {
    _wakelock = ref.read(screenWakelockProvider);
    _progress = ref.read(progressRepositoryProvider);
    _voice = VoicePlayback(ref.read(voicePlayerProvider));
    _lifecycle = AppLifecycleListener(onStateChange: handleAppLifecycleState);
    clock.addListener(_onClockChanged);
    _autosave = Timer.periodic(const Duration(seconds: 5), (_) {
      if (clock.isPlaying) _savePosition();
    });
    _driftCheck = Timer.periodic(const Duration(seconds: 2), (_) {
      final current = _latest;
      if (current == null || !current.isVoiceMode || !clock.isPlaying) return;
      _voice.correctDrift(elapsedMs: clock.elapsedMs, wpm: current.wpm);
    });

    ref.onDispose(() {
      _autosave?.cancel();
      _driftCheck?.cancel();
      _lifecycle?.dispose();
      _voice.release();
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

    final stored = await ref.read(preferencesRepositoryProvider).load();
    final track = await ref.watch(voiceTrackProvider(passageId).future);

    // Chế độ đọc có sàn WPM riêng: nâng luôn giá trị đã lưu để sheet và giọng
    // nói không nói hai con số khác nhau.
    final preferences = track != null && stored.displayMode.needsVoice
        ? stored.copyWith(wpm: math.max(stored.wpm, kVoiceMinWpm))
        : stored;

    final timeline = _timelineFor(passage, track, preferences);
    clock.setTotalMs(timeline.totalMs);
    if (track != null && preferences.displayMode.needsVoice) {
      await _voice.bind(track);
    }

    final saved = await _progress.progressOf(passageId);
    if (saved != null && !saved.isCompleted && saved.positionMs > 0) {
      clock.seekTo(saved.positionMs.clamp(0, timeline.totalMs));
    }

    return _latest = PlayerState(
      passage: passage,
      timeline: timeline,
      preferences: preferences,
      voiceTrack: track,
    );
  }

  static PlaybackTimeline _timelineFor(
    Passage passage,
    VoiceTrack? track,
    UserPreferences preferences,
  ) => track != null && preferences.displayMode.needsVoice
      ? PlaybackTimeline.ofVoice(passage, track, preferences.wpm)
      : PlaybackTimeline.of(passage, preferences.wpm);

  /// Rời app là dừng hẳn, mọi kiểu chạy chữ: không nhìn chữ thì không nhại
  /// theo được, và ở chế độ đọc thì tiếng còn phát ra ngoài app. Quay lại
  /// không tự chạy tiếp — người học tự bấm khi đã sẵn sàng.
  void handleAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) clock.pause();
  }

  PlayerState get _current => state.requireValue;

  void _emit(PlayerState value) {
    _latest = value;
    state = AsyncData(value);
  }

  void _onClockChanged() {
    _syncWakelock();
    _syncVoice();

    if (clock.isPlaying) {
      _playingSince ??= DateTime.now();
    } else {
      _accumulatePractice();
      _savePosition();
    }
  }

  void _syncVoice() {
    final current = _latest;
    if (current == null || !current.isVoiceMode) return;
    _voice.sync(
      playing: clock.isPlaying,
      elapsedMs: clock.elapsedMs,
      wpm: current.wpm,
    );
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
    final target = current.isVoiceMode ? math.max(wpm, kVoiceMinWpm) : wpm;
    if (current.wpm == target) return;
    _rebuild(current, current.preferences.copyWith(wpm: target));
  }

  /// Dựng lại bảng timing rồi dời mốc thời gian sang bảng mới, giữ nguyên vị
  /// trí từ đang đọc. Dùng chung cho đổi WPM và đổi kiểu chạy chữ — hai việc
  /// này đều đổi độ dài bài.
  void _rebuild(PlayerState current, UserPreferences preferences) {
    final wordPosition = current.timeline.wordPositionAt(clock.elapsedMs);
    final timeline = _timelineFor(current.passage, current.voiceTrack, preferences);

    clock.rebase(
      elapsedMs: timeline.msAtWordPosition(wordPosition),
      totalMs: timeline.totalMs,
    );

    _emit(current.copyWith(timeline: timeline, preferences: preferences));
    _persist(preferences);
    _syncVoice();
  }

  void setDisplayMode(DisplayMode mode) {
    final current = _current;
    if (current.displayMode == mode) return;

    final track = current.voiceTrack;
    final entersVoice = mode.needsVoice && track != null;
    final leavesVoice = current.isVoiceMode && !mode.needsVoice;

    if (!entersVoice && !leavesVoice) {
      _updatePreferences((p) => p.copyWith(displayMode: mode));
      return;
    }

    // Vào hoặc ra khỏi chế độ đọc là đổi luôn bảng timing: chế độ đọc dùng mốc
    // đo từ file audio, các chế độ khác tính từ WPM.
    var preferences = current.preferences.copyWith(displayMode: mode);
    if (entersVoice) {
      preferences = preferences.copyWith(
        wpm: math.max(preferences.wpm, kVoiceMinWpm),
      );
    }

    if (entersVoice) {
      _voice.bind(track).then((_) => _syncVoice());
    } else {
      _voice.release();
    }

    _rebuild(current, preferences);
  }

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
