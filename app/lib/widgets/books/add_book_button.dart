import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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

        const biblioApiUrl = String.fromEnvironment('BIBLIO_API_URL');
        const digitalOceanWebsecureToken = String.fromEnvironment('DIGITALOCEAN_WEBSECURE_TOKEN');
        final url = '$biblioApiUrl/books/getBookByIsbn?isbn=$isbn';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Require-Whisk-Auth': digitalOceanWebsecureToken,
          },
        );
        if (response.statusCode == 200) {
          print(response.body.toString());
        } else {
          print(response.body.toString());
        }
      },
      child: const Icon(Icons.add),
    );
  }
}
