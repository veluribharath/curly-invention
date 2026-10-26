import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/main.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('first run picks a country and services, then lands on the tabs', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = MemorySettingsRepository();
    final library = MemoryLibraryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(settings: settings, library: library),
        child: const ReelApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('India'));
    await tester.pumpAndSettle();
    expect(settings.settings!.country, 'IN');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    expect(settings.settings!.serviceIds, {8});
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Seed your taste: like the first card, then finish.
    expect(find.text('Seed your taste'), findsOneWidget);
    await tester.tap(find.byTooltip('Liked'));
    await tester.pumpAndSettle();
    expect(library.entries.values.single.latestRating, Rating.liked);
    await tester.tap(find.text('Continue · 1 rated'));
    await tester.pumpAndSettle();

    expect(settings.settings!.onboarded, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
