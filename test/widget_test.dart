// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:striktnanay/main.dart';

void main() {
  testWidgets('Splash screen shows app branding', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Strikt'), findsOneWidget);
    expect(find.text('Nanay'), findsOneWidget);

    // Advance the fake clock so the splash timer can complete without
    // leaving pending timers that fail the test harness.
    await tester.pump(const Duration(seconds: 3));
  });
}
