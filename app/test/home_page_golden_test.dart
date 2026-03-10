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
import 'package:biblio/db/migrations/migration_006_library_color.dart' as m6;
import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/screens/home_page.dart';

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
    await m6.run(testDb);
    databaseResolver = () async => testDb;
  });

  tearDown(() async {
    databaseResolver = initDatabase;
    await testDb.close();
  });

  testWidgets('HomePage matches golden file', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MyAppState(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
            useMaterial3: true,
          ),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_page.png'),
    );
  });
}
