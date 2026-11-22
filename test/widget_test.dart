import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chilli_plant_health/features/home/presentation/home_page.dart';

void main() {
  testWidgets('home keeps the active user name visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomePage(userName: 'Maria')),
    );

    expect(find.text('Hello, Maria 👋'), findsOneWidget);
  });
}
