import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:biblio/db/db.dart';
import 'package:biblio/db/migrations/migration_001_books.dart' as m1;
import 'package:biblio/db/migrations/migration_002_library_tables.dart' as m2;
import 'package:biblio/db/migrations/migration_003_pending_search.dart' as m3;
import 'package:biblio/db/migrations/migration_004_books_isbn_thumbnail.dart' as m4;
import 'package:biblio/db/migrations/migration_005_books_thumbnail_url.dart' as m5;
import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/models/library.dart';
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/screens/library_detail_page.dart';

void main() {
  late dynamic testDb;

  setUpAll(() async {
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await m1.run(testDb);
    await m2.run(testDb);
    await m3.run(testDb);
    await m4.run(testDb);
    await m5.run(testDb);
    databaseResolver = () async => testDb;
    await insertLibrary(const Library(id: 'lib-1', name: 'Original Name'));
  });

  tearDown(() async {
    databaseResolver = initDatabase;
    await testDb.close();
  });

  testWidgets('renaming a library updates the detail page title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MyAppState(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: LibraryDetailPage(
                library: const Library(id: 'lib-1', name: 'Original Name'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Original Name'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Renamed Library');
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Renamed Library'), findsOneWidget);
  });

  test('renaming a library updates it in the database so list shows new name',
      () async {
    expect((await fetchLibraries()).first.name, 'Original Name');

    await updateLibraryName('lib-1', 'Renamed Library');

    final libraries = await fetchLibraries();
    expect(libraries, hasLength(1));
    expect(libraries.first.id, 'lib-1');
    expect(libraries.first.name, 'Renamed Library');
  });
}
