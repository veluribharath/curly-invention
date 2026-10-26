import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/usecases/discover_feed.dart';
import 'package:reel/main.dart';
import 'package:reel/presentation/providers/discover_providers.dart';
import 'package:reel/presentation/screens/discover_screen.dart';
import 'package:reel/presentation/widgets/reel_clip_player.dart';

import '../support/fakes.dart';

void main() {
  Future<({MemoryLibraryRepository library, MemoryFeedSignalRepository signals})> pump(
    WidgetTester tester, {
    MemorySettingsRepository? settings,
    MemoryLibraryRepository? library,
  }) async {
    // A phone-sized screen, so the whole card fits.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    library ??= MemoryLibraryRepository();
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

  testWidgets('rate it, after the card is gone, edits the new watch', (tester) async {
    final fakes = await pump(tester);
    final first = currentName(tester);
    await tester.tap(find.text('Watched').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate it'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Edit watch'), findsOneWidget);

    await tester.tap(find.text('Loved'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final entry = fakes.library.entries.values.single;
    expect(entry.snapshot.name, first);
    expect(entry.watches.single.rating, Rating.loved);
  });

  testWidgets('a watched that fails to save keeps the card', (tester) async {
    await pump(tester, library: _FailingLibraryRepository());
    final first = currentName(tester);
    await tester.tap(find.text('Watched').first);
    await tester.pumpAndSettle();
    expect(currentName(tester), first);
    expect(find.textContaining("Couldn't save"), findsOneWidget);
    expect(find.text('Rate it'), findsNothing);
  });

  testWidgets('the clip stops while another screen or tab covers Discover', (tester) async {
    await pump(tester);
    bool live() => tester.widget<ReelClipPlayer>(find.byType(ReelClipPlayer, skipOffstage: false).first).live;
    expect(live(), isTrue);

    await tester.tap(find.text('Details').first);
    await tester.pumpAndSettle();
    expect(live(), isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(live(), isTrue);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Library')));
    await tester.pumpAndSettle();
    expect(live(), isFalse);
  });

  test('a load where everything was skipped keeps going instead of stalling', () async {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        feedBuilderProvider.overrideWithValue((_) => (sources: [_SlowSource(6)], score: baseScore)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(discoverFeedProvider, (_, _) {});
    for (var i = 0; i < 20 && container.read(discoverFeedProvider).cards.isEmpty; i++) {
      await pumpEventQueue();
    }
    final feed = container.read(discoverFeedProvider);
    expect(feed.cards.single.title.name, MockCatalog.titles.first.name);
    expect(feed.exhausted, isTrue);
  });

  testWidgets('without services it asks you to pick some', (tester) async {
    await pump(tester, settings: MemorySettingsRepository(onboardedSettings().copyWith(serviceIds: const {})));
    expect(find.text('Pick services'), findsOneWidget);
    await tester.tap(find.text('Show everything instead'));
    await tester.pumpAndSettle();
    expect(find.byType(ReelCard), findsWidgets);
  });
}

class _FailingLibraryRepository extends MemoryLibraryRepository {
  @override
  Future<void> save(LibraryEntry entry) async => throw StateError('offline');
}

/// Hands out nothing for [emptyBatches] batches, then one title.
class _SlowSource implements CandidateSource {
  int emptyBatches;
  bool _done = false;

  _SlowSource(this.emptyBatches);

  @override
  bool get exhausted => _done;

  @override
  Future<List<FeedCandidate>> next() async {
    if (emptyBatches-- > 0) return const [];
    _done = true;
    return [FeedCandidate(MockCatalog.titles.first, FeedSource.popular, 'Popular')];
  }
}
