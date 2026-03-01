import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute(
    """
      CREATE TABLE libraries(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    """,
  );
  await db.execute(
    """
      CREATE TABLE library_books(
        library_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        PRIMARY KEY (library_id, book_id),
        FOREIGN KEY (library_id) REFERENCES libraries(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    """,
  );
}
