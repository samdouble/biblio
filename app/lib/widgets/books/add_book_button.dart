import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import 'package:biblio/models/api_book.dart';
import 'package:biblio/screens/book_detail_page.dart';

class FloatingButton extends StatelessWidget {
  const FloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final String? isbn = await SimpleBarcodeScanner.scanBarcode(
          context,
          barcodeAppBar: const BarcodeAppBar(
            appBarTitle: 'Test',
            centerTitle: false,
            enableBackButton: true,
            backButtonIcon: Icon(Icons.arrow_back_ios),
          ),
          isShowFlashIcon: true,
          delayMillis: 500,
          cameraFace: CameraFace.back,
          scanFormat: ScanFormat.ONLY_BARCODE,
        );
        if (isbn == null || isbn.isEmpty) {
          return;
        }

        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Looking up book…')),
        );

        const biblioApiUrl = String.fromEnvironment('BIBLIO_API_URL');
        const digitalOceanWebsecureToken =
            String.fromEnvironment('DIGITALOCEAN_WEBSECURE_TOKEN');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.toString()}')),
          );
          return;
        }

        if (!context.mounted) {
          return;
        }

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load book (${response.statusCode})'),
            ),
          );
          return;
        }

        final apiBook = parseGetBookByIsbnResponse(response.body);
        if (apiBook == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book not found for this barcode')),
          );
          return;
        }

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => BookDetailPage(book: apiBook),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
