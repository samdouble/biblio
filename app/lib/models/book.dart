import 'package:sqflite/sqflite.dart';

import 'package:biblio/db.dart';

class Book {
  final String id;
  final String title;
  final String author;

  const Book({
    required this.id,
    required this.title,
    required this.author,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
    };
  }

  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author}';
  }
}

Future<List<Book>> fetchBooks() async {
  final db = await initDatabase();
  final List<Map<String, Object?>> bookMaps = await db.query('books');
  return [
    for (
      final {
        'id': id as String,
        'title': title as String,
        'author': author as String,
      } in bookMaps)
      Book(id: id, title: title, author: author),
  ];
}

Future<void> insertBook(Book book) async {
  final db = await initDatabase();

  await db.insert(
    'books',
    book.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
