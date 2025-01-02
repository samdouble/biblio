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
  testWidgets('Click on Notifications button shows the Notifications screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.text('Notification 1'), findsNothing);

    await tester.tap(find.byIcon(Icons.notifications_sharp));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('Scan Barcode'), findsNothing);
    expect(find.text('Notification 1'), findsOneWidget);
  });
}
