import 'package:flutter/material.dart';
import 'package:biblio/l10n/app_localizations.dart';

import 'package:biblio/models/api_book.dart';
import 'package:biblio/models/book.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/screens/book_detail_page.dart';
import 'package:biblio/widgets/books/add_book_button.dart';
import 'package:biblio/widgets/books/books_list.dart';
import 'package:biblio/widgets/main_drawer.dart';

class MyBooksPage extends StatelessWidget {
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
      body: FutureBuilder<List<Book>>(
        future: fetchBooksFromAllLibraries(),
        builder: (context, AsyncSnapshot<List<Book>> snapshot) {
          if (snapshot.hasData) {
            return BooksList(
              books: snapshot.data ?? [],
              onBookTap: (book) => _openBookDetail(context, book),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      drawer: MainDrawer(),
      floatingActionButton: FloatingButton(),
    );
  }

  static Future<void> _openBookDetail(BuildContext context, Book book) async {
    if (book.isbn.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Book details are available for books added by scan.',
          ),
        ),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final apiBook = await getBookByIsbn(book.isbn);
    if (!context.mounted) return;
    if (apiBook != null) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => BookDetailPage(book: apiBook),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not load book details')),
      );
    }
  }
}
