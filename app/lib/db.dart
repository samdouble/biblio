import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const int _dbVersion = 3;

Future<Database> initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = openDatabase(
    join(await getDatabasesPath(), 'biblio_database.db'),
    onCreate: (db, version) async {
      await db.execute(
        """
          CREATE TABLE books(
            id TEXT PRIMARY KEY,
            title TEXT,
            author TEXT
          )
        """,
      );
      await _createLibraryTables(db);
      await _createPendingSearchTable(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createLibraryTables(db);
      }
      if (oldVersion < 3) {
        await _createPendingSearchTable(db);
      }
    },
    version: _dbVersion,
  );
  return database;
}

Future<void> _createPendingSearchTable(Database db) async {
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

Future<void> addPendingIsbnSearch(String isbn) async {
  final db = await initDatabase();
  await db.insert(
    'pending_isbn_searches',
    {'isbn': isbn, 'created_at': DateTime.now().toUtc().millisecondsSinceEpoch},
  );
}

Future<List<Map<String, dynamic>>> getPendingIsbnSearches() async {
  final db = await initDatabase();
  return db.query(
    'pending_isbn_searches',
    orderBy: 'created_at ASC',
  );
}

Future<void> removePendingIsbnSearch(int id) async {
  final db = await initDatabase();
  await db.delete('pending_isbn_searches', where: 'id = ?', whereArgs: [id]);
}

Future<void> _createLibraryTables(Database db) async {
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
