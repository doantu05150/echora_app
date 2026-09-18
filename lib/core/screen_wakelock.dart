import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Tách khỏi platform channel để test không phải gọi plugin thật.
abstract interface class ScreenWakelock {
  Future<void> setEnabled(bool value);
}

class PluginScreenWakelock implements ScreenWakelock {
  @override
  Future<void> setEnabled(bool value) => WakelockPlus.toggle(enable: value);
}

final screenWakelockProvider = Provider<ScreenWakelock>(
  (ref) => PluginScreenWakelock(),
);
