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

  group('library sync (create while logged out, then log in and sync)', () {
    test('local-only library is preserved and pushed to server on sync', () async {
      const localLibrary = Library(id: 'local-uuid-1', name: 'My Offline Library');
      await insertLibrary(localLibrary);

      List<Library> libraries = await fetchLibraries();
      expect(libraries, hasLength(1));
      expect(libraries.first.id, 'local-uuid-1');
      expect(libraries.first.name, 'My Offline Library');

      await syncLibrariesWithServer(
        [],
        (name) async => (
          library: Library(id: 'server-uuid-from-mongo', name: name),
          error: null,
        ),
      );

      libraries = await fetchLibraries();
      expect(libraries, hasLength(1));
      expect(libraries.first.id, 'server-uuid-from-mongo');
      expect(libraries.first.name, 'My Offline Library');
    });

    test('library_books are re-linked to server id after push', () async {
      const localLibrary = Library(id: 'local-lib', name: 'Offline Lib');
      await insertLibrary(localLibrary);
      await testDb.insert('books', {
        'id': 'book-1',
        'title': 'A Book',
        'author': 'Author',
        'isbn': '',
        'thumbnail_url': '',
      });
      await addBookToLibrary('local-lib', 'book-1');

      expect(await fetchBookCountInLibrary('local-lib'), 1);

      await syncLibrariesWithServer(
        [],
        (name) async => (
          library: Library(id: 'server-lib', name: name),
          error: null,
        ),
      );

      expect(await fetchBookCountInLibrary('server-lib'), 1);
      expect(await fetchBookCountInLibrary('local-lib'), 0);
    });

    test('server libraries are merged and local-only are pushed', () async {
      await insertLibrary(const Library(id: 'local-only', name: 'Created offline'));
      await syncLibrariesWithServer(
        [const Library(id: 'on-server', name: 'From MongoDB')],
        (name) async => (
          library: Library(id: 'pushed-$name', name: name),
          error: null,
        ),
      );

      final libraries = await fetchLibraries();
      expect(libraries.length, 2);
      final ids = libraries.map((l) => l.id).toSet();
      expect(ids, contains('on-server'));
      expect(ids, contains('pushed-Created offline'));
    });
  });
}
