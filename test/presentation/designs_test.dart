import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/reel_style.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/main.dart';
import 'package:reel/presentation/providers/account_providers.dart';
import 'package:reel/presentation/screens/home_shell.dart';
import 'package:reel/presentation/widgets/design_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// A library with a few watched, favorite and saved titles, so stats,
  /// banners and badges all show.
  Future<MemoryLibraryRepository> seededLibrary() async {
    const catalog = MockCatalogRepository();
    final titles = (await catalog.trending()).titles.take(6).toList();
    return MemoryLibraryRepository({
      for (final (i, title) in titles.indexed)
        title.id: LibraryEntry(
          snapshot: title,
          onWatchlist: i.isOdd,
          favorite: i == 0,
          watches: i.isOdd ? const [] : [WatchEvent(watchedAt: fixedNow, rating: Rating.loved)],
          addedAt: fixedNow,
          updatedAt: fixedNow,
        ),
    });
  }

  ReelStyle styleOf(WidgetTester tester) => Theme.of(tester.element(find.byType(HomeShell))).extension<ReelStyle>()!;

  Future<void> tapTab(WidgetTester tester, int index) async {
    final destination = HomeShell.destinations[index];
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.byWidget(destination.icon)).first);
    await tester.pumpAndSettle();
  }

  for (final design in AppDesign.values) {
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('${design.name} in ${mode.name} mode draws every tab and a title without errors', (tester) async {
        phone(tester);
        final library = await seededLibrary();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...testOverrides(library: library),
              appDesignProvider.overrideWith(() => AppDesignSetting(initial: design)),
              themeModeProvider.overrideWithBuild((ref, notifier) => mode),
            ],
            child: const ReelApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(styleOf(tester).design, design);

        for (var tab = 1; tab < HomeShell.destinations.length; tab++) {
          await tapTab(tester, tab);
        }
        await tester.scrollUntilVisible(find.text('About and credits'), 400, scrollable: find.byType(Scrollable).first);

        await tapTab(tester, 2);
        await tester.tap(find.byTooltip(RegExp('Show as (grid|list)')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Diary'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tapTab(tester, 1);
        await tester.tap(find.text('Breaking Bad').first);
        await tester.pumpAndSettle();
        expect(find.text('Breaking Bad'), findsWidgets);
      });
    }
  }

  testWidgets('the You tab switches the design and keeps it for next time', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const ReelApp()));
    await tester.pumpAndSettle();
    expect(styleOf(tester).design, AppDesign.classic);

    await tapTab(tester, 3);
    for (final design in [AppDesign.marquee, AppDesign.aura, AppDesign.pop]) {
      final card = find.descendant(of: find.byType(DesignPicker), matching: find.text(design.label));
      await tester.dragUntilVisible(
        card,
        find.descendant(of: find.byType(DesignPicker), matching: find.byType(Scrollable)),
        const Offset(-150, 0),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(styleOf(tester).design, design);
      expect(find.textContaining(design.description), findsOneWidget);
    }
    expect((await SharedPreferences.getInstance()).getString('appDesign'), 'pop');
  });

  testWidgets('a saved design is back on the next start', (tester) async {
    SharedPreferences.setMockInitialValues({'appDesign': 'aura'});
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const ReelApp()));
    await tester.pumpAndSettle();
    expect(styleOf(tester).design, AppDesign.aura);
  });
}
