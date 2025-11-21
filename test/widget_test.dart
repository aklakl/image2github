import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image2github/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Image2GitHubApp());

    // Verify that the app builds and shows the title
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
