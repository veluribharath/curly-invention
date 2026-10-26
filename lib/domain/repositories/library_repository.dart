import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';

/// Your library, on the device or in Firestore.
abstract class LibraryRepository {
  /// Every entry, again after each change. Emits the current library first.
  Stream<Map<TitleId, LibraryEntry>> watchLibrary();

  /// Saves [entry], or deletes it when it holds nothing any more.
  Future<void> save(LibraryEntry entry);

  Future<void> remove(TitleId id);

  /// Deletes every entry, e.g. when the account is deleted.
  Future<void> clear();
}
