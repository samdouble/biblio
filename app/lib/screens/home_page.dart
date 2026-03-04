import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:biblio/models/api_book.dart';
import 'package:biblio/models/book.dart';
import 'package:biblio/screens/book_detail_page.dart';
import 'package:biblio/widgets/books/add_book_button.dart';
import 'package:biblio/widgets/main_drawer.dart';
import 'package:biblio/widgets/my_widget.dart';

var uuid = Uuid();

const _localeKey = 'app_locale';
const _signedInUserIdKey = 'signed_in_user_id';
const _signedInEmailKey = 'signed_in_email';

class MyAppState extends ChangeNotifier {
  MyAppState() {
    _loadLocale();
    _loadSignedInUser();
  }

  var current = 'samdouble';

  Locale? _locale;
  Locale? get locale => _locale;

  String? _signedInUserId;
  String? _signedInEmail;
  String? get signedInUserId => _signedInUserId;
  String? get signedInEmail => _signedInEmail;
  bool get isSignedIn => _signedInEmail != null;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null && (code == 'en' || code == 'fr')) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> _loadSignedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    _signedInUserId = prefs.getString(_signedInUserIdKey);
    _signedInEmail = prefs.getString(_signedInEmailKey);
    notifyListeners();
  }

  Future<void> setSignedIn(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_signedInUserIdKey, userId);
    await prefs.setString(_signedInEmailKey, email);
    _signedInUserId = userId;
    _signedInEmail = email;
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInUserIdKey);
    await prefs.remove(_signedInEmailKey);
    _signedInUserId = null;
    _signedInEmail = null;
    notifyListeners();
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<ApiBook> _searchResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() {
      _searchQuery = query.trim();
      _searching = true;
      _searchResults = [];
    });
    final results = await searchBooksFromApi(query, limit: 20);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search by title, author, ISBN…',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _runSearch,
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _searchQuery.isNotEmpty
          ? _searchBody()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyWidget(),
                Column(
                  children: [
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

  Widget _searchBody() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No books found for "$_searchQuery".',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        final info = book.volumeInfo;
        final subtitle = info.authors.isNotEmpty
            ? info.authors.join(', ')
            : (book.isbn.isNotEmpty ? 'ISBN ${book.isbn}' : '');
        return ListTile(
          title: Text(info.title.isEmpty ? 'Untitled' : info.title),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => BookDetailPage(book: book),
              ),
            );
          },
        );
      },
    );
  }
}
