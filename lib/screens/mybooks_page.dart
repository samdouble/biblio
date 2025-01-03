import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:biblio/models/book.dart';
import 'package:biblio/widgets/books/books_list.dart';
import 'package:biblio/widgets/main_drawer.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(AppLocalizations.of(context)!.myBooks),
      ),
      body: Row(
        children: [
          FutureBuilder<List<Book>>(
            future: fetchBooks(),
            builder: (context, AsyncSnapshot<List<Book>> snapshot) {
              if (snapshot.hasData) {
                return BooksList(
                  books: snapshot.data ?? [],
                );
              } else {
                return CircularProgressIndicator();
              }
            }
          ),
        ],
      ),
      drawer: MainDrawer(),
    );
  }
}
