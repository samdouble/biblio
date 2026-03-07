import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:biblio/db/db.dart';
import 'package:biblio/db/migrations/migration_001_books.dart' as m1;
import 'package:biblio/db/migrations/migration_002_library_tables.dart' as m2;
import 'package:biblio/db/migrations/migration_003_pending_search.dart' as m3;
import 'package:biblio/db/migrations/migration_004_books_isbn_thumbnail.dart' as m4;
import 'package:biblio/db/migrations/migration_005_books_thumbnail_url.dart' as m5;
import 'package:biblio/models/library.dart';

void main() {
  late dynamic testDb;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await m1.run(testDb);
    await m2.run(testDb);
    await m3.run(testDb);
    await m4.run(testDb);
    await m5.run(testDb);
    databaseResolver = () async => testDb;
  });

  tearDown(() async {
    databaseResolver = initDatabase;
    await testDb.close();
  });

  group('pushLibraryBooksToServer', () {
    test('calls setLibraryBooks for each local library with correct book IDs', () async {
      await insertLibrary(const Library(id: 'lib-1', name: 'Lib One'));
      await insertLibrary(const Library(id: 'lib-2', name: 'Lib Two'));
      await testDb.insert('books', {
        'id': 'book-a',
        'title': 'A',
        'author': 'X',
        'isbn': '',
        'thumbnail_url': '',
      });
      await testDb.insert('books', {
        'id': 'book-b',
        'title': 'B',
        'author': 'Y',
        'isbn': '',
        'thumbnail_url': '',
      });
      await addBookToLibrary('lib-1', 'book-a');
      await addBookToLibrary('lib-2', 'book-a');
      await addBookToLibrary('lib-2', 'book-b');

      final calls = <(String, List<String>)>[];
      await pushLibraryBooksToServer(
        'user-1',
        (libraryId, bookIds) async {
          calls.add((libraryId, List.from(bookIds)));
          return null;
        },
      );

      expect(calls.length, 2);
      final byLib = {for (final c in calls) c.$1: c.$2};
      expect(byLib['lib-1'], ['book-a']);
      expect(byLib['lib-2']!.toSet(), {'book-a', 'book-b'});
    });

    test('pushes empty book list for library with no books', () async {
      await insertLibrary(const Library(id: 'empty-lib', name: 'Empty'));

      final calls = <(String, List<String>)>[];
      await pushLibraryBooksToServer(
        'user-1',
        (libraryId, bookIds) async {
          calls.add((libraryId, bookIds));
          return null;
        },
      );

      expect(calls.length, 1);
      expect(calls.first.$1, 'empty-lib');
      expect(calls.first.$2, isEmpty);
    });

    test('calls setLibraryBooks for all libraries even when one returns error', () async {
      await insertLibrary(const Library(id: 'lib-1', name: 'One'));
      await insertLibrary(const Library(id: 'lib-2', name: 'Two'));

      final calls = <String>[];
      await pushLibraryBooksToServer(
        'user-1',
        (libraryId, bookIds) async {
          calls.add(libraryId);
          if (libraryId == 'lib-1') return 'Network error';
          return null;
        },
      );

      expect(calls.length, 2);
      expect(calls.toSet(), {'lib-1', 'lib-2'});
    });
  });
}
