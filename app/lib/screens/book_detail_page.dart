import 'package:flutter/material.dart';
import 'package:biblio/models/api_book.dart';
import 'package:biblio/screens/books_by_author_page.dart';

class BookDetailPage extends StatelessWidget {
  const BookDetailPage({super.key, required this.book});

  final ApiBook book;

  @override
  Widget build(BuildContext context) {
    final info = book.volumeInfo;
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(info.title.isEmpty ? 'Book details' : info.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.imageLinks != null &&
                (info.imageLinks!.thumbnail.isNotEmpty ||
                    info.imageLinks!.smallThumbnail.isNotEmpty)) ...[
              Center(
                child: Image.network(
                  info.imageLinks!.thumbnail.isNotEmpty
                      ? info.imageLinks!.thumbnail
                      : info.imageLinks!.smallThumbnail,
                  height: 220,
                  fit: BoxFit.fitHeight,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_book,
                    size: 120,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (info.title.isNotEmpty)
              Text(
                info.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (info.authors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final author in info.authors)
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => BooksByAuthorPage(
                              authorName: author,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          author,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (book.isbn.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ISBN: ${book.isbn}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (info.publisher.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Publisher: ${info.publisher}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (info.publishedDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Published: ${info.publishedDate}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (info.pageCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${info.pageCount} pages',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (info.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
