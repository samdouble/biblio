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

enum SearchResultsViewMode { list, grid }

enum SearchResultsSort { title, author }

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
  SearchResultsViewMode _resultsViewMode = SearchResultsViewMode.list;
  SearchResultsSort _resultsSort = SearchResultsSort.title;

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
    final sorted = List<ApiBook>.from(_searchResults)
      ..sort((a, b) {
        switch (_resultsSort) {
          case SearchResultsSort.title:
            return a.volumeInfo.title.toLowerCase().compareTo(
              b.volumeInfo.title.toLowerCase(),
            );
          case SearchResultsSort.author:
            final aAuthor = a.volumeInfo.authors.isNotEmpty
                ? a.volumeInfo.authors.first
                : '';
            final bAuthor = b.volumeInfo.authors.isNotEmpty
                ? b.volumeInfo.authors.first
                : '';
            final byAuthor = aAuthor.toLowerCase().compareTo(bAuthor.toLowerCase());
            if (byAuthor != 0) return byAuthor;
            return a.volumeInfo.title.toLowerCase().compareTo(
              b.volumeInfo.title.toLowerCase(),
            );
        }
      });

    Widget listContent() {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final book = sorted[index];
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

    Widget gridContent() {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.56,
        ),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final book = sorted[index];
          final info = book.volumeInfo;
          final thumb = info.imageLinks?.thumbnail.isNotEmpty == true
              ? info.imageLinks!.thumbnail
              : info.imageLinks?.smallThumbnail ?? '';
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => BookDetailPage(book: book),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: thumb.isNotEmpty
                        ? Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _searchCoverPlaceholder(context),
                          )
                        : _searchCoverPlaceholder(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text(
                      info.title.isEmpty ? AppLocalizations.of(context)!.untitled : info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Text(
                      info.authors.isNotEmpty ? info.authors.first : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                PopupMenuButton<SearchResultsSort>(
                  tooltip: AppLocalizations.of(context)!.sortBooks,
                  onSelected: (value) => setState(() => _resultsSort = value),
                  itemBuilder: (context) {
                    final scheme = Theme.of(context).colorScheme;
                    PopupMenuItem<SearchResultsSort> item(
                      SearchResultsSort value,
                      String label,
                    ) {
                      final selected = _resultsSort == value;
                      return PopupMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: selected
                                  ? Icon(Icons.check, size: 20, color: scheme.primary)
                                  : null,
                            ),
                            Expanded(child: Text(label)),
                          ],
                        ),
                      );
                    }

                    return [
                      item(SearchResultsSort.title, AppLocalizations.of(context)!.sortByTitle),
                      item(SearchResultsSort.author, AppLocalizations.of(context)!.sortByAuthor),
                    ];
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context)!.sortBooks),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _resultsViewMode == SearchResultsViewMode.list
                        ? Icons.grid_view
                        : Icons.view_list,
                  ),
                  tooltip: _resultsViewMode == SearchResultsViewMode.list
                      ? 'Grid view'
                      : 'List view',
                  onPressed: () {
                    setState(() {
                      _resultsViewMode = _resultsViewMode == SearchResultsViewMode.list
                          ? SearchResultsViewMode.grid
                          : SearchResultsViewMode.list;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _resultsViewMode == SearchResultsViewMode.list
              ? listContent()
              : gridContent(),
        ),
      ],
    );
  }

  Widget _searchCoverPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.menu_book_outlined, size: 34),
      ),
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
