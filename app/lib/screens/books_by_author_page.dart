import 'package:flutter/material.dart';
import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/models/api_book.dart';
import 'package:biblio/screens/book_detail_page.dart';

class BooksByAuthorPage extends StatelessWidget {
  const BooksByAuthorPage({super.key, required this.authorName});

  final String authorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(authorName),
      ),
      body: FutureBuilder<List<ApiBook>>(
        future: getBooksByAuthor(authorName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.of(context)!.noBooksFoundFor(authorName),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final info = book.volumeInfo;
              final subtitle = info.authors.isNotEmpty
                  ? info.authors.join(', ')
                  : (book.isbn.isNotEmpty ? 'ISBN ${book.isbn}' : '');
              return ListTile(
                title: Text(
                  info.title.isEmpty
                      ? AppLocalizations.of(context)!.untitled
                      : info.title,
                ),
                subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => BookDetailPage(book: book),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
