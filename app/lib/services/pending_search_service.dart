import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:biblio/db/db.dart';

Future<int> processPendingSearches() async {
  final biblioApiUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (biblioApiUrl.isEmpty) {
    return 0;
  }

  final pending = await getPendingIsbnSearches();
  var synced = 0;

  for (final row in pending) {
    final id = row['id'] as int;
    final isbn = row['isbn'] as String;
    final url = '$biblioApiUrl/books/getBookByIsbn?isbn=$isbn';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        await removePendingIsbnSearch(id);
        synced++;
      }
    } catch (_) {
      // Keep in pending on failure
    }
  }

  return synced;
}
