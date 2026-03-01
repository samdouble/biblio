import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:biblio/db/migrations/migration_001_books.dart' as m1;
import 'package:biblio/db/migrations/migration_002_library_tables.dart' as m2;
import 'package:biblio/db/migrations/migration_003_pending_search.dart' as m3;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  Future<List<String>> getTableNames(dynamic db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    return [for (final r in rows) r['name'] as String];
  }

  group('migration_001_books', () {
    test('creates books table with expected columns', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);

      final tables = await getTableNames(db);
      expect(tables, contains('books'));

      await db.insert('books', {
        'id': 'id-1',
        'title': 'A Title',
        'author': 'An Author',
      });
      final rows = await db.query('books');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'id-1');
      expect(rows.first['title'], 'A Title');
      expect(rows.first['author'], 'An Author');
    });
  });

  group('migration_002_library_tables', () {
    test('creates libraries and library_books tables', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m2.run(db);

      final tables = await getTableNames(db);
      expect(tables, containsAll(['libraries', 'library_books']));

      await db.insert('books', {'id': 'id-1', 'title': 'Book', 'author': 'Author'});
      await db.insert('libraries', {'id': 'lib-1', 'name': 'My Library'});
      await db.insert('library_books', {'library_id': 'lib-1', 'book_id': 'id-1'});
      final libs = await db.query('libraries');
      final links = await db.query('library_books');
      expect(libs, hasLength(1));
      expect(links, hasLength(1));
    });
  });

  group('migration_003_pending_search', () {
    test('creates pending_isbn_searches table', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m2.run(db);
      await m3.run(db);

      final tables = await getTableNames(db);
      expect(tables, contains('pending_isbn_searches'));

      await db.insert('pending_isbn_searches', {
        'isbn': '9780735619678',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      final rows = await db.query('pending_isbn_searches');
      expect(rows, hasLength(1));
      expect(rows.first['isbn'], '9780735619678');
      expect(rows.first['id'], isNotNull);
    });
  });

  group('migration chain', () {
    test('all migrations run in order without error', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m2.run(db);
      await m3.run(db);

      final tables = await getTableNames(db);
      expect(tables, containsAll(['books', 'libraries', 'library_books', 'pending_isbn_searches']));
    });
  });
}
