import 'package:flutter/material.dart';

import 'package:biblio/models/book.dart';

class BooksList extends StatelessWidget {
  final List<Book> books;
  final void Function(Book book)? onBookTap;

  const BooksList({
    super.key,
    required this.books,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Text(
          'No books in your libraries yet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          title: Text(
            book.title,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: book.author.isNotEmpty
              ? Text(
                  book.author,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: onBookTap != null ? () => onBookTap!(book) : null,
        );
      },
    );
  }
}
