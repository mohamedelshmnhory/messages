import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return await sql.openDatabase(path.join(dbPath, 'ayat.db'),
        onCreate: (db, version) {
      return db.execute('CREATE TABLE ayat(aya TEXT)');
    }, version: 1);
  }

  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    db.insert(table, data);
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table);
  }
}
