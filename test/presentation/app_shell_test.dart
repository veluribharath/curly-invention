import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/main.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('the four tabs switch screens', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const ReelApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Search', 'Library', 'You', 'Discover']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppBar), matching: find.text(label)), findsOneWidget);
    }
  });
}
