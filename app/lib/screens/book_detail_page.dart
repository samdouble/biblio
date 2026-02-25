import 'package:flutter/material.dart';
import 'package:biblio/models/api_book.dart';

class BookDetailPage extends StatelessWidget {
  const BookDetailPage({super.key, required this.book});

  final ApiBook book;

  @override
  Widget build(BuildContext context) {
    final info = book.volumeInfo;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(info.title.isEmpty ? 'Book details' : info.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              Text(
                info.authors.join(', '),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
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
