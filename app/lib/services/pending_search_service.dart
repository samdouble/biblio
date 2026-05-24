import 'package:http/http.dart' as http;

import 'package:tsundoku/config/env.dart';
import 'package:tsundoku/db/db.dart';

Future<int> processPendingSearches() async {
  final apiUrl = apiBaseUrl;
  if (apiUrl.isEmpty) {
    return 0;
  }

  final pending = await getPendingIsbnSearches();
  var synced = 0;

  for (final row in pending) {
    final id = row['id'] as int;
    final isbn = row['isbn'] as String;
    final url = '$apiUrl/books/getBookByIsbn?isbn=$isbn';
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
