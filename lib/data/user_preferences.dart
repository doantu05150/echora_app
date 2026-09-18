import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/player/display_mode.dart';
import '../features/player/playback/playback_timeline.dart';

@immutable
class UserPreferences {
  const UserPreferences({
    this.wpm = kReferenceWpm,
    this.preferredDurationMin = 3,
    this.displayMode = DisplayMode.scroll,
    this.fontSizeSp = 29,
    this.keepScreenOn = true,
    this.hapticOnSentence = false,
  });

  final int wpm;
  final int preferredDurationMin;
  final DisplayMode displayMode;
  final double fontSizeSp;
  final bool keepScreenOn;
  final bool hapticOnSentence;

  UserPreferences copyWith({
    int? wpm,
    int? preferredDurationMin,
    DisplayMode? displayMode,
    double? fontSizeSp,
    bool? keepScreenOn,
    bool? hapticOnSentence,
  }) => UserPreferences(
    wpm: wpm ?? this.wpm,
    preferredDurationMin: preferredDurationMin ?? this.preferredDurationMin,
    displayMode: displayMode ?? this.displayMode,
    fontSizeSp: fontSizeSp ?? this.fontSizeSp,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    hapticOnSentence: hapticOnSentence ?? this.hapticOnSentence,
  );
}

/// Chỉ `wpm` được lưu, không lưu hệ số `×` — hệ số luôn tính lại từ WPM.
class PreferencesRepository {
  static const _wpm = 'wpm';
  static const _durationMin = 'preferredDurationMin';
  static const _displayMode = 'displayMode';
  static const _fontSize = 'fontSizeSp';
  static const _keepScreenOn = 'keepScreenOn';
  static const _haptic = 'hapticOnSentence';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<UserPreferences> load() async {
    final prefs = await _prefs;
    const fallback = UserPreferences();
    return UserPreferences(
      wpm: prefs.getInt(_wpm) ?? fallback.wpm,
      preferredDurationMin:
          prefs.getInt(_durationMin) ?? fallback.preferredDurationMin,
      displayMode: DisplayMode.fromStorage(prefs.getString(_displayMode)),
      fontSizeSp: prefs.getDouble(_fontSize) ?? fallback.fontSizeSp,
      keepScreenOn: prefs.getBool(_keepScreenOn) ?? fallback.keepScreenOn,
      hapticOnSentence: prefs.getBool(_haptic) ?? fallback.hapticOnSentence,
    );
  }

  Future<void> save(UserPreferences value) async {
    final prefs = await _prefs;
    await prefs.setInt(_wpm, value.wpm);
    await prefs.setInt(_durationMin, value.preferredDurationMin);
    await prefs.setString(_displayMode, value.displayMode.storageValue);
    await prefs.setDouble(_fontSize, value.fontSizeSp);
    await prefs.setBool(_keepScreenOn, value.keepScreenOn);
    await prefs.setBool(_haptic, value.hapticOnSentence);
  }
}
