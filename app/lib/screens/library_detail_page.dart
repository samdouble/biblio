import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:biblio/models/api_book.dart';
import 'package:biblio/models/book.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/screens/barcode_scanner_page.dart';
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
  Future<List<Book>> _loadBooks() => fetchBooksInLibrary(widget.library.id);

  Future<void> _deleteLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete library?'),
        content: Text(
          'Delete "${widget.library.name}"? Books in this library will be removed from it.',
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
      final err = await deleteLibraryApi(userId, widget.library.id);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    await deleteLibrary(widget.library);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _addBooks() async {
    final allBooks = await fetchBooks();
    final currentIds = await fetchBookIdsInLibrary(widget.library.id);
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
      await addBookToLibrary(widget.library.id, book.id);
    }
    setState(() {});
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
      await addBookToLibrary(widget.library.id, apiBook.id);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added "${info.title.isEmpty ? "Untitled" : info.title}" to ${widget.library.name}. Scan next or tap back.',
          ),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete library',
            onPressed: _deleteLibrary,
          ),
        ],
      ),
      body: FutureBuilder<List<Book>>(
        future: _loadBooks(),
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
                    label: const Text('Add books'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _addBooksByScanning,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Add by scanning'),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addBooks,
                        icon: const Icon(Icons.add),
                        label: const Text('Add books'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _addBooksByScanning,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Add by scanning'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      title: Text(book.title),
                      subtitle: Text(book.author),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove from library',
                        onPressed: () async {
                          await removeBookFromLibrary(widget.library.id, book.id);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
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
      title: const Text('Add books to library'),
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
