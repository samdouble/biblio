import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = openDatabase(
    join(await getDatabasesPath(), 'biblio_database.db'),
    onCreate: (db, version) {
      return db.execute(
        """
          CREATE TABLE books(
            id TEXT PRIMARY KEY,
            title TEXT,
            author TEXT
          )
        """,
      );
    },
    version: 1,
  );
  return database;
}
