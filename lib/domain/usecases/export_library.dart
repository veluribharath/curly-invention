import 'dart:convert';

import 'package:reel/domain/entities/library_entry.dart';

/// The library as CSV, one row per watch (or one row for an unwatched
/// title), so spreadsheets and Letterboxd-style imports can read it.
String libraryToCsv(Iterable<LibraryEntry> entries) {
  final rows = <List<String>>[
    ['type', 'tmdb_id', 'title', 'year', 'watchlist', 'favorite', 'watched_date', 'rating', 'note'],
  ];
  final sorted = entries.toList()..sort((a, b) => a.snapshot.name.compareTo(b.snapshot.name));
  for (final entry in sorted) {
    final base = [
      entry.snapshot.type.name,
      '${entry.id.tmdbId}',
      entry.snapshot.name,
      entry.snapshot.year?.toString() ?? '',
      entry.onWatchlist ? 'yes' : 'no',
      entry.favorite ? 'yes' : 'no',
    ];
    if (entry.watches.isEmpty) {
      rows.add([...base, '', '', '']);
    } else {
      for (final watch in entry.watches) {
        rows.add([...base, _date(watch.watchedAt), watch.rating?.name ?? '', watch.note ?? '']);
      }
    }
  }
  return rows.map((row) => row.map(_cell).join(',')).join('\r\n');
}

/// The library as JSON, with everything we store.
String libraryToJson(Iterable<LibraryEntry> entries, {required DateTime exportedAt}) {
  final sorted = entries.toList()..sort((a, b) => a.snapshot.name.compareTo(b.snapshot.name));
  return const JsonEncoder.withIndent('  ').convert({
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'entries': [
      for (final e in sorted)
        {
          'type': e.snapshot.type.name,
          'tmdbId': e.id.tmdbId,
          'title': e.snapshot.name,
          'year': e.snapshot.year,
          'genres': e.snapshot.genres,
          'onWatchlist': e.onWatchlist,
          'favorite': e.favorite,
          'addedAt': e.addedAt.toUtc().toIso8601String(),
          'watches': [
            for (final w in e.watches)
              {'watchedAt': w.watchedAt.toUtc().toIso8601String(), 'rating': w.rating?.name, 'note': w.note},
          ],
        },
    ],
  });
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Quotes a cell when it has a comma, quote or line break. Cells starting
/// with = + - @ get a leading quote mark so spreadsheets don't run them as
/// formulas.
String _cell(String value) {
  var text = value;
  if (text.isNotEmpty && '=+-@'.contains(text[0])) text = "'$text";
  if (text.contains(RegExp('[",\r\n]'))) return '"${text.replaceAll('"', '""')}"';
  return text;
}
