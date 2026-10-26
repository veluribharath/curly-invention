import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:reel/data/models/library_entry_mapper.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/library_repository.dart';

/// Keeps the library on the device only, as one JSON list in shared
/// preferences. Used when Firebase is off.
class LocalLibraryRepository implements LibraryRepository {
  static const _key = 'library.v1';

  final Future<SharedPreferences> _prefs;
  final _changes = StreamController<Map<TitleId, LibraryEntry>>.broadcast();
  Map<TitleId, LibraryEntry>? _cache;

  /// The first load, shared by everyone who asks while it runs.
  Future<Map<TitleId, LibraryEntry>>? _loading;

  /// Changes run one at a time: each reads what the last one wrote, so
  /// quick saves (the taste deck) don't drop each other.
  Future<void> _pending = Future.value();

  LocalLibraryRepository({Future<SharedPreferences>? prefs}) : _prefs = prefs ?? SharedPreferences.getInstance();

  Future<Map<TitleId, LibraryEntry>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    return _loading ??= _read();
  }

  Future<Map<TitleId, LibraryEntry>> _read() async {
    final raw = (await _prefs).getString(_key);
    final entries = <TitleId, LibraryEntry>{};
    if (raw != null) {
      try {
        for (final item in json.decode(raw) as List) {
          if (item is! Map<String, dynamic>) continue;
          final entry = LibraryEntryMapper.fromJson(item);
          if (entry != null) entries[entry.id] = entry;
        }
      } on FormatException {
        // A corrupt cache starts over rather than locking the app up.
      }
    }
    return _cache ??= entries;
  }

  Future<void> _write(Map<TitleId, LibraryEntry> entries) async {
    _cache = entries;
    _changes.add(Map.unmodifiable(entries));
    final encoded = json.encode([for (final entry in entries.values) LibraryEntryMapper.toJson(entry)]);
    await (await _prefs).setString(_key, encoded);
  }

  @override
  Stream<Map<TitleId, LibraryEntry>> watchLibrary() async* {
    yield Map.unmodifiable(await _load());
    yield* _changes.stream;
  }

  @override
  Future<void> save(LibraryEntry entry) => _serial(() async {
    final entries = {...await _load()};
    if (entry.isEmpty) {
      entries.remove(entry.id);
    } else {
      entries[entry.id] = entry;
    }
    await _write(entries);
  });

  @override
  Future<void> remove(TitleId id) => _serial(() async {
    final entries = {...await _load()}..remove(id);
    await _write(entries);
  });

  @override
  Future<void> clear() => _serial(() => _write({}));

  Future<void> _serial(Future<void> Function() change) {
    final done = _pending.then((_) => change());
    _pending = done.catchError((Object _) {});
    return done;
  }

  /// Every entry, for moving the library into an account.
  Future<List<LibraryEntry>> all() async => (await _load()).values.toList();
}
