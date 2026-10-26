import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/library_repository.dart';
import 'package:reel/presentation/providers/providers.dart';

/// A library kept in memory.
class MemoryLibraryRepository implements LibraryRepository {
  final Map<TitleId, LibraryEntry> entries;
  final _changes = StreamController<Map<TitleId, LibraryEntry>>.broadcast();

  MemoryLibraryRepository([Map<TitleId, LibraryEntry>? entries]) : entries = {...?entries};

  @override
  Stream<Map<TitleId, LibraryEntry>> watchLibrary() async* {
    yield Map.unmodifiable(entries);
    yield* _changes.stream;
  }

  void _emit() => _changes.add(Map.unmodifiable(entries));

  @override
  Future<void> save(LibraryEntry entry) async {
    entry.isEmpty ? entries.remove(entry.id) : entries[entry.id] = entry;
    _emit();
  }

  @override
  Future<void> remove(TitleId id) async {
    entries.remove(id);
    _emit();
  }

  @override
  Future<void> clear() async {
    entries.clear();
    _emit();
  }
}

final fixedNow = DateTime(2026, 10, 26, 20);

/// Overrides for running screens on mock data with an in-memory library.
List<Override> testOverrides({MemoryLibraryRepository? library, DateTime? now}) {
  final repo = library ?? MemoryLibraryRepository();
  return [
    catalogRepositoryProvider.overrideWithValue(const MockCatalogRepository()),
    libraryRepositoryProvider.overrideWithValue(repo),
    clockProvider.overrideWithValue(() => now ?? fixedNow),
    videoEmbedsEnabledProvider.overrideWithValue(false),
  ];
}
