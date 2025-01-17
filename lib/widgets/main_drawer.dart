import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color.fromARGB(255, 248, 248, 248),
      shape: LinearBorder(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 100.0,
            child: const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 15, 136, 60),
                shape: BoxShape.rectangle,
              ),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
              child: Image(image: AssetImage('assets/logo.png'), height: 20),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.books),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.categories),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
