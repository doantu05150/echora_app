import 'package:echora/data/local/app_database.dart';
import 'package:echora/data/local/progress_repository.dart';
import 'package:echora/features/player/display_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late ProgressRepository repository;

  setUp(() {
    db = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = ProgressRepository(db);
  });

  tearDown(() => db.close());

  test('bookmarking the same passage twice removes it', () async {
    await repository.toggleBookmark('daily-life-01');
    expect(await repository.bookmarkedIds(), {'daily-life-01'});

    await repository.toggleBookmark('daily-life-01');
    expect(await repository.bookmarkedIds(), isEmpty);
  });

  test('saving a position twice updates rather than duplicates', () async {
    await repository.savePosition('daily-life-01', 1000);
    await repository.savePosition('daily-life-01', 4000);

    final progress = await repository.progressOf('daily-life-01');
    expect(progress!.positionMs, 4000);
    expect((await repository.allProgress()).length, 1);
  });

  test('the resumable passage is the latest unfinished one', () async {
    await repository.savePosition('daily-life-01', 5000);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.savePosition('daily-life-02', 3000);

    expect((await repository.mostRecentUnfinished())!.passageId, 'daily-life-02');
  });

  test('a finished passage is not offered for resuming', () async {
    await repository.savePosition('daily-life-01', 9000, completed: true);

    expect(await repository.mostRecentUnfinished(), isNull);
    expect((await repository.progressOf('daily-life-01'))!.isCompleted, isTrue);
  });

  test('a passage opened but never played is not offered either', () async {
    await repository.savePosition('daily-life-01', 0);

    expect(await repository.mostRecentUnfinished(), isNull);
  });

  Future<void> recordOn(DateTime day) => repository.recordSession(
    PracticeSession(
      passageId: 'daily-life-01',
      startedAt: day,
      durationSec: 180,
      wpm: 90,
      displayMode: DisplayMode.scroll,
    ),
  );

  group('stats', () {
    test('are zero with no sessions', () async {
      final stats = await repository.stats();
      expect(stats.streakDays, 0);
      expect(stats.totalMinutes, 0);
      expect(stats.passageCount, 0);
    });

    test('count minutes and distinct passages', () async {
      final now = DateTime.now();
      await recordOn(now);
      await recordOn(now);
      await repository.recordSession(
        PracticeSession(
          passageId: 'business-01',
          startedAt: now,
          durationSec: 120,
          wpm: 110,
          displayMode: DisplayMode.line,
        ),
      );

      final stats = await repository.stats();
      expect(stats.totalMinutes, 8);
      expect(stats.passageCount, 2);
    });

    test('streak counts consecutive days back from today', () async {
      final today = DateTime.now();
      for (var i = 0; i < 3; i++) {
        await recordOn(today.subtract(Duration(days: i)));
      }

      expect((await repository.stats()).streakDays, 3);
    });

    test('a missing day breaks the streak', () async {
      final today = DateTime.now();
      await recordOn(today);
      await recordOn(today.subtract(const Duration(days: 2)));

      expect((await repository.stats()).streakDays, 1);
    });

    test('yesterday still counts so the day is not lost mid-way', () async {
      await recordOn(DateTime.now().subtract(const Duration(days: 1)));

      expect((await repository.stats()).streakDays, 1);
    });

    test('a long gap ends the streak entirely', () async {
      await recordOn(DateTime.now().subtract(const Duration(days: 5)));

      expect((await repository.stats()).streakDays, 0);
    });
  });

  test('sessions come back newest first', () async {
    final now = DateTime(2026, 3, 1, 8);
    for (var i = 0; i < 3; i++) {
      await repository.recordSession(
        PracticeSession(
          passageId: 'daily-life-0$i',
          startedAt: now.add(Duration(days: i)),
          durationSec: 120,
          wpm: 90,
          displayMode: DisplayMode.scroll,
        ),
      );
    }

    final sessions = await repository.recentSessions();
    expect(sessions.map((s) => s.passageId), [
      'daily-life-02',
      'daily-life-01',
      'daily-life-00',
    ]);
    expect(sessions.first.displayMode, DisplayMode.scroll);
  });
}
