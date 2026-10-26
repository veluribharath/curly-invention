import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:reel/data/repositories/availability_repositories.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/repositories/feed_signal_repository.dart';
import 'package:reel/domain/repositories/library_repository.dart';
import 'package:reel/domain/repositories/settings_repository.dart';
import 'package:reel/presentation/providers/discover_providers.dart';
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

/// Settings kept in memory.
class MemorySettingsRepository implements SettingsRepository {
  UserSettings? settings;
  final _changes = StreamController<UserSettings>.broadcast();

  MemorySettingsRepository([this.settings]);

  @override
  Stream<UserSettings> watchSettings({required UserSettings fallback}) async* {
    yield settings ?? fallback;
    yield* _changes.stream;
  }

  @override
  Future<void> save(UserSettings settings) async {
    this.settings = settings;
    _changes.add(settings);
  }

  @override
  Future<void> clear() async => settings = null;
}

/// Feed signals kept in memory.
class MemoryFeedSignalRepository implements FeedSignalRepository {
  final List<FeedSignal> signals;

  MemoryFeedSignalRepository([List<FeedSignal>? signals]) : signals = [...?signals];

  @override
  Future<void> record(FeedSignal signal) async => signals.add(signal);

  @override
  Future<List<FeedSignal>> since(DateTime since) async => [
    for (final s in signals)
      if (s.at.isAfter(since)) s,
  ];

  @override
  Future<void> clear() async => signals.clear();
}

final fixedNow = DateTime(2026, 10, 26, 20);

/// Onboarded in the US with Netflix and Max.
UserSettings onboardedSettings() =>
    UserSettings(country: 'US', serviceIds: const {8, 1899}, onboardedAt: DateTime(2026, 10, 1));

/// Overrides for running screens on mock data with an in-memory library.
List<Override> testOverrides({
  MemoryLibraryRepository? library,
  MemorySettingsRepository? settings,
  MemoryFeedSignalRepository? signals,
  DateTime? now,
}) {
  final repo = library ?? MemoryLibraryRepository();
  return [
    feedSignalRepositoryProvider.overrideWithValue(signals ?? MemoryFeedSignalRepository()),
    settingsRepositoryProvider.overrideWithValue(settings ?? MemorySettingsRepository(onboardedSettings())),
    availabilityRepositoryProvider.overrideWithValue(const MockAvailabilityRepository()),
    deviceCountryProvider.overrideWithValue('US'),
    catalogRepositoryProvider.overrideWithValue(const MockCatalogRepository()),
    libraryRepositoryProvider.overrideWithValue(repo),
    clockProvider.overrideWithValue(() => now ?? fixedNow),
    videoEmbedsEnabledProvider.overrideWithValue(false),
  ];
}
