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
