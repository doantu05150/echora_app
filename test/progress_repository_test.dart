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
