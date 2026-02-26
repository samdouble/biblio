import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/mybooks_page.dart';
import 'package:biblio/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:biblio/l10n/app_localizations.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<Navigation> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.settings_outlined),
            label: AppLocalizations.of(context)!.settings,
            selectedIcon: Icon(Icons.settings),
          ),
        ],
      ),
      body: <Widget>[
        HomePage(),
        NotificationsPage(),
        SettingsPage(),
      ][currentPageIndex],
    );
  }
}
