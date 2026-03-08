import 'dart:async';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/libraries_page.dart';
import 'package:biblio/screens/mybooks_page.dart';
import 'package:biblio/screens/settings_page.dart';
import 'package:biblio/services/pending_search_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblio/utils/connectivity.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<Navigation> {
  int currentPageIndex = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _checkInitialPending();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialPending() async {
    final results = await Connectivity().checkConnectivity();
    if (isOnline(results)) {
      final count = await processPendingSearches();
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count book lookup${count == 1 ? '' : 's'} synced.')),
        );
      }
    } else {
      _wasOffline = true;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (!isOnline(results)) {
      _wasOffline = true;
      return;
    }
    if (!_wasOffline) return;
    _wasOffline = false;
    processPendingSearches().then((count) {
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count book lookup${count == 1 ? '' : 's'} synced.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final showSyncBanner =
        appState.isSignedIn && appState.isOutOfSync;

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.green,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: AppLocalizations.of(context)!.home,
            selectedIcon: Icon(Icons.home),
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: AppLocalizations.of(context)!.myBooks,
            selectedIcon: Icon(Icons.menu_book),
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: AppLocalizations.of(context)!.libraries,
            selectedIcon: Icon(Icons.folder),
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: AppLocalizations.of(context)!.settings,
            selectedIcon: Icon(Icons.settings),
          ),
        ],
      ),
      body: showSyncBanner
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .changesNotSynced,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<MyAppState>().requestSync();
                              setState(() => currentPageIndex = 2);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.syncNow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: <Widget>[
                    HomePage(),
                    MyBooksPage(),
                    LibrariesPage(),
                    SettingsPage(),
                  ][currentPageIndex],
                ),
              ],
            )
          : <Widget>[
              HomePage(),
              MyBooksPage(),
              LibrariesPage(),
              SettingsPage(),
            ][currentPageIndex],
    );
  }
}
