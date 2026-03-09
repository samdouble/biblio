import 'package:sqflite/sqflite.dart';

import 'package:biblio/db/db.dart';
import 'package:biblio/models/book.dart';

class Library {
  final String id;
  final String name;
  /// ARGB color value, or null for transparent (default).
  final int? color;

  const Library({
    required this.id,
    required this.name,
    this.color,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  @override
  String toString() => 'Library{id: $id, name: $name, color: $color}';
}

Future<List<Library>> fetchLibraries() async {
  final db = await databaseResolver();
  final List<Map<String, Object?>> rows = await db.query('libraries');
  return [
    for (final row in rows)
      Library(
        id: row['id'] as String,
        name: row['name'] as String,
        color: row['color'] as int?,
      ),
  ];
}

Future<void> insertLibrary(Library library) async {
  final db = await databaseResolver();
  await db.insert(
    'libraries',
    library.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateLibraryName(String libraryId, String name) async {
  final db = await databaseResolver();
  await db.update(
    'libraries',
    {'name': name},
    where: 'id = ?',
    whereArgs: [libraryId],
  );
}

Future<void> updateLibraryColor(String libraryId, int? color) async {
  final db = await databaseResolver();
  await db.update(
    'libraries',
    {'color': color},
    where: 'id = ?',
    whereArgs: [libraryId],
  );
}

Future<void> deleteLibrary(Library library) async {
  final db = await databaseResolver();
  await db.delete('library_books', where: 'library_id = ?', whereArgs: [library.id]);
  await db.delete('libraries', where: 'id = ?', whereArgs: [library.id]);
}

Future<void> mergeLibrariesFromServer(List<Library> libraries) async {
  final db = await databaseResolver();
  final existing = await db.query('libraries', columns: ['id', 'color']);
  final colorById = {for (final row in existing) row['id'] as String: row['color'] as int?};
  for (final lib in libraries) {
    final preserveColor = colorById[lib.id];
    await db.insert(
      'libraries',
      {
        'id': lib.id,
        'name': lib.name,
        'color': preserveColor ?? lib.color,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

Future<void> replaceLocalLibraryId(String oldId, Library newLibrary) async {
  final db = await databaseResolver();
  final oldRows = await db.query('libraries', columns: ['color'], where: 'id = ?', whereArgs: [oldId]);
  final preservedColor = oldRows.isNotEmpty ? oldRows.first['color'] as int? : null;
  await db.update(
    'library_books',
    {'library_id': newLibrary.id},
    where: 'library_id = ?',
    whereArgs: [oldId],
  );
  await db.delete('libraries', where: 'id = ?', whereArgs: [oldId]);
  await db.insert(
    'libraries',
    {'id': newLibrary.id, 'name': newLibrary.name, 'color': preservedColor ?? newLibrary.color},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<bool> syncLibrariesWithServer(
  List<Library> serverLibraries,
  Future<({Library? library, String? error})> Function(String name) createLibrary,
) async {
  await mergeLibrariesFromServer(serverLibraries);
  final serverIds = serverLibraries.map((l) => l.id).toSet();
  final localLibraries = await fetchLibraries();
  for (final lib in localLibraries) {
    if (serverIds.contains(lib.id)) continue;
    final result = await createLibrary(lib.name);
    if (result.error != null || result.library == null) return false;
    await replaceLocalLibraryId(lib.id, result.library!);
  }
  return true;
}

Future<int> fetchBookCountInLibrary(String libraryId) async {
  final db = await databaseResolver();
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM library_books WHERE library_id = ?',
    [libraryId],
  );
  final count = result.first['count'];
  return (count is int) ? count : (count as num).toInt();
}

Future<List<String>> fetchBookIdsInLibrary(String libraryId) async {
  final db = await databaseResolver();
  final rows = await db.query(
    'library_books',
    columns: ['book_id'],
    where: 'library_id = ?',
    whereArgs: [libraryId],
  );
  return [for (final row in rows) row['book_id'] as String];
}

Future<List<Book>> fetchBooksInLibrary(String libraryId) async {
  final db = await databaseResolver();
  final rows = await db.rawQuery(
    '''
    SELECT b.id, b.title, b.author, b.isbn, b.thumbnail_url
    FROM books b
    INNER JOIN library_books lb ON b.id = lb.book_id
    WHERE lb.library_id = ?
    ORDER BY b.title
    ''',
    [libraryId],
  );
  return [
    for (final row in rows)
      Book(
        id: row['id'] as String,
        title: row['title'] as String,
        author: row['author'] as String,
        isbn: (row['isbn'] as String?) ?? '',
        thumbnailUrl: (row['thumbnail_url'] as String?) ?? '',
      ),
  ];
}

/// Returns all books that appear in at least one library, deduplicated by book id, ordered by title.
Future<List<Book>> fetchBooksFromAllLibraries() async {
  final db = await databaseResolver();
  final rows = await db.rawQuery(
    '''
    SELECT DISTINCT b.id, b.title, b.author, b.isbn, b.thumbnail_url
    FROM books b
    INNER JOIN library_books lb ON b.id = lb.book_id
    ORDER BY b.title
    ''',
  );
  return [
    for (final row in rows)
      Book(
        id: row['id'] as String,
        title: row['title'] as String,
        author: row['author'] as String,
        isbn: (row['isbn'] as String?) ?? '',
        thumbnailUrl: (row['thumbnail_url'] as String?) ?? '',
      ),
  ];
}

Future<void> addBookToLibrary(String libraryId, String bookId) async {
  final db = await databaseResolver();
  await db.insert(
    'library_books',
    {'library_id': libraryId, 'book_id': bookId},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

Future<void> removeBookFromLibrary(String libraryId, String bookId) async {
  final db = await databaseResolver();
  await db.delete(
    'library_books',
    where: 'library_id = ? AND book_id = ?',
    whereArgs: [libraryId, bookId],
  );
}

Future<bool> pushLibraryBooksToServer(
  String userId,
  Future<String?> Function(String libraryId, List<String> bookIds) setLibraryBooks,
) async {
  final localLibraries = await fetchLibraries();
  var anyError = false;
  for (final lib in localLibraries) {
    final bookIds = await fetchBookIdsInLibrary(lib.id);
    final err = await setLibraryBooks(lib.id, bookIds);
    if (err != null) anyError = true;
  }
  return !anyError;
}
