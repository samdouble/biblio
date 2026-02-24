import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:biblio/models/book.dart';
import 'package:biblio/widgets/books/add_book_button.dart';
import 'package:biblio/widgets/main_drawer.dart';
import 'package:biblio/widgets/my_widget.dart';

var uuid = Uuid();

const _localeKey = 'app_locale';

class MyAppState extends ChangeNotifier {
  MyAppState() {
    _loadLocale();
  }

  var current = 'samdouble';

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null && (code == 'en' || code == 'fr')) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale value) async {
    _locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, value.languageCode);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    const String appTitle = 'Biblio';
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(appTitle),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MyWidget(),
          Column(
            children: [
              Text(appState.current),
              ElevatedButton(
                onPressed: () async {
                  var everyFallingStar = Book(
                    id: uuid.v4(),
                    title: 'Every Falling Star',
                    author: 'Sungju Lee',
                  );
                  await insertBook(everyFallingStar);
                },
                child: const Text('Create Book'),
              ),
            ],
          ),
        ],
      ),
      drawer: MainDrawer(),
      floatingActionButton: FloatingButton(),
    );
  }
}
