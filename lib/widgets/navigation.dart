import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/messages_page.dart';
import 'package:biblio/screens/mybooks_page.dart';
import 'package:biblio/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: AppLocalizations.of(context)!.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: AppLocalizations.of(context)!.myBooks,
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.messenger_sharp),
            ),
            label: AppLocalizations.of(context)!.messages,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
      body: <Widget>[
        HomePage(),
        NotificationsPage(),
        MessagesPage(),
        SettingsPage(),
      ][currentPageIndex],
    );
  }
}
