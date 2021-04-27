import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

import '../aya.dart';

class DBHelper {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return await sql.openDatabase(path.join(dbPath, 'ayat.db'),
        onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE ayat(id INTEGER primary key autoincrement, aya TEXT not null, date TEXT not null)');
    }, version: 1);
  }

  static Future<void> insert(String table, Aya aya) async {
    final db = await DBHelper.database();
    db.insert(table, aya.toMap());
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table);
  }

  static Future<int> update(String table, Aya aya) async {
    final db = await DBHelper.database();
    return await db
        .update(table, aya.toMap(), where: 'id = ?', whereArgs: [aya.id]);
  }

  static Future<int> delete(String table, int id) async {
    final db = await DBHelper.database();
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
