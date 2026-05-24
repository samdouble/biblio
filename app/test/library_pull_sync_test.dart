import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tsunbooku/db/db.dart';
import 'package:tsunbooku/db/migrations/migration_001_books.dart' as m1;
import 'package:tsunbooku/db/migrations/migration_002_library_tables.dart' as m2;
import 'package:tsunbooku/db/migrations/migration_003_pending_search.dart' as m3;
import 'package:tsunbooku/db/migrations/migration_004_books_isbn_thumbnail.dart' as m4;
import 'package:tsunbooku/db/migrations/migration_005_books_thumbnail_url.dart' as m5;
import 'package:tsunbooku/db/migrations/migration_006_library_color.dart' as m6;
import 'package:tsunbooku/db/migrations/migration_007_library_books_added_at.dart' as m7;
import 'package:tsunbooku/models/library.dart';
import 'package:tsunbooku/services/library_api_service.dart';
import 'package:tsunbooku/services/library_sync_service.dart';

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
    await m6.run(testDb);
    await m7.run(testDb);
    databaseResolver = () async => testDb;
  });

  tearDown(() async {
    databaseResolver = initDatabase;
    await testDb.close();
  });

  group('mergeLibraryBooksFromServer', () {
    test('inserts book metadata and library membership from server', () async {
      await insertLibrary(const Library(id: 'lib-1', name: 'Reading'));

      await mergeLibraryBooksFromServer(
        'lib-1',
        [
          LibraryBookAssociation(
            bookId: 'book-1',
            addedAt: DateTime.utc(2024, 1, 2),
            isbn: '9780000000001',
            title: 'Cloud Book',
            author: 'Cloud Author',
            thumbnailUrl: 'https://example.com/thumb.jpg',
          ),
        ],
      );

      expect(await fetchBookCountInLibrary('lib-1'), 1);
      final books = await fetchBooksInLibrary('lib-1');
      expect(books.single.title, 'Cloud Book');
      expect(books.single.isbn, '9780000000001');
    });

    test('merges server books without removing local-only memberships', () async {
      await insertLibrary(const Library(id: 'lib-1', name: 'Reading'));
      await testDb.insert('books', {
        'id': 'local-book',
        'title': 'Offline',
        'author': 'Me',
        'isbn': '',
        'thumbnail_url': '',
      });
      await addBookToLibrary('lib-1', 'local-book');

      await mergeLibraryBooksFromServer(
        'lib-1',
        [
          LibraryBookAssociation(
            bookId: 'server-book',
            addedAt: DateTime.utc(2024, 3, 4),
            title: 'From Mongo',
            author: 'Atlas',
          ),
        ],
      );

      final ids = await fetchBookIdsInLibrary('lib-1');
      expect(ids.toSet(), {'local-book', 'server-book'});
    });
  });
}
