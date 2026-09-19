import 'package:echora/core/strings.dart';
import 'package:echora/features/player/display_mode.dart';
import 'package:echora/features/player/playback/playback_timeline.dart';
import 'package:echora/features/player/session_settings_sheet.dart';
import 'package:echora/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _pumpSheet(
  WidgetTester tester, {
  required DisplayMode mode,
  required bool voiceAvailable,
  int wpm = kReferenceWpm,
}) async {
  final wpmChanges = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SessionSettingsSheet(
          wpm: wpm,
          preferredDurationMin: 2,
          displayMode: mode,
          fontSizeSp: 29,
          keepScreenOn: false,
          voiceAvailable: voiceAvailable,
          onWpm: wpmChanges.add,
          onDuration: (_) {},
          onDisplayMode: (_) {},
          onFontSize: (_) {},
          onKeepScreenOn: (_) {},
        ),
      ),
    ),
  );
  return wpmChanges;
}

void main() {
  testWidgets('the voice mode is offered when the passage has one', (
    tester,
  ) async {
    await _pumpSheet(tester, mode: DisplayMode.scroll, voiceAvailable: true);

    expect(find.text(Strings.sheetModeVoice), findsOneWidget);
    expect(find.text(Strings.sheetModeVoiceHint), findsOneWidget);
    expect(find.text(Strings.sheetModeVoiceMissing), findsNothing);
  });

  testWidgets('a passage without a voice says so instead of offering it', (
    tester,
  ) async {
    await _pumpSheet(tester, mode: DisplayMode.scroll, voiceAvailable: false);

    expect(find.text(Strings.sheetModeVoice), findsOneWidget);
    expect(find.text(Strings.sheetModeVoiceMissing), findsOneWidget);
    expect(find.text(Strings.sheetModeVoiceHint), findsNothing);
  });

  testWidgets('the speed slider starts at the voice floor in voice mode', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      mode: DisplayMode.voice,
      voiceAvailable: true,
      wpm: kVoiceMinWpm,
    );

    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(slider.min, kVoiceMinWpm.toDouble());
    expect(find.text(Strings.sheetSpeedVoiceHint), findsOneWidget);
    expect(find.text(Strings.sheetPresetSlow), findsNothing);
  });

  testWidgets('the slider covers the full range in the silent modes', (
    tester,
  ) async {
    await _pumpSheet(tester, mode: DisplayMode.scroll, voiceAvailable: true);

    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(slider.min, kMinWpm.toDouble());
    expect(find.text(Strings.sheetSpeedVoiceHint), findsNothing);
    expect(find.text(Strings.sheetPresetSlow), findsOneWidget);
  });

  testWidgets('a voice mode with no rendered voice keeps the full range', (
    tester,
  ) async {
    await _pumpSheet(tester, mode: DisplayMode.voice, voiceAvailable: false);

    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(slider.min, kMinWpm.toDouble());
  });
}
