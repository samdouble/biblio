import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/models/api_book.dart';
import 'package:biblio/models/book.dart';
import 'package:biblio/screens/book_detail_page.dart';
import 'package:biblio/widgets/books/add_book_button.dart';
import 'package:biblio/widgets/main_drawer.dart';

const _localeKey = 'app_locale';
const _signedInUserIdKey = 'signed_in_user_id';
const _signedInEmailKey = 'signed_in_email';
const _planKey = 'app_plan';

enum SyncStatus { synced, outOfSync, unknown }

enum Plan { free, payPerBook }

class MyAppState extends ChangeNotifier {
  MyAppState() {
    _loadLocale();
    _loadSignedInUser();
    _loadPlan();
  }

  var current = 'samdouble';

  Locale? _locale;
  Locale? get locale => _locale;

  String? _signedInUserId;
  String? _signedInEmail;
  String? get signedInUserId => _signedInUserId;
  String? get signedInEmail => _signedInEmail;
  bool get isSignedIn => _signedInEmail != null;

  SyncStatus _syncStatus = SyncStatus.unknown;
  SyncStatus get syncStatus => _syncStatus;
  bool get isOutOfSync => _syncStatus == SyncStatus.outOfSync;

  int _syncRequestedCount = 0;
  int get syncRequestedCount => _syncRequestedCount;

  Plan _plan = Plan.free;
  Plan get plan => _plan;

  Future<void> _loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_planKey);
    if (value == 'payPerBook') {
      _plan = Plan.payPerBook;
      notifyListeners();
    }
  }

  Future<void> setPlan(Plan value) async {
    if (_plan == value) return;
    _plan = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, value == Plan.payPerBook ? 'payPerBook' : 'free');
    notifyListeners();
  }

  void setSynced() {
    if (_syncStatus == SyncStatus.synced) return;
    _syncStatus = SyncStatus.synced;
    notifyListeners();
  }

  void setOutOfSync() {
    if (_syncStatus == SyncStatus.outOfSync) return;
    _syncStatus = SyncStatus.outOfSync;
    notifyListeners();
  }

  void setSyncUnknown() {
    _syncStatus = SyncStatus.unknown;
    notifyListeners();
  }

  void requestSync() {
    _syncRequestedCount++;
    notifyListeners();
  }

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
    _syncStatus = SyncStatus.unknown;
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInUserIdKey);
    await prefs.remove(_signedInEmailKey);
    _signedInUserId = null;
    _signedInEmail = null;
    _syncStatus = SyncStatus.unknown;
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
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
    });
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
            hintText: AppLocalizations.of(context)!.searchByHint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            filled: false,
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSearch,
                    tooltip: AppLocalizations.of(context)!.clearSearch,
                  ),
          ),
          onSubmitted: _runSearch,
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _searchQuery.isNotEmpty
          ? _searchBody()
          : SingleChildScrollView(
              child: _recentlyScannedSection(),
            ),
      drawer: MainDrawer(),
      floatingActionButton: FloatingButton(),
    );
  }

  Widget _recentlyScannedSection() {
    return FutureBuilder<List<Book>>(
      future: fetchRecentScannedBooks(limit: 5),
      builder: (context, snapshot) {
        final books = snapshot.hasData ? snapshot.data! : <Book>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                AppLocalizations.of(context)!.recentlyScanned,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            SizedBox(
              height: 165,
              child: books.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.recentlyScannedEmpty,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: books.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _RecentBookCard(book: book);
                      },
                    ),
            ),
          ],
        );
      },
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
            AppLocalizations.of(context)!.noBooksFoundFor(_searchQuery),
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
          title: Text(info.title.isEmpty ? AppLocalizations.of(context)!.untitled : info.title),
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

class _RecentBookCard extends StatelessWidget {
  const _RecentBookCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 100.0;
    const coverHeight = 120.0;
    final theme = Theme.of(context);

    return SizedBox(
      width: cardWidth,
      child: InkWell(
        onTap: book.isbn.isEmpty
            ? null
            : () async {
                final apiBook = await getBookByIsbn(book.isbn);
                if (!context.mounted) return;
                if (apiBook != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => BookDetailPage(book: apiBook),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!.couldNotLoadBookDetails)),
                  );
                }
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: book.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      book.thumbnailUrl,
                      width: cardWidth,
                      height: coverHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(cardWidth, coverHeight),
                    )
                  : _coverPlaceholder(cardWidth, coverHeight),
            ),
            const SizedBox(height: 6),
            Text(
              book.title.isEmpty ? AppLocalizations.of(context)!.untitled : book.title,
              style: theme.textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: Colors.black,
      child: const Icon(Icons.menu_book, color: Colors.white54, size: 32),
    );
  }
}
