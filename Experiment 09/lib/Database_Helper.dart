import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calculator.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expression TEXT NOT NULL,
        result TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertHistory(String expression, String result) async {
    final db = await instance.database;
    return await db.insert('history', {
      'expression': expression,
      'result': result,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await instance.database;
    return await db.query('history', orderBy: "id DESC");
  }

  // ** DEFINITION OF THE clearHistory() METHOD **
  // This function deletes all rows from the 'history' table, returning the number of rows deleted.
  Future<int> clearHistory() async {
    final db = await instance.database;
    // Calling db.delete('table_name') without a where clause deletes all records.
    return await db.delete('history');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

