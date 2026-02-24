// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biblio/main.dart';

void main() {
  testWidgets('Click on My Books button shows the Books screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Create Book'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pump();

    expect(find.text('My Books'), findsAtLeastNWidgets(2));
  });
}
