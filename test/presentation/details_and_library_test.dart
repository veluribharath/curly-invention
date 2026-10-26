import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
