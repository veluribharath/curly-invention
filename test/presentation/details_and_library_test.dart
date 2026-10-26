import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/main.dart';

import '../support/fakes.dart';

void main() {
  Future<MemoryLibraryRepository> pumpApp(WidgetTester tester) async {
    final repo = MemoryLibraryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(library: repo),
        child: const ReelApp(),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  testWidgets('search, save to watchlist, and see it in the library', (tester) async {
    final repo = await pumpApp(tester);
    await tapTab(tester, 'Search');

    await tester.enterText(find.byType(SearchBar), 'breaking');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Breaking Bad'), findsWidgets);

    await tester.tap(find.byTooltip('Add to watchlist').first);
    await tester.pumpAndSettle();
    expect(repo.entries[const TitleId.tv(1396)]!.onWatchlist, isTrue);

    await tapTab(tester, 'Library');
    expect(find.text('Breaking Bad'), findsWidgets);
    expect(find.text('Watchlist 1'), findsOneWidget);
  });

  testWidgets('log a loved watch from the details screen', (tester) async {
    final repo = await pumpApp(tester);
    await tapTab(tester, 'Search');
    await tester.enterText(find.byType(SearchBar), 'inception');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inception').last);
    await tester.pumpAndSettle();
    expect(find.text('Christopher Nolan'), findsOneWidget);

    await tester.tap(find.text('Log a watch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loved'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final entry = repo.entries[const TitleId.movie(27205)]!;
    expect(entry.watches.single.watchedAt.day, fixedNow.day);
    expect(entry.latestRating?.name, 'loved');
    expect(find.textContaining('Watched'), findsWidgets);
  });

  testWidgets('details show where to watch with your services highlighted', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 'Search');
    await tester.enterText(find.byType(SearchBar), 'stranger');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stranger Things').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Where to watch'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Stream'), findsOneWidget);
    expect(find.byTooltip('On your services'), findsOneWidget);
    expect(find.textContaining('JustWatch'), findsOneWidget);
  });

  testWidgets('the watchlist counts what streams on your services', (tester) async {
    final repo = MemoryLibraryRepository();
    final now = fixedNow;
    for (final id in [const TitleId.tv(1396), const TitleId.movie(238)]) {
      await repo.save(LibraryEntry.empty(MockCatalog.byId(id)!, now: now).copyWith(onWatchlist: true));
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(library: repo),
        child: const ReelApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tapTab(tester, 'Library');

    expect(find.text('1 of your watchlist is on your services'), findsOneWidget);
    await tester.tap(find.text('1 of your watchlist is on your services'));
    await tester.pumpAndSettle();
    expect(find.text('Breaking Bad'), findsWidgets);
    expect(find.text('The Godfather'), findsNothing);
  });
}
