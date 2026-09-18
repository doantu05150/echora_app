import 'package:flutter/foundation.dart';

/// Nguồn sự thật duy nhất về thời gian đã chạy. Cả ba kiểu chạy chữ
/// (SCROLL / LINE / KARAOKE) đều đọc `elapsedMs` từ đây — viết ba bộ đếm riêng
/// là cách chắc chắn nhất để chúng lệch nhau khi pause hoặc seek.
///
/// Clock không tự phát tick mỗi frame: `elapsedMs` suy ra từ đồng hồ hệ thống
/// nên luôn chính xác dù đọc ở tần suất nào. Renderer tự lấy nhịp bằng Ticker.
/// Listener chỉ được thông báo khi trạng thái đổi (play / pause / seek / total).
class PlaybackClock extends ChangeNotifier {
  PlaybackClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  int _anchorMs = 0;
  DateTime? _startedAt;
  int _totalMs = 0;

  int get totalMs => _totalMs;
  bool get isPlaying => _startedAt != null;

  int get elapsedMs {
    final startedAt = _startedAt;
    final raw = startedAt == null
        ? _anchorMs
        : _anchorMs + _now().difference(startedAt).inMilliseconds;
    return raw.clamp(0, _totalMs);
  }

  bool get isFinished => _totalMs > 0 && elapsedMs >= _totalMs;

  void setTotalMs(int value) {
    if (_totalMs == value) return;
    _totalMs = value;
    if (_anchorMs > value) _anchorMs = value;
    notifyListeners();
  }

  void play() {
    if (_startedAt != null) return;
    if (isFinished) _anchorMs = 0;
    _startedAt = _now();
    notifyListeners();
  }

  void pause() {
    if (_startedAt == null) return;
    _anchorMs = elapsedMs;
    _startedAt = null;
    notifyListeners();
  }

  void toggle() => isPlaying ? pause() : play();

  void seekTo(int ms) {
    _anchorMs = ms.clamp(0, _totalMs);
    if (_startedAt != null) _startedAt = _now();
    notifyListeners();
  }

  /// Dời thời gian mà không đổi trạng thái play — dùng khi đổi WPM giữa chừng,
  /// vị trí từ hiện tại phải giữ nguyên còn mốc thời gian thì đổi.
  void rebase({required int elapsedMs, required int totalMs}) {
    _totalMs = totalMs;
    _anchorMs = elapsedMs.clamp(0, totalMs);
    if (_startedAt != null) _startedAt = _now();
    notifyListeners();
  }

  /// Chốt `elapsedMs` khi chạy tới cuối bài để không trôi quá `totalMs`.
  void finish() {
    _anchorMs = _totalMs;
    _startedAt = null;
    notifyListeners();
  }
}
