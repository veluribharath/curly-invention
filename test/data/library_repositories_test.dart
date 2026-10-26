import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/models/library_entry_mapper.dart';
import 'package:reel/data/repositories/firestore_library_repository.dart';
import 'package:reel/data/repositories/local_library_repository.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 26, 20);
  final entry = LibraryEntry.empty(MockCatalog.byId(const TitleId.tv(1396))!, now: now)
      .logWatch(
        WatchEvent(watchedAt: DateTime(2025, 3, 1), rating: Rating.loved, note: 'Again!'),
        now: now,
      )
      .copyWith(favorite: true);

  group('LibraryEntryMapper', () {
    test('round-trips through JSON', () {
      final back = LibraryEntryMapper.fromJson(LibraryEntryMapper.toJson(entry))!;
      expect(back.id, entry.id);
      expect(back.favorite, isTrue);
      expect(back.watches, entry.watches);
      expect(back.snapshot.directors, entry.snapshot.directors);
      expect(back.snapshot.seasonCount, 5);
    });

    test('round-trips through Firestore fields', () {
      final back = LibraryEntryMapper.fromFirestore(LibraryEntryMapper.toFirestore(entry))!;
      expect(back.watches.single.rating, Rating.loved);
      expect(back.addedAt, entry.addedAt);
    });

    test('skips documents without a known type', () {
      expect(LibraryEntryMapper.fromJson({'type': 'book', 'tmdbId': 1}), isNull);
      expect(LibraryEntryMapper.fromJson({'type': 'movie'}), isNull);
    });
  });

  test('the local library survives a restart and drops empty entries', () async {
    SharedPreferences.setMockInitialValues({});
    final first = LocalLibraryRepository();
    await first.save(entry);
    expect((await first.watchLibrary().first).keys, [entry.id]);

    final second = LocalLibraryRepository();
    final loaded = await second.watchLibrary().first;
    expect(loaded[entry.id]!.watches.single.note, 'Again!');

    await second.save(entry.removeWatch(0, now: now));
    expect(await second.watchLibrary().first, isEmpty);
  });

  test('the Firestore library uses typed document ids', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = FirestoreLibraryRepository(uid: 'u1', firestore: firestore);
    await repo.save(entry);
    final doc = await firestore.doc('users/u1/library/tv_1396').get();
    expect(doc.exists, isTrue);
    expect((await repo.watchLibrary().first)[entry.id]!.favorite, isTrue);

    await repo.remove(entry.id);
    expect(await repo.watchLibrary().first, isEmpty);
  });

  test('importing keeps whichever copy changed last', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = FirestoreLibraryRepository(uid: 'u1', firestore: firestore);
    final newer = entry.copyWith(updatedAt: now.add(const Duration(days: 1)), favorite: false);
    await repo.save(newer);
    await repo.importEntries([entry]);
    expect((await repo.watchLibrary().first)[entry.id]!.favorite, isFalse);
  });
}
