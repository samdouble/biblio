import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('ALTER TABLE books ADD COLUMN isbn TEXT');
  await db.execute('ALTER TABLE books ADD COLUMN thumbnail_url TEXT');
}
