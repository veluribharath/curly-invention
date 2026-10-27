import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/usecases/query_library.dart';
import 'package:reel/presentation/providers/browse_providers.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/library_actions.dart';
import 'package:reel/presentation/widgets/poster_image.dart';
import 'package:reel/presentation/widgets/title_meta.dart';

/// An endless list of well-known movies, series and documentaries to rate,
/// mark seen, or save to the watchlist, one tap each.
class RateTitlesScreen extends ConsumerStatefulWidget {
  const RateTitlesScreen({super.key});

  @override
  ConsumerState<RateTitlesScreen> createState() => _RateTitlesScreenState();
}

class _RateTitlesScreenState extends ConsumerState<RateTitlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(browseFeedProvider.notifier).loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(browseFeedProvider);
    final notifier = ref.read(browseFeedProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Rate titles')),
      body: Column(
        children: [
          SizedBox(
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
                      selected: feed.kind == kind,
                      onSelected: (_) => notifier.setKind(kind),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _Body(feed: feed, onMore: notifier.loadMore),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final BrowseState feed;
  final VoidCallback onMore;

  const _Body({required this.feed, required this.onMore});

  @override
  Widget build(BuildContext context) {
    if (feed.titles.isEmpty) {
      if (feed.error != null) return ErrorMessage(message: friendlyError(feed.error!), onRetry: onMore);
      if (feed.loading || feed.hasMore) return const Center(child: CircularProgressIndicator());
      return const EmptyMessage(icon: Icons.check_circle_outline, message: "You've been through all of these.");
    }
    final extra = feed.hasMore || feed.error != null ? 1 : 0;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: feed.titles.length + extra,
      itemBuilder: (context, index) {
        // Fetch ahead, before the end comes into view.
        if (index >= feed.titles.length - 6) WidgetsBinding.instance.addPostFrameCallback((_) => onMore());
        if (index >= feed.titles.length) {
          return feed.error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text("Couldn't load more. ${friendlyError(feed.error!)}"),
                      onPressed: onMore,
                    ),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
        }
        return RateTile(title: feed.titles[index]);
      },
    );
  }
}

/// A title with one-tap Watchlist, Seen, and ratings.
class RateTile extends ConsumerWidget {
  final MediaTitle title;

  const RateTile({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(libraryEntryProvider(title.id));
    final actions = ref.read(libraryActionsProvider);
    final textTheme = Theme.of(context).textTheme;
    final watched = entry?.watched ?? false;
    final rating = entry?.latestRating;
    final onWatchlist = entry?.onWatchlist ?? false;
    // Only a quick "seen" from a list can be taken back here; dated watches
    // are edited in the diary or on the title.
    final quickSeen = entry != null && entry.watches.length == 1 && !entry.watches.single.dateKnown;

    void run(Future<void> Function() action) {
      HapticFeedback.selectionClick();
      runLibraryAction(context, action);
    }

    void rate(Rating r) => run(() => actions.rateSeen(title, rating == r ? null : r));

    return InkWell(
      onTap: () => openTitle(context, title),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosterImage(title: title, width: 72, radius: 6, size: 'w185'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.name, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(titleMetaLine(title), style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 0,
                    children: [
                      _Toggle(
                        label: 'Watchlist',
                        icon: Icons.bookmark_add_outlined,
                        selectedIcon: Icons.bookmark_added,
                        selected: onWatchlist,
                        onPressed: () => run(() => actions.setWatchlist(title, !onWatchlist)),
                      ),
                      _Toggle(
                        label: 'Seen',
                        icon: Icons.check_circle_outline,
                        selectedIcon: Icons.check_circle,
                        selected: watched,
                        onPressed: !watched
                            ? () => run(() => actions.rateSeen(title, null))
                            : quickSeen
                            ? () => run(() => actions.removeWatch(title, 0))
                            : () => openTitle(context, title),
                      ),
                      _Toggle(
                        label: 'Nah',
                        icon: Icons.thumb_down_outlined,
                        selectedIcon: Icons.thumb_down,
                        selected: rating == Rating.disliked,
                        onPressed: () => rate(Rating.disliked),
                      ),
                      _Toggle(
                        label: 'Liked',
                        icon: Icons.thumb_up_outlined,
                        selectedIcon: Icons.thumb_up,
                        selected: rating == Rating.liked,
                        onPressed: () => rate(Rating.liked),
                      ),
                      _Toggle(
                        label: 'Loved',
                        icon: Icons.favorite_border,
                        selectedIcon: Icons.favorite,
                        selected: rating == Rating.loved,
                        onPressed: () => rate(Rating.loved),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  const _Toggle({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: label,
            isSelected: selected,
            visualDensity: VisualDensity.compact,
            icon: Icon(icon, color: color),
            selectedIcon: Icon(selectedIcon, color: color),
            onPressed: onPressed,
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
