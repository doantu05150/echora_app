import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../features/player/display_mode.dart';
import 'app_database.dart';

@immutable
class PassageProgress {
  const PassageProgress({
    required this.passageId,
    required this.positionMs,
    required this.lastOpenedAt,
    this.completedAt,
  });

  final String passageId;
  final int positionMs;
  final DateTime lastOpenedAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  factory PassageProgress.fromRow(Map<String, Object?> row) => PassageProgress(
    passageId: row['passageId']! as String,
    positionMs: row['positionMs']! as int,
    lastOpenedAt: DateTime.fromMillisecondsSinceEpoch(
      row['lastOpenedAt']! as int,
    ),
    completedAt: row['completedAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['completedAt']! as int),
  );
}

@immutable
class PracticeSession {
  const PracticeSession({
    required this.passageId,
    required this.startedAt,
    required this.durationSec,
    required this.wpm,
    required this.displayMode,
  });

  final String passageId;
  final DateTime startedAt;
  final int durationSec;
  final int wpm;
  final DisplayMode displayMode;

  factory PracticeSession.fromRow(Map<String, Object?> row) => PracticeSession(
    passageId: row['passageId']! as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(row['startedAt']! as int),
    durationSec: row['durationSec']! as int,
    wpm: row['wpm']! as int,
    displayMode: DisplayMode.fromStorage(row['displayMode'] as String?),
  );
}

@immutable
class PracticeStats {
  const PracticeStats({
    required this.streakDays,
    required this.totalSeconds,
    required this.passageCount,
  });

  final int streakDays;
  final int totalSeconds;
  final int passageCount;

  int get totalMinutes => totalSeconds ~/ 60;
}

class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  Future<Set<String>> bookmarkedIds() async {
    final db = await _db.database;
    final rows = await db.query(Tables.bookmark, orderBy: 'createdAt DESC');
    return {for (final row in rows) row['passageId']! as String};
  }

  Future<void> toggleBookmark(String passageId) async {
    final db = await _db.database;
    final removed = await db.delete(
      Tables.bookmark,
      where: 'passageId = ?',
      whereArgs: [passageId],
    );
    if (removed == 0) {
      await db.insert(Tables.bookmark, {
        'passageId': passageId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<Map<String, PassageProgress>> allProgress() async {
    final db = await _db.database;
    final rows = await db.query(Tables.progress);
    return {
      for (final row in rows)
        row['passageId']! as String: PassageProgress.fromRow(row),
    };
  }

  Future<PassageProgress?> progressOf(String passageId) async {
    final db = await _db.database;
    final rows = await db.query(
      Tables.progress,
      where: 'passageId = ?',
      whereArgs: [passageId],
      limit: 1,
    );
    return rows.isEmpty ? null : PassageProgress.fromRow(rows.first);
  }

  /// Bài gần nhất mở ra mà chưa học xong, dùng cho card "đang dở" ở Home.
  Future<PassageProgress?> mostRecentUnfinished() async {
    final db = await _db.database;
    final rows = await db.query(
      Tables.progress,
      where: 'completedAt IS NULL AND positionMs > 0',
      orderBy: 'lastOpenedAt DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : PassageProgress.fromRow(rows.first);
  }

  Future<void> savePosition(
    String passageId,
    int positionMs, {
    bool completed = false,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(Tables.progress, {
      'passageId': passageId,
      'positionMs': positionMs,
      'completedAt': completed ? now : null,
      'lastOpenedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> recordSession(PracticeSession session) async {
    final db = await _db.database;
    await db.insert(Tables.session, {
      'passageId': session.passageId,
      'startedAt': session.startedAt.millisecondsSinceEpoch,
      'durationSec': session.durationSec,
      'wpm': session.wpm,
      'displayMode': session.displayMode.storageValue,
    });
  }

  Future<PracticeStats> stats() async {
    final db = await _db.database;

    final totals = await db.rawQuery(
      'SELECT COALESCE(SUM(durationSec), 0) AS seconds, '
      'COUNT(DISTINCT passageId) AS passages FROM ${Tables.session}',
    );
    final days = await db.rawQuery(
      "SELECT DISTINCT date(startedAt / 1000, 'unixepoch', 'localtime') AS day "
      'FROM ${Tables.session} ORDER BY day DESC',
    );

    return PracticeStats(
      totalSeconds: totals.first['seconds']! as int,
      passageCount: totals.first['passages']! as int,
      streakDays: _streakFrom(
        days.map((row) => DateTime.parse(row['day']! as String)).toList(),
      ),
    );
  }

  /// Số ngày liên tiếp gần nhất có ít nhất một buổi luyện. Chuỗi vẫn còn nếu
  /// hôm nay chưa luyện nhưng hôm qua có — người học chưa mất chuỗi giữa ngày.
  static int _streakFrom(List<DateTime> descendingDays) {
    if (descendingDays.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gapToLatest = today.difference(descendingDays.first).inDays;
    if (gapToLatest > 1) return 0;

    var streak = 1;
    for (var i = 1; i < descendingDays.length; i++) {
      final gap = descendingDays[i - 1].difference(descendingDays[i]).inDays;
      if (gap != 1) break;
      streak++;
    }
    return streak;
  }

  Future<List<PracticeSession>> recentSessions({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      Tables.session,
      orderBy: 'startedAt DESC',
      limit: limit,
    );
    return rows.map(PracticeSession.fromRow).toList();
  }
}
