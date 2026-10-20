import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _db;
  static String? dbPath;

  static Future<void> _createPersonnel(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS personnel (
        name TEXT PRIMARY KEY NOT NULL,
        field TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    dbPath = p.join(dir.path, 'issue_tracker.db');

    _db = await databaseFactory.openDatabase(
      dbPath!,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE projects (
              name TEXT PRIMARY KEY NOT NULL,
              code TEXT NOT NULL,
              lead TEXT NOT NULL DEFAULT '',
              start_date TEXT,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE issues (
              id TEXT PRIMARY KEY NOT NULL,
              project TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT NOT NULL DEFAULT '',
              module TEXT NOT NULL DEFAULT '',
              platform TEXT NOT NULL DEFAULT '',
              type TEXT NOT NULL DEFAULT '',
              severity TEXT NOT NULL DEFAULT '',
              priority TEXT NOT NULL DEFAULT '',
              status TEXT NOT NULL DEFAULT 'New',
              steps_to_reproduce TEXT NOT NULL DEFAULT '',
              expected_result TEXT NOT NULL DEFAULT '',
              actual_result TEXT NOT NULL DEFAULT '',
              app_version TEXT NOT NULL DEFAULT '',
              device_os TEXT NOT NULL DEFAULT '',
              reported_by TEXT NOT NULL DEFAULT '',
              assigned_to TEXT NOT NULL DEFAULT '',
              date_reported TEXT NOT NULL,
              target_date TEXT,
              date_resolved TEXT,
              fixed_in_version TEXT NOT NULL DEFAULT '',
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await _createPersonnel(db);
          await db.execute(
            'CREATE INDEX idx_issues_project ON issues(project)',
          );
          await db.execute('CREATE INDEX idx_issues_status ON issues(status)');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createPersonnel(db);
          }
        },
      ),
    );
    return _db!;
  }
}
