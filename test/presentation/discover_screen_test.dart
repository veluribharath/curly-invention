import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/main.dart';
import 'package:reel/presentation/screens/discover_screen.dart';

import '../support/fakes.dart';

void main() {
  Future<({MemoryLibraryRepository library, MemoryFeedSignalRepository signals})> pump(
    WidgetTester tester, {
    MemorySettingsRepository? settings,
  }) async {
    // A phone-sized screen, so the whole card fits.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final library = MemoryLibraryRepository();
    final signals = MemoryFeedSignalRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(library: library, signals: signals, settings: settings),
        child: const ReelApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (library: library, signals: signals);
  }

  String currentName(WidgetTester tester) => tester.widget<ReelCard>(find.byType(ReelCard).first).card.title.name;

  testWidgets('shows titles on your services, with a way to open them', (tester) async {
    await pump(tester);
    expect(find.byType(ReelCard), findsWidgets);
    expect(find.textContaining('Open in'), findsWidgets);
    // Netflix and Max only: Top Gun is on Prime.
    expect(find.text('Top Gun: Maverick'), findsNothing);
  });

  testWidgets('not for me removes the card and is remembered', (tester) async {
    final fakes = await pump(tester);
    final first = currentName(tester);
    await tester.tap(find.text('Not for me').first);
    await tester.pumpAndSettle();
    expect(currentName(tester), isNot(first));
    expect(fakes.signals.signals.single.type, FeedSignalType.notInterested);
  });

  testWidgets('watched logs a watch and moves on', (tester) async {
    final fakes = await pump(tester);
    final first = currentName(tester);
    await tester.tap(find.text('Watched').first);
    await tester.pumpAndSettle();
    expect(fakes.library.entries.values.single.snapshot.name, first);
    expect(find.text('Rate it'), findsOneWidget);
  });

  testWidgets('without services it asks you to pick some', (tester) async {
    await pump(tester, settings: MemorySettingsRepository(onboardedSettings().copyWith(serviceIds: const {})));
    expect(find.text('Pick services'), findsOneWidget);
    await tester.tap(find.text('Show everything instead'));
    await tester.pumpAndSettle();
    expect(find.byType(ReelCard), findsWidgets);
  });
}
