import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/usecases/query_library.dart';

/// One line of the diary: a single viewing of a title.
class DiaryItem {
  final LibraryEntry entry;

  /// Index into [LibraryEntry.watches], to edit this viewing.
  final int watchIndex;

  const DiaryItem(this.entry, this.watchIndex);

  WatchEvent get watch => entry.watches[watchIndex];

  /// Not the first time you watched it.
  bool get rewatch => watchIndex > 0;
}

/// Every viewing in your library, newest first, so a title watched twice
/// shows twice. Viewings without a date ([WatchEvent.dateKnown]) come last,
/// newest logged first. Ties go by title.
List<DiaryItem> buildDiary(Iterable<LibraryEntry> entries, {KindFilter kind = KindFilter.all}) {
  final items = [
    for (final entry in entries)
      if (kind.matches(entry.snapshot.type, isDocumentary: entry.snapshot.isDocumentary))
        for (var i = 0; i < entry.watches.length; i++) DiaryItem(entry, i),
  ];
  items.sort((a, b) {
    if (a.watch.dateKnown != b.watch.dateKnown) return a.watch.dateKnown ? -1 : 1;
    final byDate = b.watch.watchedAt.compareTo(a.watch.watchedAt);
    return byDate != 0 ? byDate : a.entry.snapshot.name.toLowerCase().compareTo(b.entry.snapshot.name.toLowerCase());
  });
  return items;
}
