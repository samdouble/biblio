import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/settings_page.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({Locale locale = const Locale('en')}) {
    return ChangeNotifierProvider(
      create: (_) => MyAppState(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('shows Settings title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Plan section with Free and Pay per book toggles',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pay per book'), findsOneWidget);
    });

    testWidgets('shows Free plan description by default', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Use the app at no cost.'), findsOneWidget);
    });

    testWidgets('tapping Pay per book selects it and updates description',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Pay per book'));
      await tester.pumpAndSettle();

      expect(find.text('Small fee per book added.'), findsOneWidget);
    });

    testWidgets('tapping Free after Pay per book switches back', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Pay per book'));
      await tester.pumpAndSettle();
      expect(find.text('Small fee per book added.'), findsOneWidget);

      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();
      expect(find.text('Use the app at no cost.'), findsOneWidget);
    });

    testWidgets('shows Language section and dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Language'), findsWidgets);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows Sign up when not signed in', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Sign up'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('has menu button to open drawer', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('shows Sign out and signed-in email when signed in',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'signed_in_user_id': 'user-1',
        'signed_in_email': 'test@example.com',
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sign out'), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
