import 'package:sqflite/sqflite.dart';

import 'package:biblio/db/db.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String thumbnailUrl;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    this.thumbnailUrl = '',
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'thumbnail_url': thumbnailUrl,
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
    for (final m in bookMaps)
      Book(
        id: m['id'] as String,
        title: m['title'] as String,
        author: m['author'] as String,
        isbn: (m['isbn'] as String?) ?? '',
        thumbnailUrl: (m['thumbnail_url'] as String?) ?? '',
      ),
  ];
}

Future<List<Book>> fetchRecentScannedBooks({int limit = 5}) async {
  final db = await initDatabase();
  final List<Map<String, Object?>> rows = await db.query(
    'books',
    where: "COALESCE(isbn, '') != ''",
    orderBy: 'rowid DESC',
    limit: limit,
  );
  return [
    for (final m in rows)
      Book(
        id: m['id'] as String,
        title: m['title'] as String,
        author: m['author'] as String,
        isbn: (m['isbn'] as String?) ?? '',
        thumbnailUrl: (m['thumbnail_url'] as String?) ?? '',
      ),
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
