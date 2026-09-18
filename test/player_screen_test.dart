import 'package:echora/core/screen_wakelock.dart';
import 'package:echora/data/content_repository.dart';
import 'package:echora/data/models/passage.dart';
import 'package:echora/data/models/topic.dart';
import 'package:echora/data/providers.dart';
import 'package:echora/features/player/player_controller.dart';
import 'package:echora/features/player/player_screen.dart';
import 'package:echora/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _topic = Topic(
  id: 'daily-life',
  title: 'Daily Life',
  description: 'Mô tả',
  colorToken: 'clay',
  levelRange: 'A2-B1',
  order: 1,
  comingSoon: false,
);

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

class _FakeWakelock implements ScreenWakelock {
  bool enabled = false;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}

class _FakeRepository implements ContentRepository {
  @override
  Future<List<Topic>> getTopics() async => const [_topic];

  @override
  Future<List<Passage>> getPassages(String topicId, {int? durationMin}) async =>
      const [_passage];

  @override
  Future<Passage?> getPassage(String id) async =>
      id == _passage.id ? _passage : null;
}

late _FakeWakelock _wakelock;

Future<void> _pumpPlayer(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  _wakelock = _FakeWakelock();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(_FakeRepository()),
        screenWakelockProvider.overrideWithValue(_wakelock),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const PlayerScreen(passageId: 'daily-life-01'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the passage, its topic and the reference speed', (
    tester,
  ) async {
    await _pumpPlayer(tester);

    expect(find.text('A Calm Start'), findsOneWidget);
    expect(find.text('Daily Life · Bài 01'), findsOneWidget);
    expect(find.text('1.0×'), findsOneWidget);
    expect(find.text('90 từ/phút'), findsOneWidget);
    expect(find.text(_passage.body.first), findsOneWidget);
  });

  testWidgets('total time comes from wordCount and wpm, not durationMin', (
    tester,
  ) async {
    await _pumpPlayer(tester);

    // 11 words at 90 wpm is 7 seconds, not the 2 minutes in durationMin.
    expect(find.text('00:07'), findsOneWidget);
  });

  testWidgets('the play button toggles to pause', (tester) async {
    await _pumpPlayer(tester);

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('seeking forward snaps to the next sentence start', (
    tester,
  ) async {
    await _pumpPlayer(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerScreen)),
    );
    final controller = container.read(
      playerControllerProvider('daily-life-01').notifier,
    );
    final timeline = container
        .read(playerControllerProvider('daily-life-01'))
        .requireValue
        .timeline;

    controller.seekBy(const Duration(seconds: 10));
    expect(controller.clock.elapsedMs, timeline.sentences.last.startMs);
  });

  testWidgets('the settings sheet applies a speed preset immediately', (
    tester,
  ) async {
    await _pumpPlayer(tester);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt buổi luyện'), findsOneWidget);
    await tester.tap(find.text('Nhanh'));
    await tester.pumpAndSettle();

    // Sheet vẫn mở mà cả sheet lẫn Player phía sau đã đổi số:
    // không phải bấm Áp dụng mới thấy hiệu quả.
    expect(find.text('110 từ/phút'), findsNWidgets(2));

    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(find.text('1.2×'), findsOneWidget);
  });

  testWidgets('the screen stays awake only while playing', (tester) async {
    await _pumpPlayer(tester);
    expect(_wakelock.enabled, isFalse);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(_wakelock.enabled, isTrue);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(_wakelock.enabled, isFalse);
  });

  testWidgets('changing wpm keeps the reading position', (tester) async {
    await _pumpPlayer(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerScreen)),
    );
    final controller = container.read(
      playerControllerProvider('daily-life-01').notifier,
    );

    controller.seekToSentence(1);
    final before = container
        .read(playerControllerProvider('daily-life-01'))
        .requireValue
        .timeline
        .wordPositionAt(controller.clock.elapsedMs);

    controller.setWpm(130);
    await tester.pump();

    final after = container
        .read(playerControllerProvider('daily-life-01'))
        .requireValue
        .timeline
        .wordPositionAt(controller.clock.elapsedMs);

    expect(after, closeTo(before, 0.01));
    expect(find.text('1.4×'), findsOneWidget);
  });
}
