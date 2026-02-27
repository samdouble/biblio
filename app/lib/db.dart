import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const int _dbVersion = 2;

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
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createLibraryTables(db);
      }
    },
    version: _dbVersion,
  );
  return database;
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
