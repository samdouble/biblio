import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  try {
    await db.execute('ALTER TABLE books ADD COLUMN thumbnail_url TEXT');
  } catch (_) {
  }
}
