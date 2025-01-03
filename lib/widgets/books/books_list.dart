import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:biblio/models/book.dart';

class BooksList extends StatefulWidget {
  final List<Book> books;

  const BooksList({
    super.key,
    required this.books,
  });

  @override
  State<BooksList> createState() => _BooksListState();
}

class _BooksListState extends State<BooksList> {
  @override
  Widget build(BuildContext context) {
    List<bool> selected = List<bool>.generate(widget.books.length, (int index) => false);
    List<DataRow> rows = [];

    for (int index = 0; index < widget.books.length; index++) {
      Book book = widget.books[index];
      rows.add(
        DataRow(
          color: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              // All rows will have the same selected color.
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
              }
              // Even rows will have a grey color.
              if (index.isEven) {
                return Colors.grey.withValues(alpha: 0.3);
              }
              return null; // Use default value for other states and odd rows.
            }
          ),
          cells: <DataCell>[
            DataCell(Text(book.title)),
            DataCell(Text(book.author)),
          ],
          selected: selected[index],
          onSelectChanged: (bool? value) {
            setState(() {
              selected[index] = value!;
            });
          },
        )
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: <DataColumn>[
          DataColumn(
            label: Text(AppLocalizations.of(context)!.title),
          ),
          DataColumn(
            label: Text(AppLocalizations.of(context)!.author),
          ),
        ],
        rows: rows,
      ),
    );
  }
}
