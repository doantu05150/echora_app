import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract final class Tables {
  static const bookmark = 'bookmark';
  static const progress = 'progress';
  static const session = 'session';
}

class AppDatabase {
  AppDatabase({this.factory, this.path});

  /// Test truyền `databaseFactoryFfi` và `inMemoryDatabasePath` vào đây.
  final DatabaseFactory? factory;
  final String? path;

  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), 'echora.db');

    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${Tables.bookmark} (
              passageId TEXT PRIMARY KEY,
              createdAt INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ${Tables.progress} (
              passageId TEXT PRIMARY KEY,
              positionMs INTEGER NOT NULL,
              completedAt INTEGER,
              lastOpenedAt INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ${Tables.session} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              passageId TEXT NOT NULL,
              startedAt INTEGER NOT NULL,
              durationSec INTEGER NOT NULL,
              wpm INTEGER NOT NULL,
              displayMode TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_session_startedAt '
            'ON ${Tables.session}(startedAt)',
          );
        },
      ),
    );
  }

  Future<void> close() async {
    final db = await _opening;
    await db?.close();
    _opening = null;
  }
}
