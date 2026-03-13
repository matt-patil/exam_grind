import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_grind/main.dart';

void main() {
  testWidgets('Smoke test for ChallengeAlarmApp', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChallengeAlarmApp());

    // Verify that the HomeScreen loads by checking for 'Upcoming alarms' text.
    expect(find.text('Upcoming alarms'), findsOneWidget);
  });
}
