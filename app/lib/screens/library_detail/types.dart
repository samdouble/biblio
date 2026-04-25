import 'package:biblio/models/library.dart';

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
