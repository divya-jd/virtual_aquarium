import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'settings.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE settings (id INTEGER PRIMARY KEY, fishCount INTEGER, fishSpeed REAL, fishColor TEXT)',
        );
      },
    );
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final db = await database;

    await db.insert(
      'settings',
      settings,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query('settings', limit: 1);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
