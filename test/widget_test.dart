// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catastrophe_companion/main.dart';

void main() {
  testWidgets('App loads and shows configuration loading', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CatastropheCompanionApp());

    // Verify that the loading screen appears first
    expect(find.text('Loading game configuration...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the configuration to load
    await tester.pumpAndSettle();

    // After loading, we should see the main screen with bottom navigation
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
