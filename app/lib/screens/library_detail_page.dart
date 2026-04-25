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
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/services/library_api_service.dart';
import 'package:biblio/utils/connectivity.dart';

enum LibraryBookListSort { title, author, dateAdded }
enum LibraryBookViewMode { list, grid }

int compareLibraryBookListEntries(
  LibraryBookEntry a,
  LibraryBookEntry b,
  LibraryBookListSort sort,
) {
  switch (sort) {
    case LibraryBookListSort.title:
      var c = a.book.title.toLowerCase().compareTo(b.book.title.toLowerCase());
      if (c != 0) return c;
      c = a.book.author.toLowerCase().compareTo(b.book.author.toLowerCase());
      if (c != 0) return c;
      return a.book.id.compareTo(b.book.id);
    case LibraryBookListSort.author:
      var c = a.book.author.toLowerCase().compareTo(b.book.author.toLowerCase());
      if (c != 0) return c;
      c = a.book.title.toLowerCase().compareTo(b.book.title.toLowerCase());
      if (c != 0) return c;
      return a.book.id.compareTo(b.book.id);
    case LibraryBookListSort.dateAdded:
      var c = b.addedAt.compareTo(a.addedAt);
      if (c != 0) return c;
      c = a.book.title.toLowerCase().compareTo(b.book.title.toLowerCase());
      if (c != 0) return c;
      return a.book.id.compareTo(b.book.id);
  }
}

List<LibraryBookEntry> sortedLibraryBookListEntries(
  List<LibraryBookEntry> entries,
  LibraryBookListSort sort,
) {
  final out = List<LibraryBookEntry>.from(entries);
  out.sort((a, b) => compareLibraryBookListEntries(a, b, sort));
  return out;
}

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
    final result = await showDialog<_EditLibraryDialogResult>(
      context: context,
      builder: (context) => _EditLibraryDialog(
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

    final userId = context.read<MyAppState>().signedInUserId;
    if (userId != null) {
      final err = await updateLibrary(userId, _library.id, newName, color: newColor);
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

    final userId = context.read<MyAppState>().signedInUserId;
    if (userId != null) {
      final err = await deleteLibraryApi(userId, _library.id);
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
      builder: (context) => _AddBooksToLibraryDialog(books: available),
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
          PopupMenuButton<LibraryBookListSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortBooks,
            onSelected: (value) => setState(() => _bookListSort = value),
            itemBuilder: (context) {
              final scheme = Theme.of(context).colorScheme;
              PopupMenuItem<LibraryBookListSort> item(
                LibraryBookListSort value,
                String label,
              ) {
                final selected = _bookListSort == value;
                return PopupMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: selected
                            ? Icon(Icons.check, size: 20, color: scheme.primary)
                            : null,
                      ),
                      Expanded(child: Text(label)),
                    ],
                  ),
                );
              }

              return [
                item(LibraryBookListSort.title, l10n.sortByTitle),
                item(LibraryBookListSort.author, l10n.sortByAuthor),
                item(LibraryBookListSort.dateAdded, l10n.sortByDateAdded),
              ];
            },
          ),
          IconButton(
            icon: Icon(
              _bookViewMode == LibraryBookViewMode.list
                  ? Icons.grid_view
                  : Icons.view_list,
            ),
            tooltip: _bookViewMode == LibraryBookViewMode.list
                ? 'Grid view'
                : 'List view',
            onPressed: () {
              setState(() {
                _bookViewMode = _bookViewMode == LibraryBookViewMode.list
                    ? LibraryBookViewMode.grid
                    : LibraryBookViewMode.list;
              });
            },
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
      body: FutureBuilder<List<LibraryBookEntry>>(
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
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_bookViewMode == LibraryBookViewMode.list)
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
                          'Added ${_formatAddedAt(entry.addedAt)}',
                        ),
                        onTap: () => _openBookDetails(book),
                        trailing: IconButton(
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            minimumSize: const Size(40, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: 'Remove from library',
                          onPressed: () => _removeBookFromLibrary(book),
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
                            onTap: () => _openBookDetails(book),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
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
                                    onPressed: () => _removeBookFromLibrary(book),
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
        },
      ),
    );
  }
}

class _EditLibraryDialogResult {
  const _EditLibraryDialogResult({required this.name, required this.color});
  final String name;
  final int? color;
}

class _EditLibraryDialog extends StatefulWidget {
  const _EditLibraryDialog({
    required this.initialName,
    required this.initialColor,
    required this.colorOptions,
    required this.nameLabel,
  });

  final String initialName;
  final int? initialColor;
  final List<int?> colorOptions;
  final String nameLabel;

  @override
  State<_EditLibraryDialog> createState() => _EditLibraryDialogState();
}

class _EditLibraryDialogState extends State<_EditLibraryDialog> {
  late final TextEditingController _nameCtrl;
  late int? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      _EditLibraryDialogResult(name: name, color: _selectedColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.editLibrary),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                hintText: widget.nameLabel,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.libraryColor,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in widget.colorOptions)
                  InkWell(
                    onTap: () => setState(() => _selectedColor = value),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: _selectedColor == value
                            ? Border.all(color: scheme.primary, width: 3)
                            : null,
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: value != null ? Color(value) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.outline,
                            width: value == null ? 2 : 0,
                          ),
                        ),
                        child: value == null
                            ? Icon(Icons.block, size: 20, color: scheme.outline)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

class _AddBooksToLibraryDialog extends StatefulWidget {
  final List<Book> books;

  const _AddBooksToLibraryDialog({required this.books});

  @override
  State<_AddBooksToLibraryDialog> createState() => _AddBooksToLibraryDialogState();
}

class _AddBooksToLibraryDialogState extends State<_AddBooksToLibraryDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addBooksToLibrary),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.books.length,
          itemBuilder: (context, index) {
            final book = widget.books[index];
            return CheckboxListTile(
              title: Text(book.title),
              subtitle: Text(book.author),
              value: _selectedIds.contains(book.id),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(book.id);
                  } else {
                    _selectedIds.remove(book.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  final selected = widget.books
                      .where((b) => _selectedIds.contains(b.id))
                      .toList();
                  Navigator.of(context).pop(selected);
                },
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
