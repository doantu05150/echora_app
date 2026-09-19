import 'package:echora/data/models/voice_track.dart';
import 'package:echora/features/player/playback/voice_playback.dart';
import 'package:echora/features/player/playback/voice_player.dart';
import 'package:flutter_test/flutter_test.dart';

const _track = VoiceTrack(
  passageId: 'voice-01',
  audioAsset: 'assets/audio/voice-01.mp3',
  voice: 'am_michael',
  nativeWpm: 120,
  totalMs: 6000,
  sentences: [VoiceSentence(index: 0, startMs: 0, endMs: 6000)],
);

class _FakePlayer implements VoicePlayer {
  final calls = <String>[];
  Duration _position = Duration.zero;

  @override
  Duration get position => _position;

  set position(Duration value) => _position = value;

  @override
  Future<void> load(String assetPath) async => calls.add('load $assetPath');

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

void main() {
  late _FakePlayer player;
  late VoicePlayback playback;

  setUp(() {
    player = _FakePlayer();
    playback = VoicePlayback(player);
  });

  test('binding loads the asset once', () async {
    await playback.bind(_track);
    await playback.bind(_track);

    expect(player.calls, ['load assets/audio/voice-01.mp3']);
    expect(playback.isBound, isTrue);
  });

  test('nothing is sent to the player before a track is bound', () async {
    await playback.sync(playing: true, elapsedMs: 1000, wpm: 120);
    expect(player.calls, isEmpty);
  });

  test('at the native wpm the audio follows the clock one to one', () async {
    await playback.bind(_track);
    player.calls.clear();

    await playback.sync(playing: true, elapsedMs: 2000, wpm: 120);

    expect(player.calls, ['seek 2000', 'play']);
  });

  test('a faster wpm speeds the audio up and moves it further along', () async {
    await playback.bind(_track);
    player.calls.clear();

    await playback.sync(playing: true, elapsedMs: 2000, wpm: 180);

    expect(player.calls, ['speed 1.5', 'seek 3000', 'play']);
  });

  test('pausing the clock pauses the voice', () async {
    await playback.bind(_track);
    await playback.sync(playing: true, elapsedMs: 0, wpm: 120);
    player.calls.clear();

    await playback.sync(playing: false, elapsedMs: 1200, wpm: 120);

    expect(player.calls, ['seek 1200', 'pause']);
  });

  test('small drift is left alone, large drift is pulled back', () async {
    await playback.bind(_track);
    await playback.sync(playing: true, elapsedMs: 0, wpm: 120);
    player.calls.clear();

    player.position = const Duration(milliseconds: 1100);
    await playback.correctDrift(elapsedMs: 1000, wpm: 120);
    expect(player.calls, isEmpty);

    player.position = const Duration(milliseconds: 1600);
    await playback.correctDrift(elapsedMs: 1000, wpm: 120);
    expect(player.calls, ['seek 1000']);
  });

  test('releasing stops the voice and unbinds the track', () async {
    await playback.bind(_track);
    player.calls.clear();

    await playback.release();

    expect(player.calls, ['pause']);
    expect(playback.isBound, isFalse);
  });
}
