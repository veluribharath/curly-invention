import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/build_diary.dart';
import 'package:reel/domain/usecases/query_library.dart';

void main() {
  LibraryEntry entry(TitleId id, List<DateTime> watched, {bool watchlist = false}) {
    var e = LibraryEntry.empty(MockCatalog.byId(id)!, now: DateTime(2026)).copyWith(onWatchlist: watchlist);
    for (final date in watched) {
      e = e.logWatch(WatchEvent(watchedAt: date), now: date);
    }
    return e;
  }

  final inception = entry(const TitleId.movie(27205), [DateTime(2026, 3, 1), DateTime(2026, 9, 1)]);
  final office = entry(const TitleId.tv(2316), [DateTime(2026, 5, 1)]);
  final breakingBad = entry(const TitleId.tv(1396), const [], watchlist: true);

  test('lists every viewing newest first, rewatches included', () {
    final diary = buildDiary([inception, office, breakingBad]);
    expect([for (final i in diary) i.entry.snapshot.name], ['Inception', 'The Office', 'Inception']);
    expect([for (final i in diary) i.rewatch], [true, false, false]);
    expect(diary.first.watch.watchedAt, DateTime(2026, 9, 1));
  });

  test('filters by kind', () {
    final diary = buildDiary([inception, office], kind: KindFilter.series);
    expect([for (final i in diary) i.entry.snapshot.name], ['The Office']);
  });

  test('puts watches without a date last', () {
    final seeded = LibraryEntry.empty(
      MockCatalog.byId(const TitleId.tv(1396))!,
      now: DateTime(2026),
    ).logWatch(WatchEvent(watchedAt: DateTime(2026, 12), dateKnown: false), now: DateTime(2026, 12));
    final diary = buildDiary([inception, seeded]);
    expect([for (final i in diary) i.entry.snapshot.name], ['Inception', 'Inception', 'Breaking Bad']);
  });
}
