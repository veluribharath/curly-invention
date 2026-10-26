import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/query_library.dart';
import 'package:reel/presentation/providers/library_view.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/library_actions.dart';
import 'package:reel/presentation/widgets/poster_image.dart';
import 'package:reel/presentation/widgets/service_logo.dart';
import 'package:reel/presentation/widgets/title_tile.dart';

/// Your watchlist, what you've watched, and your favorites.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final query = ref.watch(libraryViewProvider);
    final view = ref.read(libraryViewProvider.notifier);
    final grid = ref.watch(libraryGridProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: grid ? 'Show as list' : 'Show as grid',
            icon: Icon(grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => ref.read(libraryGridProvider.notifier).toggle(),
          ),
          PopupMenuButton<LibrarySort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: (sort) => view.update((q) => q.copyWith(sort: sort)),
            itemBuilder: (_) => [
              for (final sort in LibrarySort.values) PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
          ),
        ],
      ),
      body: AsyncBody<Map<TitleId, LibraryEntry>>(
        value: library,
        onRetry: () => ref.invalidate(libraryProvider),
        data: (entries) {
          final all = entries.values.toList();
          final segmentEntries = [
            for (final e in all)
              if (inSegment(e, query.segment)) e,
          ];
          final playable = ref.watch(playableOnMyServicesProvider);
          final shown = queryLibrary(all, query, isPlayable: playable);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LibrarySegment>(
                    showSelectedIcon: false,
                    segments: [
                      for (final segment in LibrarySegment.values)
                        ButtonSegment(
                          value: segment,
                          label: Text('${segment.label} ${all.where((e) => inSegment(e, segment)).length}'),
                        ),
                    ],
                    selected: {query.segment},
                    onSelectionChanged: (s) => view.setSegment(s.first),
                  ),
                ),
              ),
              _Filters(query: query, genres: libraryGenres(segmentEntries)),
              ...libraryBanners(context, ref, query, segmentEntries),
              Expanded(
                child: shown.isEmpty
                    ? _EmptyLibrary(segment: query.segment, filtered: segmentEntries.isNotEmpty)
                    : grid
                    ? _Grid(entries: shown)
                    : _List(entries: shown, segment: query.segment),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Whether a watchlist title streams on your services right now. Titles
/// whose availability hasn't loaded count as not playable.
final playableOnMyServicesProvider = Provider<bool Function(TitleId id)>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final availability = ref.watch(watchlistAvailabilityProvider).value ?? const {};
  return (id) =>
      settings != null &&
      (availability[id]?.isPlayableOn(settings.serviceIds, includeFree: settings.includeFreeWithAds) ?? false);
});

/// "7 of your watchlist are on your services", or a nudge to pick services.
List<Widget> libraryBanners(BuildContext context, WidgetRef ref, LibraryQuery query, List<LibraryEntry> entries) {
  if (query.segment != LibrarySegment.watchlist || entries.isEmpty) return const [];
  final settings = ref.watch(settingsProvider).value;
  if (settings == null) return const [];
  final scheme = Theme.of(context).colorScheme;
  if (settings.serviceIds.isEmpty && !settings.includeFreeWithAds) {
    return [
      ListTile(
        dense: true,
        leading: const Icon(Icons.live_tv),
        title: const Text('Pick your services to see what you can watch now'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/you/services'),
      ),
    ];
  }
  final playable = ref.watch(playableOnMyServicesProvider);
  final count = entries.where((e) => playable(e.id)).length;
  if (count == 0) return const [];
  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(libraryViewProvider.notifier).update((q) => q.copyWith(onMyServicesOnly: true)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.play_circle, color: scheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count of your watchlist ${count == 1 ? 'is' : 'are'} on your services',
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ];
}

class _Filters extends ConsumerWidget {
  final LibraryQuery query;
  final List<String> genres;

  const _Filters({required this.query, required this.genres});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.read(libraryViewProvider.notifier);
    final canFilterByService = query.segment == LibrarySegment.watchlist;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final kind in KindFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(kind.label),
                selected: query.kind == kind,
                onSelected: (_) => view.update((q) => q.copyWith(kind: kind)),
              ),
            ),
          if (canFilterByService)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: const Text('On my services'),
                selected: query.onMyServicesOnly,
                onSelected: (on) => view.update((q) => q.copyWith(onMyServicesOnly: on)),
              ),
            ),
          if (genres.isNotEmpty || query.genre != null)
            PopupMenuButton<String?>(
              tooltip: 'Genre',
              onSelected: (genre) => view.update((q) => q.copyWith(genre: () => genre)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Any genre')),
                for (final genre in genres) PopupMenuItem(value: genre, child: Text(genre)),
              ],
              child: Chip(
                label: Text(query.genre ?? 'Genre'),
                avatar: const Icon(Icons.arrow_drop_down, size: 18),
                backgroundColor: query.genre == null ? null : Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<LibraryEntry> entries;

  const _Grid({required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        childAspectRatio: 2 / 3.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return InkWell(
          onTap: () => openTitle(context, entry.snapshot),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PosterImage(title: entry.snapshot),
                  if (entry.favorite)
                    const Positioned(top: 4, right: 4, child: Icon(Icons.star, color: Colors.amber, size: 20)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  entry.snapshot.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _List extends ConsumerWidget {
  final List<LibraryEntry> entries;
  final LibrarySegment segment;

  const _List({required this.entries, required this.segment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(libraryActionsProvider);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final canMarkWatched = segment == LibrarySegment.watchlist;
        return Dismissible(
          key: ValueKey(entry.id),
          direction: canMarkWatched ? DismissDirection.horizontal : DismissDirection.endToStart,
          background: _SwipeBackground(
            color: Colors.green.shade700,
            icon: Icons.check,
            label: 'Watched',
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _SwipeBackground(
            color: Theme.of(context).colorScheme.error,
            icon: Icons.delete_outline,
            label: 'Remove',
            alignment: Alignment.centerRight,
          ),
          onDismissed: (direction) {
            final messenger = ScaffoldMessenger.of(context);
            if (direction == DismissDirection.startToEnd) {
              runLibraryAction(context, () => actions.markWatched(entry.snapshot), done: 'Marked watched');
              return;
            }
            actions.remove(entry.id);
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Removed ${entry.snapshot.name}'),
                  action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(entry)),
                ),
              );
          },
          child: TitleTile(
            title: entry.snapshot,
            subtitle: segment == LibrarySegment.watchlist ? _PlayableOn(entry: entry) : _EntrySummary(entry: entry),
          ),
        );
      },
    );
  }
}

class _EntrySummary extends StatelessWidget {
  final LibraryEntry entry;

  const _EntrySummary({required this.entry});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (entry.favorite) '★ Favorite',
      if (entry.latestRating != null) entry.latestRating!.label,
      if (entry.watches.length > 1) 'Watched ${entry.watches.length}×',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' · '), style: Theme.of(context).textTheme.labelSmall);
  }
}

class _PlayableOn extends ConsumerWidget {
  final LibraryEntry entry;

  const _PlayableOn({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final availability = ref.watch(watchlistAvailabilityProvider.select((a) => a.value?[entry.id]));
    if (settings == null || availability == null) return const SizedBox.shrink();
    final offers = availability.playableOn(settings.serviceIds, includeFree: settings.includeFreeWithAds);
    return ServiceLogoRow(offers: offers);
  }
}

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _SwipeBackground({required this.color, required this.icon, required this.label, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final LibrarySegment segment;
  final bool filtered;

  const _EmptyLibrary({required this.segment, required this.filtered});

  @override
  Widget build(BuildContext context) {
    if (filtered) return const EmptyMessage(icon: Icons.filter_alt_off, message: 'Nothing matches these filters.');
    final message = switch (segment) {
      LibrarySegment.watchlist => 'Save titles you want to watch and they show up here.',
      LibrarySegment.watched => "Log what you've watched to build your record.",
      LibrarySegment.favorites => 'Star the titles you love most.',
    };
    return EmptyMessage(
      icon: Icons.video_library_outlined,
      message: message,
      action: FilledButton.tonal(onPressed: () => context.go('/search'), child: const Text('Find something')),
    );
  }
}
