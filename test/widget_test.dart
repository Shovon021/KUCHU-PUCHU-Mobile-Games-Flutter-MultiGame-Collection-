// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_mobile_game/main.dart';

void main() {
  testWidgets('Game Box app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GameBoxApp());

    // Verify that the app title is present
    expect(find.textContaining('Game Box'), findsOneWidget);
  });
}
