import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

        final biblioApiUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
        final digitalOceanWebsecureToken =
            dotenv.env['DIGITALOCEAN_WEBSECURE_TOKEN'] ?? '';
        if (biblioApiUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
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
      child: const Icon(Icons.qr_code_scanner),
    );
  }
}
