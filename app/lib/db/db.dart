import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:biblio/db/migrations/migration_001_books.dart' as m1;
import 'package:biblio/db/migrations/migration_002_library_tables.dart' as m2;
import 'package:biblio/db/migrations/migration_003_pending_search.dart' as m3;
import 'package:biblio/db/migrations/migration_004_books_isbn_thumbnail.dart' as m4;
import 'package:biblio/db/migrations/migration_005_books_thumbnail_url.dart' as m5;
import 'package:biblio/db/migrations/migration_006_library_color.dart' as m6;

const int _dbVersion = 6;

final List<Future<void> Function(Database)> _migrations = [
  m1.run,
  m2.run,
  m3.run,
  m4.run,
  m5.run,
  m6.run,
];

Future<Database> initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = openDatabase(
    join(await getDatabasesPath(), 'biblio_database.db'),
    onCreate: (db, version) async {
      for (final migration in _migrations) {
        await migration(db);
      }
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      for (var i = oldVersion; i < newVersion; i++) {
        await _migrations[i](db);
      }
    },
    version: _dbVersion,
  );
  return database;
}

Future<Database> Function() databaseResolver = initDatabase;

Future<void> addPendingIsbnSearch(String isbn) async {
  final db = await databaseResolver();
  await db.insert(
    'pending_isbn_searches',
    {'isbn': isbn, 'created_at': DateTime.now().toUtc().millisecondsSinceEpoch},
  );
}

Future<List<Map<String, dynamic>>> getPendingIsbnSearches() async {
  final db = await databaseResolver();
  return db.query(
    'pending_isbn_searches',
    orderBy: 'created_at ASC',
  );
}

Future<void> removePendingIsbnSearch(int id) async {
  final db = await databaseResolver();
  await db.delete('pending_isbn_searches', where: 'id = ?', whereArgs: [id]);
}
