import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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

class LibraryDetailPage extends StatefulWidget {
  final Library library;

  const LibraryDetailPage({super.key, required this.library});

  @override
  State<LibraryDetailPage> createState() => _LibraryDetailPageState();
}

class _LibraryDetailPageState extends State<LibraryDetailPage> {
  late Library _library;
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _library = widget.library;
    _booksFuture = fetchBooksInLibrary(_library.id);
  }

  Future<List<Book>> _loadBooks() => fetchBooksInLibrary(_library.id);

  void _refreshBooks() {
    setState(() {
      _booksFuture = _loadBooks();
    });
  }

  Future<void> _renameLibrary() async {
    final nameController = TextEditingController(text: _library.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename library'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Library name',
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(context).pop(nameController.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    if (newName == _library.name) return;

    final userId = context.read<MyAppState>().signedInUserId;
    if (userId != null) {
      final err = await updateLibrary(userId, _library.id, newName);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    await updateLibraryName(_library.id, newName);
    if (!mounted) return;
    context.read<MyAppState>().setOutOfSync();
    setState(() => _library = Library(id: _library.id, name: newName));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_library.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename library',
            onPressed: _renameLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete library',
            onPressed: _deleteLibrary,
          ),
        ],
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data!;
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No books in this library',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _addBooks,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.addBooks),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _addBooksByScanning,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(AppLocalizations.of(context)!.addByScanning),
                  ),
                ],
              ),
            );
          }
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _addBooks,
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.addBooks),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _addBooksByScanning,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(AppLocalizations.of(context)!.addByScanning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = books[index];
                    return ListTile(
                      title: Text(book.title),
                      subtitle: Text(book.author),
                      onTap: () async {
                        if (book.isbn.isEmpty) {
                          if (!mounted) return;
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
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove from library',
                        onPressed: () async {
                          await removeBookFromLibrary(_library.id, book.id);
                          if (!mounted) return;
                          context.read<MyAppState>().setOutOfSync();
                          _refreshBooks();
                        },
                      ),
                    );
                  },
                  childCount: books.length,
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
