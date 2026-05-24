import 'package:flutter/material.dart';

import 'package:tsundoku/l10n/app_localizations.dart';
import 'package:tsundoku/models/book.dart';

class EditLibraryDialogResult {
  const EditLibraryDialogResult({required this.name, required this.color});
  final String name;
  final int? color;
}

class EditLibraryDialog extends StatefulWidget {
  const EditLibraryDialog({
    super.key,
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
  State<EditLibraryDialog> createState() => _EditLibraryDialogState();
}

class _EditLibraryDialogState extends State<EditLibraryDialog> {
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
      EditLibraryDialogResult(name: name, color: _selectedColor),
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

class AddBooksToLibraryDialog extends StatefulWidget {
  const AddBooksToLibraryDialog({super.key, required this.books});

  final List<Book> books;

  @override
  State<AddBooksToLibraryDialog> createState() => _AddBooksToLibraryDialogState();
}

class _AddBooksToLibraryDialogState extends State<AddBooksToLibraryDialog> {
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
