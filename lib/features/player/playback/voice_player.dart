import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Tách khỏi plugin để test không phải phát audio thật.
abstract interface class VoicePlayer {
  Duration get position;

  Future<void> load(String assetPath);
  Future<void> setSpeed(double speed);
  Future<void> seek(Duration position);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

class JustAudioVoicePlayer implements VoicePlayer {
  JustAudioVoicePlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _sessionReady = false;

  @override
  Duration get position => _player.position;

  @override
  Future<void> load(String assetPath) async {
    if (!_sessionReady) {
      // `speech` để hệ điều hành xử lý đúng khi có cuộc gọi đến hoặc app khác
      // phát nhạc; không có bước này thì tiếng chồng lên nhau.
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _sessionReady = true;
    }
    await _player.setAsset(assetPath);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}

final voicePlayerProvider = Provider<VoicePlayer>((ref) {
  final player = JustAudioVoicePlayer();
  ref.onDispose(player.dispose);
  return player;
});
