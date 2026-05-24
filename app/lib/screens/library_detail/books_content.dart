import 'package:flutter/material.dart';

import 'package:tsunbooku/models/book.dart';
import 'package:tsunbooku/models/library.dart';
import 'package:tsunbooku/screens/library_detail/types.dart';

class LibraryBooksContent extends StatelessWidget {
  const LibraryBooksContent({
    super.key,
    required this.entries,
    required this.viewMode,
    required this.formatAddedAt,
    required this.onOpenBookDetails,
    required this.onRemoveBookFromLibrary,
  });

  final List<LibraryBookEntry> entries;
  final LibraryBookViewMode viewMode;
  final String Function(DateTime) formatAddedAt;
  final Future<void> Function(Book) onOpenBookDetails;
  final Future<void> Function(Book) onRemoveBookFromLibrary;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (viewMode == LibraryBookViewMode.list)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index];
                final book = entry.book;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ).copyWith(right: 0),
                  title: Text(book.title),
                  subtitle: Text(
                    '${book.author}\n'
                    'Added ${formatAddedAt(entry.addedAt)}',
                  ),
                  onTap: () => onOpenBookDetails(book),
                  trailing: IconButton(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remove from library',
                    onPressed: () => onRemoveBookFromLibrary(book),
                  ),
                );
              },
              childCount: entries.length,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  final book = entry.book;
                  final thumb = book.thumbnailUrl.trim();
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onOpenBookDetails(book),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: thumb.isEmpty
                                ? Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Center(
                                      child: Icon(Icons.menu_book_outlined, size: 36),
                                    ),
                                  )
                                : Image.network(
                                    thumb,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 32,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Remove from library',
                              onPressed: () => onRemoveBookFromLibrary(book),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 48),
        ),
      ],
    );
  }
}
