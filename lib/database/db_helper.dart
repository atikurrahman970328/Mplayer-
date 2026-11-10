import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mx_player_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // ১. হিস্ট্রি টেবিল (ওয়াচ পজিশন ও রেজ্যুম ট্র্যাক)
    await db.execute('''
      CREATE TABLE playback_history (
        file_path TEXT PRIMARY KEY,
        media_type TEXT NOT NULL,
        last_position_ms INTEGER NOT NULL,
        total_duration_ms INTEGER NOT NULL,
        watched_percentage REAL NOT NULL,
        last_played_timestamp INTEGER NOT NULL
      )
    ''');

    // ২. ফেভারিট টেবিল
    await db.execute('''
      CREATE TABLE favorites (
        file_path TEXT PRIMARY KEY,
        media_type TEXT NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');

    // ৩. প্লেলিস্ট টেবিল
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // ৪. প্লেলিস্ট আইটেমস
    await db.execute('''
      CREATE TABLE playlist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
      )
    ''');

    // ৫. প্রাইভেট ভল্ট টেবিল
    await db.execute('''
      CREATE TABLE private_vault (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_path TEXT NOT NULL,
        vault_path TEXT NOT NULL,
        media_type TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}