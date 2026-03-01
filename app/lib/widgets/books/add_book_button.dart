import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:biblio/db/db.dart';
import 'package:biblio/models/api_book.dart';
import 'package:biblio/screens/barcode_scanner_page.dart';
import 'package:biblio/screens/book_detail_page.dart';
import 'package:biblio/utils/connectivity.dart';

class FloatingButton extends StatelessWidget {
  const FloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final String? isbn = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
            builder: (context) => const BarcodeScannerPage(),
          ),
        );
        if (isbn == null || isbn.isEmpty) {
          return;
        }

        if (!context.mounted) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        final connectivity = Connectivity();
        final results = await connectivity.checkConnectivity();
        if (!isOnline(results)) {
          await addPendingIsbnSearch(isbn);
          if (!context.mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'You\'re offline. Search saved - we\'ll look it up when you\'re back online.',
              ),
            ),
          );
          return;
        }

        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Looking up book…')),
        );

        final biblioApiUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
        final digitalOceanWebsecureToken =
            dotenv.env['DIGITALOCEAN_WEBSECURE_TOKEN'] ?? '';
        if (biblioApiUrl.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(content: Text('BIBLIO_API_URL is not set in .env')),
          );
          return;
        }
        final url = '$biblioApiUrl/books/getBookByIsbn?isbn=$isbn';
        http.Response? response;
        try {
          response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'X-Require-Whisk-Auth': digitalOceanWebsecureToken,
            },
          );
        } catch (error) {
          if (!context.mounted) {
            return;
          }
          messenger.showSnackBar(
            SnackBar(content: Text('Error: ${error.toString()}')),
          );
          return;
        }

        if (!context.mounted) {
          return;
        }

        if (response.statusCode != 200) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Could not load book (${response.statusCode})'),
            ),
          );
          return;
        }

        final apiBook = parseGetBookByIsbnResponse(response.body);
        if (apiBook == null) {
          messenger.showSnackBar(
            SnackBar(content: Text('Book not found for barcode $isbn')),
          );
          return;
        }

        messenger.hideCurrentSnackBar();
        navigator.push(
          MaterialPageRoute<void>(
            builder: (context) => BookDetailPage(book: apiBook),
          ),
        );
      },
      child: const Icon(Icons.qr_code_scanner),
    );
  }
}
