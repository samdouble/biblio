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

        const isbn = "0735619670";
        const url = "https://faas-tor1-70ca848e.doserverless.co/api/v1/web/fn-21b31321-952b-469e-8ef0-79a5954fa817/books/getBookByIsbn?isbn=$isbn";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          print(response.body.toString());
          // return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        } else {
          print(response.body.toString());
          throw Exception('Failed to load book with isbn 0735619670');
        }
      },
      foregroundColor: customizations[index].$1,
      backgroundColor: customizations[index].$2,
      shape: customizations[index].$3,
      child: const Icon(Icons.add),
    );
  }
}
