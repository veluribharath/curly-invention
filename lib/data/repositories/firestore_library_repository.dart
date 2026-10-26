import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:reel/data/models/library_entry_mapper.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/library_repository.dart';

/// The library in `users/{uid}/library`. Firestore's offline persistence
/// makes writes show at once and sync when the network is back.
class FirestoreLibraryRepository implements LibraryRepository {
  final FirebaseFirestore _firestore;
  final String uid;

  FirestoreLibraryRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _library =>
      _firestore.collection('users').doc(uid).collection('library');

  @override
  Stream<Map<TitleId, LibraryEntry>> watchLibrary() {
    return _library.snapshots().map((snapshot) {
      final entries = <TitleId, LibraryEntry>{};
      for (final doc in snapshot.docs) {
        final entry = LibraryEntryMapper.fromFirestore(doc.data());
        // The document id is the source of truth for which title it is.
        if (entry != null && TitleId.tryParse(doc.id) == entry.id) entries[entry.id] = entry;
      }
      return Map.unmodifiable(entries);
    });
  }

  @override
  Future<void> save(LibraryEntry entry) {
    final doc = _library.doc(entry.id.docId);
    return entry.isEmpty ? doc.delete() : doc.set(LibraryEntryMapper.toFirestore(entry));
  }

  @override
  Future<void> remove(TitleId id) => _library.doc(id.docId).delete();

  @override
  Future<void> clear() async {
    final docs = await _library.get();
    // Batches hold at most 500 writes.
    for (var i = 0; i < docs.docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final doc in docs.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Copies entries kept on the device into the account, keeping whichever
  /// copy of a title changed last.
  Future<void> importEntries(Iterable<LibraryEntry> entries) async {
    final existing = await _library.get();
    final updatedAt = <String, DateTime>{
      for (final doc in existing.docs)
        if (LibraryEntryMapper.fromFirestore(doc.data()) case final entry?) doc.id: entry.updatedAt,
    };
    final batch = _firestore.batch();
    var writes = 0;
    for (final entry in entries) {
      final theirs = updatedAt[entry.id.docId];
      if (entry.isEmpty || (theirs != null && !entry.updatedAt.isAfter(theirs))) continue;
      batch.set(_library.doc(entry.id.docId), LibraryEntryMapper.toFirestore(entry));
      if (++writes == 400) break;
    }
    if (writes > 0) await batch.commit();
  }
}
