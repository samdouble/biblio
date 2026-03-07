import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/library_detail_page.dart';
import 'package:biblio/services/library_api_service.dart';
import 'package:biblio/widgets/main_drawer.dart';

final _uuid = Uuid();

class LibrariesPage extends StatefulWidget {
  const LibrariesPage({super.key});

  @override
  State<LibrariesPage> createState() => _LibrariesPageState();
}

class _LibrariesPageState extends State<LibrariesPage> {
  Future<List<(Library library, int bookCount)>> _loadLibraries() async {
    final userId = context.read<MyAppState>().signedInUserId;
    if (userId != null) {
      final result = await getLibraries(userId);
      if (result.error == null && result.libraries.isNotEmpty) {
        await replaceLibrariesWith(result.libraries);
      }
    }
    final libraries = await fetchLibraries();
    final counts = await Future.wait(
      libraries.map((l) => fetchBookCountInLibrary(l.id)),
    );
    return List.generate(
      libraries.length,
      (i) => (libraries[i], counts[i]),
    );
  }

  Future<void> _createLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<MyAppState>().signedInUserId;
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
    if (created != true || !mounted) {
      return;
    }
    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    if (userId != null) {
      final result = await createLibrary(userId, name);
      if (result.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!)),
        );
        return;
      }
      if (result.library != null) {
        await insertLibrary(result.library!);
      }
    } else {
      final library = Library(id: _uuid.v4(), name: name);
      await insertLibrary(library);
    }
    if (!mounted) {
      return;
    }
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
      body: FutureBuilder<List<(Library library, int bookCount)>>(
        future: _loadLibraries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
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
            itemCount: list.length,
            itemBuilder: (context, index) {
              final (lib, bookCount) = list[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.folder_outlined),
                ),
                title: Text('${lib.name} ($bookCount)'),
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
