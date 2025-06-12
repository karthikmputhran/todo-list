import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:to_do_list/main.dart'; // ✅ match your pubspec.yaml

void main() {
  testWidgets('Theme toggle smoke test', (WidgetTester tester) async {
    // Build the ToDo app
    await tester.pumpWidget(const ToDoApp());

    // Check if LoginPage is displayed (modify if your LoginPage has other specific text)
    expect(find.text('Login'), findsOneWidget);
  });
}
