import 'package:flutter/material.dart';

import 'package:biblio/services/title.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getleader(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data ?? 'No data');
        } else {
          return CircularProgressIndicator();
        }
      }
    );
  }
}
