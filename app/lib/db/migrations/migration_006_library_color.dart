import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('ALTER TABLE libraries ADD COLUMN color INTEGER');
}
