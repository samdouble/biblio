import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FloatingButton extends StatefulWidget {
  const FloatingButton({super.key});

  @override
  State<FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<FloatingButton> {
  static const List<(Color?, Color? background, ShapeBorder?)> customizations = <(Color?, Color?, ShapeBorder?)>[
    (null, null, null),
    (null, Colors.green, null),
    (Colors.white, Colors.green, null),
    (Colors.white, Colors.green, CircleBorder()),
  ];

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        setState(() {
          index = (index + 1) % customizations.length;
        });

        const isbn = '9782253250005';

        const biblioApiUrl = String.fromEnvironment('BIBLIO_API_URL');
        const digitalOceanWebsecureToken = String.fromEnvironment('DIGITALOCEAN_WEBSECURE_TOKEN');
        const url = '$biblioApiUrl/books/getBookByIsbn?isbn=$isbn';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Require-Whisk-Auth': digitalOceanWebsecureToken,
          },
        );
        if (response.statusCode == 200) {
          print(response.body.toString());
          // return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        } else {
          print(response.body.toString());
          // throw Exception('Failed to load book with isbn $isbn');
        }
      },
      foregroundColor: customizations[index].$1,
      backgroundColor: customizations[index].$2,
      shape: customizations[index].$3,
      child: const Icon(Icons.add),
    );
  }
}
