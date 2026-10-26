import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/export_library.dart';

void main() {
  final title = MockCatalog.byId(const TitleId.movie(27205))!;
  final now = DateTime(2026, 10, 26);

  test('CSV has one row per watch and escapes notes', () {
    var entry = LibraryEntry.empty(title, now: now);
    entry = entry.logWatch(
      WatchEvent(watchedAt: DateTime(2024, 3, 5), rating: Rating.liked),
      now: now,
    );
    entry = entry.logWatch(
      WatchEvent(watchedAt: DateTime(2025, 1, 2), note: '=SUM(1), "great"'),
      now: now,
    );
    final lines = libraryToCsv([entry]).split('\r\n');
    expect(lines.first, startsWith('type,tmdb_id,title'));
    expect(lines, hasLength(3));
    expect(lines[1], contains('2024-03-05,liked,'));
    expect(lines[2], endsWith('2025-01-02,,"\'=SUM(1), ""great"""'));
  });

  test('an unwatched title still gets a row', () {
    final entry = LibraryEntry.empty(title, now: now).copyWith(onWatchlist: true);
    final lines = libraryToCsv([entry]).split('\r\n');
    expect(lines, hasLength(2));
    expect(lines[1], contains(',yes,no,,,'));
  });

  test('JSON keeps every watch', () {
    final entry = LibraryEntry.empty(title, now: now).logWatch(
      WatchEvent(watchedAt: DateTime.utc(2024), rating: Rating.loved),
      now: now,
    );
    final json = jsonDecode(libraryToJson([entry], exportedAt: DateTime.utc(2026))) as Map<String, dynamic>;
    final exported = (json['entries'] as List).single as Map<String, dynamic>;
    expect(exported['tmdbId'], 27205);
    expect((exported['watches'] as List).single['rating'], 'loved');
  });
}
