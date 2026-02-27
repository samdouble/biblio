import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/widgets/main_drawer.dart';
import 'package:biblio/screens/library_detail_page.dart';

final _uuid = Uuid();

class LibrariesPage extends StatefulWidget {
  const LibrariesPage({super.key});

  @override
  State<LibrariesPage> createState() => _LibrariesPageState();
}

class _LibrariesPageState extends State<LibrariesPage> {
  Future<void> _createLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createLibrary),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.libraryName,
            hintText: l10n.libraryName,
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(context).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (created != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final library = Library(id: _uuid.v4(), name: name);
    await insertLibrary(library);
    if (!mounted) return;
    setState(() {});
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
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(l10n.libraries),
      ),
      drawer: MainDrawer(),
      body: FutureBuilder<List<Library>>(
        future: fetchLibraries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final libraries = snapshot.data!;
          if (libraries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noLibraries,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: libraries.length,
            itemBuilder: (context, index) {
              final lib = libraries[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.folder_outlined),
                ),
                title: Text(lib.name),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => LibraryDetailPage(library: lib),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLibrary,
        tooltip: l10n.addLibrary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
