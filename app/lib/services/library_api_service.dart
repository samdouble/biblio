import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:biblio/models/library.dart';

class CreateLibraryResult {
  CreateLibraryResult({this.library, this.error});
  final Library? library;
  final String? error;
}

class GetLibrariesResult {
  GetLibrariesResult({this.libraries = const [], this.error});
  final List<Library> libraries;
  final String? error;
}

Future<CreateLibraryResult> createLibrary(String userId, String name, {int? color}) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) return CreateLibraryResult(error: 'API not configured');

  final url = Uri.parse('$baseUrl/libraries/createLibrary');
  final body = <String, dynamic>{'userId': userId, 'name': name};
  if (color != null) body['color'] = color;
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
      return CreateLibraryResult(error: err?.toString() ?? 'Failed to create library');
    } catch (_) {
      return CreateLibraryResult(error: 'Failed to create library');
    }
  }

  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final b = body?['body'];
    if (b is Map && b['library'] is Map) {
      final lib = b['library'] as Map;
      final id = lib['id'] as String?;
      final nameStr = lib['name'] as String?;
      final colorVal = lib['color'];
      final color = colorVal is int ? colorVal : null;
      if (id != null && nameStr != null) {
        return CreateLibraryResult(library: Library(id: id, name: nameStr, color: color));
      }
    }
    return CreateLibraryResult(error: 'Invalid response');
  } catch (_) {
    return CreateLibraryResult(error: 'Invalid response');
  }
}

Future<GetLibrariesResult> getLibraries(String userId) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) return GetLibrariesResult(error: 'API not configured');

  final url = Uri.parse('$baseUrl/libraries/getLibraries');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'userId': userId}),
  );

  if (response.statusCode != 200) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
      return GetLibrariesResult(error: err?.toString() ?? 'Failed to load libraries');
    } catch (_) {
      return GetLibrariesResult(error: 'Failed to load libraries');
    }
  }

  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final list = body?['body'] is Map ? (body!['body'] as Map)['libraries'] : null;
    if (list is List) {
      final libraries = <Library>[
        for (final e in list)
          if (e is Map && e['id'] != null && e['name'] != null) ...[
            Library(
              id: e['id'] as String,
              name: e['name'] as String,
              color: e['color'] is int ? e['color'] as int : null,
            ),
          ],
      ];
      return GetLibrariesResult(libraries: libraries);
    }
    return GetLibrariesResult(libraries: []);
  } catch (_) {
    return GetLibrariesResult(error: 'Invalid response');
  }
}

Future<String?> updateLibrary(String userId, String libraryId, String name, {int? color}) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) return 'API not configured';

  final url = Uri.parse('$baseUrl/libraries/updateLibrary');
  final body = <String, dynamic>{
    'userId': userId,
    'libraryId': libraryId,
    'name': name,
  };
  body['color'] = color;
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) return 'Failed to update library';
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
    return err as String?;
  } catch (_) {
    return null;
  }
}

Future<String?> deleteLibraryApi(String userId, String libraryId) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) return 'API not configured';

  final url = Uri.parse('$baseUrl/libraries/deleteLibrary');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'userId': userId, 'libraryId': libraryId}),
  );

  if (response.statusCode != 200) return 'Failed to delete library';
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
    return err as String?;
  } catch (_) {
    return null;
  }
}

Future<List<String>?> getLibraryBooks(String userId, String libraryId) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) return null;

  final url = Uri.parse('$baseUrl/libraries/getLibraryBooks');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'userId': userId, 'libraryId': libraryId}),
  );

  if (response.statusCode != 200) return null;
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final list = body?['body'] is Map ? (body!['body'] as Map)['bookIds'] : null;
    if (list is List) {
      return [for (final e in list) if (e is String) e];
    }
    return <String>[];
  } catch (_) {
    return null;
  }
}

Future<String?> setLibraryBooks(String userId, String libraryId, List<String> bookIds) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) return 'API not configured';

  final url = Uri.parse('$baseUrl/libraries/setLibraryBooks');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'userId': userId, 'libraryId': libraryId, 'bookIds': bookIds}),
  );

  if (response.statusCode != 200) return 'Failed to sync library books';
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
    return err as String?;
  } catch (_) {
    return null;
  }
}
