import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiBook {
  ApiBook({
    required this.id,
    required this.isbn,
    required this.volumeInfo,
  });

  final String id;
  final String isbn;
  final VolumeInfo volumeInfo;

  factory ApiBook.fromJson(Map<String, dynamic> json) {
    return ApiBook(
      id: json['id'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      volumeInfo: VolumeInfo.fromJson(
        (json['volumeInfo'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class VolumeInfo {
  VolumeInfo({
    this.title = '',
    this.authors = const [],
    this.publisher = '',
    this.publishedDate = '',
    this.description = '',
    this.pageCount = 0,
    this.imageLinks,
  });

  final String title;
  final List<String> authors;
  final String publisher;
  final String publishedDate;
  final String description;
  final int pageCount;
  final ImageLinks? imageLinks;

  factory VolumeInfo.fromJson(Map<String, dynamic> json) {
    final authorsJson = json['authors'];
    return VolumeInfo(
      title: json['title'] as String? ?? '',
      authors: authorsJson is List
          ? List<String>.from(authorsJson.map((e) => e.toString()))
          : [],
      publisher: json['publisher'] as String? ?? '',
      publishedDate: json['publishedDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      imageLinks: json['imageLinks'] != null
          ? ImageLinks.fromJson(
              json['imageLinks'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ImageLinks {
  ImageLinks({
    this.thumbnail = '',
    this.smallThumbnail = '',
  });

  final String thumbnail;
  final String smallThumbnail;

  factory ImageLinks.fromJson(Map<String, dynamic> json) {
    return ImageLinks(
      thumbnail: json['thumbnail'] as String? ?? '',
      smallThumbnail: json['smallThumbnail'] as String? ?? '',
    );
  }
}

ApiBook? parseGetBookByIsbnResponse(String responseBody) {
  try {
    final map = jsonDecode(responseBody) as Map<String, dynamic>?;
    if (map == null) {
      return null;
    }
    final body = map['body'];
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final books = body['books'];
    if (books is! List || books.isEmpty) {
      return null;
    }
    final first = books.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }
    return ApiBook.fromJson(first);
  } catch (_) {
    return null;
  }
}

List<ApiBook> parseSearchBooksResponse(String responseBody) {
  try {
    final map = jsonDecode(responseBody) as Map<String, dynamic>?;
    if (map == null) return [];
    final body = map['body'];
    if (body is! Map<String, dynamic>) return [];
    final books = body['books'];
    if (books is! List) return [];
    final result = <ApiBook>[];
    for (final item in books) {
      if (item is Map<String, dynamic>) {
        result.add(ApiBook.fromJson(item));
      }
    }
    return result;
  } catch (_) {
    return [];
  }
}

Future<List<ApiBook>> searchBooksFromApi(String query, {int limit = 20}) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty || query.trim().isEmpty) return [];

  final url = Uri.parse('$baseUrl/books/searchBooks');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'query': query.trim(), 'limit': limit}),
  );

  if (response.statusCode != 200) return [];
  return parseSearchBooksResponse(response.body);
}

Future<ApiBook?> getBookByIsbn(String isbn) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty || isbn.trim().isEmpty) return null;
  final url = Uri.parse(
    '$baseUrl/books/getBookByIsbn?isbn=${Uri.encodeQueryComponent(isbn.trim())}',
  );
  final response = await http.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode != 200) return null;
  return parseGetBookByIsbnResponse(response.body);
}
