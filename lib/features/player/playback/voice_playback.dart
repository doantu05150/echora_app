import 'dart:async';
import 'dart:math' as math;

import '../../../data/models/voice_track.dart';
import 'voice_player.dart';

/// Lệch tối đa giữa giọng và chữ trước khi tua lại. Nhỏ hơn mức này thì tua
/// gây khựng tiếng mà tai không nghe ra khác biệt.
const int kVoiceDriftToleranceMs = 220;

/// Giữ giọng đọc bám theo `PlaybackClock`. Clock vẫn là nguồn sự thật duy nhất
/// về thời gian — audio chỉ đi theo, nên pause / tua / đổi WPM không cần xử lý
/// riêng cho chế độ đọc.
class VoicePlayback {
  VoicePlayback(this._player);

  final VoicePlayer _player;

  VoiceTrack? _track;
  double _speed = 1;
  bool _playing = false;

  bool get isBound => _track != null;

  Future<void> bind(VoiceTrack track) async {
    if (_track?.audioAsset == track.audioAsset) return;
    _track = track;
    await _player.load(track.audioAsset);
  }

  Future<void> release() async {
    if (_track == null) return;
    _track = null;
    _playing = false;
    await _player.pause();
  }

  /// Gọi mỗi khi clock đổi trạng thái: luôn kéo audio về đúng mốc của chữ.
  Future<void> sync({required bool playing, required int elapsedMs, required int wpm}) =>
      _apply(playing: playing, elapsedMs: elapsedMs, wpm: wpm, force: true);

  /// Gọi định kỳ lúc đang chạy: chỉ tua khi đã trôi quá ngưỡng.
  Future<void> correctDrift({required int elapsedMs, required int wpm}) =>
      _apply(playing: true, elapsedMs: elapsedMs, wpm: wpm, force: false);

  Future<void> _apply({
    required bool playing,
    required int elapsedMs,
    required int wpm,
    required bool force,
  }) async {
    final track = _track;
    if (track == null) return;

    final speed = track.speedAt(wpm);
    if (speed != _speed) {
      _speed = speed;
      await _player.setSpeed(speed);
    }

    final target = (elapsedMs * speed).round();
    final drift = (_player.position.inMilliseconds - target).abs();
    if (force || drift > kVoiceDriftToleranceMs) {
      await _player.seek(Duration(milliseconds: math.max(0, target)));
    }

    if (playing == _playing) return;
    _playing = playing;
    await (playing ? _player.play() : _player.pause());
  }
}
