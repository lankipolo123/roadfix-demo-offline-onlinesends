import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:roadfix/models/report_model.dart';

class SqliteService {
  static final SqliteService instance = SqliteService._internal();
  static Database? _db;

  SqliteService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('roadfix.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        location TEXT,
        latitude REAL,
        longitude REAL,
        imageUrl TEXT,
        reportType TEXT,
        tags TEXT,
        userId TEXT,
        email TEXT,
        fullName TEXT,
        phoneNumber TEXT,
        reportedAt TEXT,
        status TEXT,
        priority TEXT
      )
    ''');
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;

    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;

    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;

    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<ReportModel>> getReports() async {
    final db = await database;

    final result = await db.query('reports', orderBy: 'reviewedAt DESC');

    return result.map((e) => ReportModel.fromMap(e)).toList();
  }

  Stream<List<ReportModel>> watchReports({
    Duration interval = const Duration(seconds: 3),
  }) async* {
    while (true) {
      await Future.delayed(interval);
      yield await getReports();
    }
  }
}
