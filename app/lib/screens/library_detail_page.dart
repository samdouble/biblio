import 'package:flutter/material.dart';

import 'package:biblio/models/book.dart';
import 'package:biblio/models/library.dart';

class LibraryDetailPage extends StatefulWidget {
  final Library library;

  const LibraryDetailPage({super.key, required this.library});

  @override
  State<LibraryDetailPage> createState() => _LibraryDetailPageState();
}

class _LibraryDetailPageState extends State<LibraryDetailPage> {
  Future<List<Book>> _loadBooks() => fetchBooksInLibrary(widget.library.id);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
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
                    onPressed: () {
                      _addBooks();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add books'),
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
                child: FilledButton.icon(
                  onPressed: _addBooks,
                  icon: const Icon(Icons.add),
                  label: const Text('Add books'),
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
