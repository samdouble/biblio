import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:tsundoku/config/env.dart';
import 'package:tsundoku/db/db.dart';
import 'package:tsundoku/models/api_book.dart';
import 'package:tsundoku/models/book.dart';
import 'package:tsundoku/screens/barcode_scanner_page.dart';
import 'package:tsundoku/screens/book_detail_page.dart';
import 'package:tsundoku/utils/connectivity.dart';

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
        final snackBar = SnackBar(content: Text('Looking up book with ISBN $isbn…'));
        messenger.showSnackBar(snackBar);

        final apiUrl = apiBaseUrl;
        if (apiUrl.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('TSUNDOKU_API_URL is not set in .env'),
            ),
          );
          return;
        }
        final url = '$apiUrl/books/getBookByIsbn?isbn=$isbn';
        http.Response? response;
        try {
          response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
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

        final info = apiBook.volumeInfo;
        final thumb = info.imageLinks?.thumbnail.isNotEmpty == true
            ? info.imageLinks!.thumbnail
            : info.imageLinks?.smallThumbnail ?? '';
        await insertBook(Book(
          id: apiBook.id,
          title: info.title.isEmpty ? 'Untitled' : info.title,
          author: info.authors.isEmpty ? '' : info.authors.join(', '),
          isbn: apiBook.isbn,
          thumbnailUrl: thumb,
        ));

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
