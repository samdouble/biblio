import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute(
    """
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT,
        author TEXT
      )
    """,
  );
}
