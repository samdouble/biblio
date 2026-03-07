import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biblio/main.dart';

void main() {
  testWidgets('Click on My Books button shows the Books screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('My Books'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pump();

    expect(find.text('My Books'), findsAtLeastNWidgets(2));
  });
}
