import 'package:flutter/material.dart';
import 'package:biblio/l10n/app_localizations.dart';

import 'package:biblio/models/api_book.dart';
import 'package:biblio/models/book.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/screens/book_detail_page.dart';
import 'package:biblio/widgets/books/add_book_button.dart';
import 'package:biblio/widgets/books/books_list.dart';
import 'package:biblio/widgets/main_drawer.dart';
import 'package:biblio/widgets/sort_view_toolbar.dart';

enum MyBooksSort { title, author }

enum MyBooksViewMode { list, grid }

class MyBooksPage extends StatefulWidget {
  const MyBooksPage({super.key});

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  late Future<List<Book>> _booksFuture;
  MyBooksSort _sort = MyBooksSort.title;
  MyBooksViewMode _viewMode = MyBooksViewMode.list;

  @override
  void initState() {
    super.initState();
    _booksFuture = fetchBooksFromAllLibraries();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.myBooks),
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, AsyncSnapshot<List<Book>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final sorted = List<Book>.from(snapshot.data ?? [])
            ..sort((a, b) {
              switch (_sort) {
                case MyBooksSort.title:
                  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
                case MyBooksSort.author:
                  final byAuthor = a.author.toLowerCase().compareTo(b.author.toLowerCase());
                  if (byAuthor != 0) return byAuthor;
                  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              }
            });
          if (sorted.isEmpty) {
            return BooksList(
              books: sorted,
              onBookTap: (book) => _openBookDetail(context, book),
            );
          }
          return Column(
            children: [
              SortViewToolbar<MyBooksSort>(
                sortOptions: [
                  (value: MyBooksSort.title, label: l10n.sortByTitle),
                  (value: MyBooksSort.author, label: l10n.sortByAuthor),
                ],
                selectedSort: _sort,
                onSortSelected: (value) => setState(() => _sort = value),
                sortButtonLabel: l10n.sortBooks,
                sortTooltip: l10n.sortBooks,
                isGridView: _viewMode == MyBooksViewMode.grid,
                onToggleView: () {
                  setState(() {
                    _viewMode = _viewMode == MyBooksViewMode.list
                        ? MyBooksViewMode.grid
                        : MyBooksViewMode.list;
                  });
                },
                gridTooltip: 'Grid view',
                listTooltip: 'List view',
              ),
              Expanded(
                child: _viewMode == MyBooksViewMode.list
                    ? BooksList(
                        books: sorted,
                        onBookTap: (book) => _openBookDetail(context, book),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.56,
                        ),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final book = sorted[index];
                          final thumb = book.thumbnailUrl.trim();
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _openBookDetail(context, book),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: thumb.isNotEmpty
                                        ? Image.network(
                                            thumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _coverPlaceholder(context),
                                          )
                                        : _coverPlaceholder(context),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                    child: Text(
                                      book.title.isEmpty ? l10n.untitled : book.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                    child: Text(
                                      book.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      drawer: MainDrawer(),
      floatingActionButton: FloatingButton(),
    );
  }

  Widget _coverPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.menu_book_outlined, size: 34),
      ),
    );
  }

  Future<void> _openBookDetail(BuildContext context, Book book) async {
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
