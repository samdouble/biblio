import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:biblio/db/migrations/migration_001_books.dart' as m1;
import 'package:biblio/db/migrations/migration_002_library_tables.dart' as m2;
import 'package:biblio/db/migrations/migration_003_pending_search.dart' as m3;
import 'package:biblio/db/migrations/migration_004_books_isbn_thumbnail.dart' as m4;
import 'package:biblio/db/migrations/migration_005_books_thumbnail_url.dart' as m5;
import 'package:biblio/db/migrations/migration_006_library_color.dart' as m6;

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

  group('migration_004_books_isbn_thumbnail', () {
    test('adds isbn and thumbnail_url columns to books', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m4.run(db);

      await db.insert('books', {
        'id': 'b-1',
        'title': 'Title',
        'author': 'Author',
        'isbn': '9780123456789',
        'thumbnail_url': 'https://example.com/cover.jpg',
      });
      final rows = await db.query('books');
      expect(rows, hasLength(1));
      expect(rows.first['isbn'], '9780123456789');
      expect(rows.first['thumbnail_url'], 'https://example.com/cover.jpg');
    });
  });

  group('migration_005_books_thumbnail_url', () {
    test('adds thumbnail_url column when missing (idempotent)', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m5.run(db);

      await db.insert('books', {
        'id': 'b-1',
        'title': 'Title',
        'author': 'Author',
        'thumbnail_url': '',
      });
      final rows = await db.query('books');
      expect(rows, hasLength(1));
      expect(rows.first['thumbnail_url'], '');
    });

    test('does not fail when thumbnail_url already exists', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m4.run(db);
      await m5.run(db);

      final rows = await db.query('books');
      expect(rows, isEmpty);
    });
  });

  group('migration_006_library_color', () {
    test('adds color column to libraries', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m2.run(db);
      await m6.run(db);

      await db.insert('libraries', {'id': 'lib-1', 'name': 'My Lib', 'color': null});
      var rows = await db.query('libraries');
      expect(rows, hasLength(1));
      expect(rows.first['color'], isNull);

      await db.update('libraries', {'color': 0xFF4DB6AC}, where: 'id = ?', whereArgs: ['lib-1']);
      rows = await db.query('libraries');
      expect(rows.first['color'], 0xFF4DB6AC);
    });
  });

  group('migration chain', () {
    test('all migrations run in order without error', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() => db.close());

      await m1.run(db);
      await m2.run(db);
      await m3.run(db);
      await m4.run(db);
      await m5.run(db);
      await m6.run(db);

      final tables = await getTableNames(db);
      expect(tables, containsAll(['books', 'libraries', 'library_books', 'pending_isbn_searches']));

      await db.insert('books', {
        'id': 'b-1',
        'title': 'T',
        'author': 'A',
        'isbn': '',
        'thumbnail_url': '',
      });
      await db.insert('libraries', {'id': 'lib-1', 'name': 'Lib', 'color': null});
      final bookRows = await db.query('books');
      final libRows = await db.query('libraries');
      expect(bookRows.first, containsPair('isbn', ''));
      expect(bookRows.first, containsPair('thumbnail_url', ''));
      expect(libRows.first, containsPair('color', isNull));
    });
  });
}
