import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute(
    """
      CREATE TABLE pending_isbn_searches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isbn TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    """,
  );
}
