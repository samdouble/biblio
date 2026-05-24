import 'package:sqflite/sqflite.dart';

import 'package:tsunbooku/db/db.dart';
import 'package:tsunbooku/models/book.dart';
import 'package:tsunbooku/models/library.dart';
import 'package:tsunbooku/services/library_api_service.dart';

class AccountSyncResult {
  const AccountSyncResult({required this.success, this.error});
  final bool success;
  final String? error;
}

Future<void> mergeLibraryBooksFromServer(
  String libraryId,
  List<LibraryBookAssociation> serverAssociations,
) async {
  final db = await databaseResolver();
  for (final assoc in serverAssociations) {
    if (assoc.hasMetadata) {
      await insertBook(
        Book(
          id: assoc.bookId,
          title: assoc.title,
          author: assoc.author,
          isbn: assoc.isbn,
          thumbnailUrl: assoc.thumbnailUrl,
        ),
      );
    } else {
      final existing = await db.query(
        'books',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [assoc.bookId],
        limit: 1,
      );
      if (existing.isEmpty) {
        await insertBook(
          Book(
            id: assoc.bookId,
            title: '',
            author: '',
            isbn: '',
            thumbnailUrl: '',
          ),
        );
      }
    }
    await db.insert(
      'library_books',
      {
        'library_id': libraryId,
        'book_id': assoc.bookId,
        'added_at': assoc.addedAt.toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

Future<bool> pullLibraryBooksFromServer(String token) async {
  final libraries = await fetchLibraries();
  for (final lib in libraries) {
    final associations = await getLibraryBookAssociations(token, lib.id);
    if (associations == null) return false;
    await mergeLibraryBooksFromServer(lib.id, associations);
  }
  return true;
}

Future<AccountSyncResult> syncAccountWithServer(String token) async {
  final result = await getLibraries(token);
  if (result.error != null) {
    return AccountSyncResult(success: false, error: result.error);
  }

  final syncLibsOk = await syncLibrariesWithServer(
    result.libraries,
    (name) async {
      final r = await createLibrary(token, name);
      return (library: r.library, error: r.error);
    },
  );
  if (!syncLibsOk) {
    return AccountSyncResult(success: false, error: 'Failed to sync libraries');
  }

  final pullOk = await pullLibraryBooksFromServer(token);
  if (!pullOk) {
    return AccountSyncResult(success: false, error: 'Failed to pull library books');
  }

  final pushOk = await pushLibraryBooksToServer(
    (libraryId, bookIds) => setLibraryBooks(token, libraryId, bookIds),
  );
  if (!pushOk) {
    return AccountSyncResult(success: false, error: 'Failed to push library books');
  }

  return const AccountSyncResult(success: true);
}
