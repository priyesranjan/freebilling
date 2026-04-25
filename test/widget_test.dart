// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:erp_bill/main.dart';

void main() {
  testWidgets('ERP shell loads main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ERP Bill Platform'), findsOneWidget);
    expect(find.text('Multi-Tenant Billing Platform'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
  });
}
