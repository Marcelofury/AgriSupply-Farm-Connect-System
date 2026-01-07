// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrisupply/main.dart';

void main() {
  testWidgets('App loads successfully', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AgriSupplyApp());

    // Verify that our app builds successfully
    // The splash screen should be shown initially
    await tester.pump();

    // Verify the app is running
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
