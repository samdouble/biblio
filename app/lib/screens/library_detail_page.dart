import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/models/api_book.dart';
import 'package:biblio/models/book.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/screens/barcode_scanner_page.dart';
import 'package:biblio/screens/book_detail_page.dart';
import 'package:biblio/screens/library_detail/books_content.dart';
import 'package:biblio/screens/library_detail/dialogs.dart';
import 'package:biblio/screens/library_detail/types.dart';
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/services/library_api_service.dart';
import 'package:biblio/utils/connectivity.dart';
import 'package:biblio/widgets/sort_view_toolbar.dart';

class LibraryDetailPage extends StatefulWidget {
  final Library library;

  const LibraryDetailPage({super.key, required this.library});

  @override
  State<LibraryDetailPage> createState() => _LibraryDetailPageState();
}

class _LibraryDetailPageState extends State<LibraryDetailPage> {
  late Library _library;
  late Future<List<LibraryBookEntry>> _booksFuture;
  LibraryBookListSort _bookListSort = LibraryBookListSort.title;
  LibraryBookViewMode _bookViewMode = LibraryBookViewMode.list;

  @override
  void initState() {
    super.initState();
    _library = widget.library;
    _booksFuture = fetchBooksInLibraryWithAddedAt(_library.id);
  }

  Future<List<LibraryBookEntry>> _loadBooks() =>
      fetchBooksInLibraryWithAddedAt(_library.id);

  void _refreshBooks() {
    setState(() {
      _booksFuture = _loadBooks();
    });
  }

  static String _formatAddedAt(DateTime addedAt) {
    return DateFormat.yMMMd().format(addedAt.toLocal());
  }

  static const List<int?> _colorOptions = [
    null, // transparent
    0xFFE57373, // red
    0xFFF06292, // pink
    0xFFBA68C8, // purple
    0xFF9575CD, // deep purple
    0xFF7986CB, // indigo
    0xFF64B5F6, // blue
    0xFF4FC3F7, // light blue
    0xFF4DD0E1, // cyan
    0xFF4DB6AC, // teal
    0xFF81C784, // green
    0xFFAED581, // light green
    0xFFDCE775, // lime
    0xFFFFF176, // yellow
    0xFFFFB74D, // orange
    0xFFA1887F, // brown
  ];

  Future<void> _editLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<EditLibraryDialogResult>(
      context: context,
      builder: (context) => EditLibraryDialog(
        initialName: _library.name,
        initialColor: _library.color,
        colorOptions: _colorOptions,
        nameLabel: l10n.libraryName,
      ),
    );
    if (result == null || !mounted) return;

    final newName = result.name.trim();
    if (newName.isEmpty) return;

    final newColor = result.color;
    final nameChanged = newName != _library.name;
    final colorChanged = newColor != _library.color;
    if (!nameChanged && !colorChanged) return;

    final token = context.read<MyAppState>().authToken;
    if (token != null) {
      final err = await updateLibrary(token, _library.id, newName, color: newColor);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    if (nameChanged) await updateLibraryName(_library.id, newName);
    if (colorChanged) await updateLibraryColor(_library.id, newColor);
    if (!mounted) return;
    if (nameChanged || colorChanged) context.read<MyAppState>().setOutOfSync();
    setState(
      () => _library = Library(id: _library.id, name: newName, color: newColor),
    );
  }

  Future<void> _deleteLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete library?'),
        content: Text(
          'Delete "${_library.name}"? Books in this library will be removed from it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<MyAppState>().authToken;
    if (token != null) {
      final err = await deleteLibraryApi(token, _library.id);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    await deleteLibrary(_library);
    if (!mounted) return;
    context.read<MyAppState>().setOutOfSync();
    Navigator.of(context).pop(true);
  }

  void _addBooks() async {
    final allBooks = await fetchBooks();
    final currentIds = await fetchBookIdsInLibrary(_library.id);
    final currentSet = currentIds.toSet();
    final available = allBooks.where((b) => !currentSet.contains(b.id)).toList();
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your books are already in this library.')),
      );
      return;
    }
    if (!mounted) return;
    final selected = await showDialog<List<Book>>(
      context: context,
      builder: (context) => AddBooksToLibraryDialog(books: available),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    for (final book in selected) {
      await addBookToLibrary(_library.id, book.id);
    }
    if (mounted) context.read<MyAppState>().setOutOfSync();
    _refreshBooks();
  }

  Future<void> _addBooksByScanning() async {
    if (!mounted) return;
    final connectivity = Connectivity();
    final messenger = ScaffoldMessenger.of(context);

    while (mounted) {
      final isbn = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (context) => const BarcodeScannerPage(),
        ),
      );
      if (isbn == null || isbn.isEmpty) break;

      final results = await connectivity.checkConnectivity();
      if (!isOnline(results)) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You\'re offline. Connect to add books by scanning.'),
          ),
        );
        continue;
      }

      final apiBook = await getBookByIsbn(isbn);
      if (apiBook == null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Book not found for barcode $isbn')),
        );
        continue;
      }

      final info = apiBook.volumeInfo;
      final thumb = info.imageLinks?.thumbnail.isNotEmpty == true
          ? info.imageLinks!.thumbnail
          : info.imageLinks?.smallThumbnail ?? '';
      await insertBook(Book(
        id: apiBook.id,
        title: info.title.isEmpty ? 'Untitled' : info.title,
        author: info.authors.isEmpty ? '' : info.authors.join(', '),
        isbn: apiBook.isbn,
        thumbnailUrl: thumb,
      ));
      await addBookToLibrary(_library.id, apiBook.id);
      if (!mounted) return;
      context.read<MyAppState>().setOutOfSync();
      _refreshBooks();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added "${info.title.isEmpty ? "Untitled" : info.title}" to ${_library.name}. Scan next or tap back.',
          ),
        ),
      );
    }
    if (mounted) _refreshBooks();
  }

  Future<void> _openBookDetails(Book book) async {
    if (book.isbn.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book details are available for books added by scan.'),
        ),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final apiBook = await getBookByIsbn(book.isbn);
    if (!mounted) return;
    if (apiBook != null) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => BookDetailPage(book: apiBook),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not load book details'),
        ),
      );
    }
  }

  Future<void> _removeBookFromLibrary(Book book) async {
    final appState = context.read<MyAppState>();
    await removeBookFromLibrary(_library.id, book.id);
    if (!mounted) return;
    appState.setOutOfSync();
    _refreshBooks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_library.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: l10n.addBook,
            onSelected: (value) {
              if (value == 'manual') {
                _addBooks();
              } else if (value == 'scan') {
                _addBooksByScanning();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(
                      Icons.playlist_add_outlined,
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.addBooks)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.addByScanning)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editLibrary,
            onPressed: _editLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete library',
            onPressed: _deleteLibrary,
          ),
        ],
      ),
      body: Column(
        children: [
          SortViewToolbar<LibraryBookListSort>(
            sortOptions: [
              (value: LibraryBookListSort.title, label: l10n.sortByTitle),
              (value: LibraryBookListSort.author, label: l10n.sortByAuthor),
              (value: LibraryBookListSort.dateAdded, label: l10n.sortByDateAdded),
            ],
            selectedSort: _bookListSort,
            onSortSelected: (value) => setState(() => _bookListSort = value),
            sortButtonLabel: l10n.sortBooks,
            sortTooltip: l10n.sortBooks,
            isGridView: _bookViewMode == LibraryBookViewMode.grid,
            onToggleView: () {
              setState(() {
                _bookViewMode = _bookViewMode == LibraryBookViewMode.list
                    ? LibraryBookViewMode.grid
                    : LibraryBookViewMode.list;
              });
            },
            gridTooltip: 'Grid view',
            listTooltip: 'List view',
            useSafeArea: true,
          ),
          Expanded(
            child: FutureBuilder<List<LibraryBookEntry>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = sortedLibraryBookListEntries(snapshot.data!, _bookListSort);
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.noBooksInLibrary,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.libraryEmptyAddHint,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return LibraryBooksContent(
                  entries: entries,
                  viewMode: _bookViewMode,
                  formatAddedAt: _formatAddedAt,
                  onOpenBookDetails: _openBookDetails,
                  onRemoveBookFromLibrary: _removeBookFromLibrary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

