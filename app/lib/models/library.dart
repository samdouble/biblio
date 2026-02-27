import 'package:sqflite/sqflite.dart';

import 'package:biblio/db.dart';
import 'package:biblio/models/book.dart';

class Library {
  final String id;
  final String name;

  const Library({
    required this.id,
    required this.name,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'Library{id: $id, name: $name}';
}

Future<List<Library>> fetchLibraries() async {
  final db = await initDatabase();
  final List<Map<String, Object?>> rows = await db.query('libraries');
  return [
    for (final {'id': id as String, 'name': name as String} in rows)
      Library(id: id, name: name),
  ];
}

Future<void> insertLibrary(Library library) async {
  final db = await initDatabase();
  await db.insert(
    'libraries',
    library.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> deleteLibrary(Library library) async {
  final db = await initDatabase();
  await db.delete('library_books', where: 'library_id = ?', whereArgs: [library.id]);
  await db.delete('libraries', where: 'id = ?', whereArgs: [library.id]);
}

Future<List<String>> fetchBookIdsInLibrary(String libraryId) async {
  final db = await initDatabase();
  final rows = await db.query(
    'library_books',
    columns: ['book_id'],
    where: 'library_id = ?',
    whereArgs: [libraryId],
  );
  return [for (final row in rows) row['book_id'] as String];
}

Future<List<Book>> fetchBooksInLibrary(String libraryId) async {
  final db = await initDatabase();
  final rows = await db.rawQuery(
    '''
    SELECT b.id, b.title, b.author
    FROM books b
    INNER JOIN library_books lb ON b.id = lb.book_id
    WHERE lb.library_id = ?
    ORDER BY b.title
    ''',
    [libraryId],
  );
  return [
    for (final {'id': id as String, 'title': title as String, 'author': author as String} in rows)
      Book(id: id, title: title, author: author),
  ];
}

Future<void> addBookToLibrary(String libraryId, String bookId) async {
  final db = await initDatabase();
  await db.insert(
    'library_books',
    {'library_id': libraryId, 'book_id': bookId},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

Future<void> removeBookFromLibrary(String libraryId, String bookId) async {
  final db = await initDatabase();
  await db.delete(
    'library_books',
    where: 'library_id = ? AND book_id = ?',
    whereArgs: [libraryId, bookId],
  );
}
