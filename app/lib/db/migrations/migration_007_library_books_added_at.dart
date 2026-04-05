import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('ALTER TABLE library_books ADD COLUMN added_at INTEGER');
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.rawUpdate(
    'UPDATE library_books SET added_at = ? WHERE added_at IS NULL',
    [now],
  );
}
