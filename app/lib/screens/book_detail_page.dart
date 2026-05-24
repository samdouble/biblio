import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tsundoku/l10n/app_localizations.dart';
import 'package:tsundoku/models/api_book.dart';
import 'package:tsundoku/models/library.dart';
import 'package:tsundoku/screens/books_by_author_page.dart';

String formatPublishedDateForDisplay(BuildContext context, String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final locale = Localizations.localeOf(context).toString();

  try {
    final dt = DateTime.parse(trimmed);
    return DateFormat.yMMMd(locale).format(dt);
  } catch (_) {}

  final ym = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(trimmed);
  if (ym != null) {
    final year = int.tryParse(ym.group(1)!);
    final month = int.tryParse(ym.group(2)!);
    if (year != null && month != null && month >= 1 && month <= 12) {
      return DateFormat.yMMMM(locale).format(DateTime(year, month));
    }
  }

  if (RegExp(r'^\d{4}$').hasMatch(trimmed)) {
    return trimmed;
  }

  return trimmed;
}

class BookDetailPage extends StatefulWidget {
  const BookDetailPage({super.key, required this.book});

  final ApiBook book;

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late final Future<List<Library>> _librariesFuture;

  @override
  void initState() {
    super.initState();
    _librariesFuture = fetchLibrariesContainingBook(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final info = book.volumeInfo;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final publishedFormatted = formatPublishedDateForDisplay(context, info.publishedDate);

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
                          horizontal: 0,
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
                '${l10n.bookPublisher}: ${info.publisher}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (publishedFormatted.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.bookPublished}: $publishedFormatted',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (info.pageCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${info.pageCount} pages',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.bookInYourLibraries,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Library>>(
              future: _librariesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                final libs = snapshot.data ?? [];
                if (libs.isEmpty) {
                  return Text(
                    l10n.bookNotInAnyLibrary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final lib in libs)
                      Chip(
                        avatar: CircleAvatar(
                          backgroundColor: lib.color != null
                              ? Color(lib.color!)
                              : theme.colorScheme.surfaceContainerHighest,
                          maxRadius: 10,
                          child: lib.color == null
                              ? Icon(
                                  Icons.folder_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        label: Text(lib.name),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                );
              },
            ),
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
