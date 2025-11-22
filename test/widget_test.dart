import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image2github/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Image2GitHubApp());

    // Verify that the app builds and shows the title
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
