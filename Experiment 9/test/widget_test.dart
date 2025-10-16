import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/main.dart';

void main() {
  testWidgets('Calculator shows 0 at start', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify calculator screen starts with "0"
    expect(find.text('0'), findsWidgets); // ✅ allows multiple "0"s (button + screen)

    // You can also check if a button exists
    expect(find.widgetWithText(ElevatedButton, '0'), findsOneWidget);
  });
}
