import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/main.dart';
import 'package:reel/presentation/screens/diary_screen.dart';
import 'package:reel/presentation/widgets/title_tile.dart';

import '../support/fakes.dart';

void main() {
  Future<void> openLibrary(WidgetTester tester, MemoryLibraryRepository library) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(library: library),
        child: const ReelApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Library')));
    await tester.pumpAndSettle();
  }

  testWidgets('the diary lists watches by month, undated ones last', (tester) async {
    final inception = LibraryEntry.empty(MockCatalog.byId(const TitleId.movie(27205))!, now: DateTime(2026))
        .logWatch(
          WatchEvent(watchedAt: DateTime(2026, 9, 12, 20), rating: Rating.loved),
          now: DateTime(2026),
        )
        .logWatch(
          WatchEvent(watchedAt: DateTime(2026, 10, 3, 20), note: 'Better the second time'),
          now: DateTime(2026),
        );
    final office = LibraryEntry.empty(MockCatalog.byId(const TitleId.tv(2316))!, now: DateTime(2026)).logWatch(
      WatchEvent(watchedAt: DateTime(2026, 10, 20), rating: Rating.liked, dateKnown: false),
      now: DateTime(2026),
    );
    final library = MemoryLibraryRepository({inception.id: inception, office.id: office});
    await openLibrary(tester, library);

    await tester.tap(find.byTooltip('Diary'));
    await tester.pumpAndSettle();

    final headers = ['October 2026', 'September 2026', 'Seen before, no date'];
    for (final header in headers) {
      expect(find.text(header), findsOneWidget);
    }
    final ys = [for (final h in headers) tester.getTopLeft(find.text(h)).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('Rewatch · “Better the second time”'), findsOneWidget);
    expect(find.text('Loved it'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(DiaryScreen), matching: find.widgetWithText(TitleTile, 'Inception')),
      findsNWidgets(2),
    );
  });

  testWidgets('Add offers the setup swipe deck, which adds to the library', (tester) async {
    final library = MemoryLibraryRepository();
    await openLibrary(tester, library);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swipe through popular titles'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Want to watch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Liked'));
    await tester.pumpAndSettle();

    final entries = library.entries.values.toList();
    expect(entries.where((e) => e.onWatchlist), hasLength(1));
    final watched = entries.singleWhere((e) => e.watched);
    expect(watched.watches.single.rating, Rating.liked);
    expect(watched.watches.single.dateKnown, isFalse);
  });
}
