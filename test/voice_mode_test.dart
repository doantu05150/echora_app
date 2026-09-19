import 'package:echora/core/screen_wakelock.dart';
import 'package:echora/data/content_repository.dart';
import 'package:echora/data/local/progress_repository.dart';
import 'package:echora/data/models/passage.dart';
import 'package:echora/data/models/topic.dart';
import 'package:echora/data/models/voice_track.dart';
import 'package:echora/data/providers.dart';
import 'package:echora/features/player/display_mode.dart';
import 'package:echora/features/player/playback/playback_timeline.dart';
import 'package:echora/features/player/playback/voice_player.dart';
import 'package:echora/features/player/player_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _passage = Passage(
  id: 'daily-life-01',
  topicId: 'daily-life',
  title: 'A Calm Start',
  level: 'A2',
  durationMin: 2,
  wordCount: 11,
  order: 1,
  body: [
    'My morning starts before the city wakes.',
    'I open the window.',
  ],
);

const _track = VoiceTrack(
  passageId: 'daily-life-01',
  audioAsset: 'assets/audio/daily-life-01.mp3',
  voice: 'am_michael',
  nativeWpm: 100,
  totalMs: 8000,
  sentences: [
    VoiceSentence(index: 0, startMs: 0, endMs: 4200),
    VoiceSentence(index: 1, startMs: 4550, endMs: 7600),
  ],
);

class _FakeRepository implements ContentRepository {
  _FakeRepository({required this.track});

  final VoiceTrack? track;

  @override
  Future<List<Topic>> getTopics() async => const [];

  @override
  Future<List<Passage>> getPassages(String topicId, {int? durationMin}) async =>
      const [_passage];

  @override
  Future<Passage?> getPassage(String id) async =>
      id == _passage.id ? _passage : null;

  @override
  Future<VoiceTrack?> getVoiceTrack(String passageId) async => track;
}

class _FakeProgress implements ProgressRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => switch (invocation.memberName) {
    #progressOf => Future<PassageProgress?>.value(null),
    #bookmarkedIds => Future<Set<String>>.value(const {}),
    #allProgress => Future<Map<String, PassageProgress>>.value(const {}),
    #mostRecentUnfinished => Future<PassageProgress?>.value(null),
    #recentSessions => Future<List<PracticeSession>>.value(const []),
    _ => Future<void>.value(),
  };
}

class _FakeVoicePlayer implements VoicePlayer {
  final calls = <String>[];
  Duration _position = Duration.zero;

  @override
  Duration get position => _position;

  @override
  Future<void> load(String assetPath) async => calls.add('load');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed $speed');

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    calls.add('seek ${position.inMilliseconds}');
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

late _FakeVoicePlayer _player;

Future<PlayerController> _controller({
  VoiceTrack? track = _track,
  DisplayMode mode = DisplayMode.scroll,
  int wpm = kReferenceWpm,
}) async {
  SharedPreferences.setMockInitialValues({
    'wpm': wpm,
    'displayMode': mode.storageValue,
  });
  _player = _FakeVoicePlayer();

  final container = ProviderContainer(
    overrides: [
      contentRepositoryProvider.overrideWithValue(
        _FakeRepository(track: track),
      ),
      screenWakelockProvider.overrideWithValue(_FakeWakelock()),
      progressRepositoryProvider.overrideWithValue(_FakeProgress()),
      voicePlayerProvider.overrideWithValue(_player),
    ],
  );
  addTearDown(container.dispose);

  final provider = playerControllerProvider(_passage.id);
  // Provider là autoDispose: không giữ subscription thì controller bị vứt ngay
  // khi test `await` một nhịp, y như màn hình bị đóng.
  container.listen(provider, (previous, next) {});
  await container.read(provider.future);
  return container.read(provider.notifier);
}

class _FakeWakelock implements ScreenWakelock {
  @override
  Future<void> setEnabled(bool value) async {}
}

void main() {
  // `PlayerController` dựng AppLifecycleListener nên cần binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a passage with a rendered voice exposes it', () async {
    final controller = await _controller();
    expect(controller.state.requireValue.hasVoice, isTrue);
    expect(controller.state.requireValue.isVoiceMode, isFalse);
  });

  test('switching to voice uses the measured timings, not the wpm ones', () async {
    final controller = await _controller(wpm: _track.nativeWpm);
    final before = controller.state.requireValue.timeline;

    controller.setDisplayMode(DisplayMode.voice);
    final after = controller.state.requireValue.timeline;

    expect(before.sentences[1].startMs, isNot(after.sentences[1].startMs));
    expect(after.sentences[0].endMs, 4200);
    expect(after.sentences[1].startMs, 4550);
    expect(after.totalMs, 8000);
  });

  test('entering voice mode lifts a wpm below the voice floor', () async {
    final controller = await _controller(wpm: 60);
    expect(controller.state.requireValue.wpm, 60);

    controller.setDisplayMode(DisplayMode.voice);

    expect(controller.state.requireValue.wpm, kVoiceMinWpm);
  });

  test('the voice floor also holds when the speed is changed later', () async {
    final controller = await _controller(mode: DisplayMode.voice);

    controller.setWpm(50);

    expect(controller.state.requireValue.wpm, kVoiceMinWpm);
  });

  test('leaving voice mode goes back to timings derived from wpm', () async {
    final controller = await _controller(mode: DisplayMode.voice, wpm: 100);
    expect(controller.state.requireValue.timeline.totalMs, 8000);

    controller.setDisplayMode(DisplayMode.scroll);

    expect(controller.state.requireValue.isVoiceMode, isFalse);
    expect(controller.state.requireValue.timeline.totalMs, isNot(8000));
    expect(_player.calls, contains('pause'));
  });

  test('a passage without a voice falls back to silent scrolling', () async {
    final controller = await _controller(track: null, mode: DisplayMode.voice);
    final state = controller.state.requireValue;

    expect(state.hasVoice, isFalse);
    expect(state.isVoiceMode, isFalse);
    expect(_player.calls, isEmpty);
  });

  test('leaving the app stops the voice, not just the text', () async {
    final controller = await _controller(mode: DisplayMode.voice, wpm: 100);
    controller.togglePlay();
    await Future<void>.delayed(Duration.zero);
    _player.calls.clear();

    controller.handleAppLifecycleState(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);

    expect(controller.clock.isPlaying, isFalse);
    expect(_player.calls, contains('pause'));
  });

  test('leaving the app stops the silent modes too', () async {
    final controller = await _controller(mode: DisplayMode.scroll);
    controller.togglePlay();
    expect(controller.clock.isPlaying, isTrue);

    controller.handleAppLifecycleState(AppLifecycleState.paused);

    expect(controller.clock.isPlaying, isFalse);
  });

  test('coming back does not resume on its own', () async {
    final controller = await _controller(mode: DisplayMode.scroll);
    controller.togglePlay();
    controller.handleAppLifecycleState(AppLifecycleState.paused);

    controller.handleAppLifecycleState(AppLifecycleState.resumed);

    expect(controller.clock.isPlaying, isFalse);
  });

  test('playing in voice mode starts the audio at the clock position', () async {
    final controller = await _controller(mode: DisplayMode.voice, wpm: 100);
    _player.calls.clear();

    controller.togglePlay();
    await Future<void>.delayed(Duration.zero);

    expect(_player.calls, contains('play'));
  });
}
