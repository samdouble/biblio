import 'package:flutter/material.dart';
import 'package:biblio/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/sign_up_page.dart';
import 'package:biblio/widgets/main_drawer.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l10n.plan,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Consumer<MyAppState>(
            builder: (context, appState, _) {
              final plan = appState.plan;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ToggleButtons(
                      isSelected: [plan == Plan.free, plan == Plan.payPerBook],
                      onPressed: (int index) {
                        context.read<MyAppState>().setPlan(
                              index == 0 ? Plan.free : Plan.payPerBook,
                            );
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(l10n.planFree),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(l10n.planPayPerBook),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan == Plan.free
                          ? l10n.planFreeDescription
                          : l10n.planPayPerBookDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            title: Text(l10n.language),
            trailing: Consumer<MyAppState>(
              builder: (context, appState, _) {
                final current = appState.locale?.languageCode ?? 'en';
                return DropdownButton<String>(
                  value: current == 'en' || current == 'fr' ? current : 'en',
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(value: 'fr', child: Text(l10n.languageFrench)),
                  ],
                  onChanged: (String? code) {
                    if (code != null) {
                      context.read<MyAppState>().setLocale(Locale(code));
                    }
                  },
                );
              },
            ),
          ),
          Consumer<MyAppState>(
            builder: (context, appState, _) {
              if (appState.isSignedIn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l10n.signedInAs(appState.signedInEmail ?? ''),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(l10n.signOut),
                      onTap: () => appState.signOut(),
                    ),
                  ],
                );
              }
              return ListTile(
                leading: const Icon(Icons.person_add),
                title: Text(l10n.signUp),
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (context) => const SignUpPage(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.signUpSuccess)),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      drawer: MainDrawer(),
    );
  }
}
