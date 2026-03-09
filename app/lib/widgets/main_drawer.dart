import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color.fromARGB(255, 248, 248, 248),
      shape: LinearBorder(),
      child: Column(
        children: [
          Expanded(
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
                    child: Text('Drawer Header'),
                  ),
                ),
                ListTile(
                  title: const Text('Item 1'),
                  onTap: () {
                    // Update the state of the app.
                    // ...
                  },
                ),
                ListTile(
                  title: const Text('Item 2'),
                  onTap: () {
                    // Update the state of the app
                    // ...
                    // Then close the drawer
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final info = snapshot.data!;
              final version = info.buildNumber.isNotEmpty
                  ? '${info.version}+${info.buildNumber}'
                  : info.version;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Text(
                  'Version $version',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
