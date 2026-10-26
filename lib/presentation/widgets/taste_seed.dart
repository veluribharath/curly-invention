import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipable_stack/swipable_stack.dart';

import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/poster_image.dart';
import 'package:reel/presentation/widgets/title_meta.dart';

/// Well-known movies and series to rate, ones not in your library yet.
final seedCandidatesProvider = FutureProvider.autoDispose<List<MediaTitle>>((ref) async {
  final catalog = ref.watch(catalogRepositoryProvider);
  final pages = await Future.wait([
    for (final page in [1, 2])
      for (final type in MediaType.values)
        catalog.discover(DiscoverQuery(type: type, page: page, minVotes: type == MediaType.movie ? 3000 : 1000)),
  ]);
  final library = ref.read(libraryProvider).value ?? const {};
  final seen = <TitleId>{};
  final movies = [for (final p in pages) ...p.titles.where((t) => t.type == MediaType.movie)];
  final shows = [for (final p in pages) ...p.titles.where((t) => t.type == MediaType.tv)];
  final mixed = <MediaTitle>[];
  for (var i = 0; i < movies.length || i < shows.length; i++) {
    // About two movies for each series.
    if (i < movies.length) mixed.add(movies[i]);
    if (i.isOdd && i ~/ 2 < shows.length) mixed.add(shows[i ~/ 2]);
  }
  return [
    for (final t in mixed)
      if (!library.containsKey(t.id) && seen.add(t.id)) t,
  ].take(40).toList();
});

/// The resonance swipe deck, reused to seed your taste: right = seen and
/// liked, left = seen and didn't like, up = want to watch, down = haven't
/// seen. Each swipe goes straight into the library.
class TasteSeedDeck extends ConsumerStatefulWidget {
  /// Called when you're done or the deck runs out, with how many you rated.
  final ValueChanged<int> onDone;
  final String doneLabel;

  const TasteSeedDeck({super.key, required this.onDone, this.doneLabel = 'Done'});

  @override
  ConsumerState<TasteSeedDeck> createState() => _TasteSeedDeckState();
}

class _TasteSeedDeckState extends ConsumerState<TasteSeedDeck> {
  final _controller = SwipableStackController();
  int _rated = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSwipe(MediaTitle title, SwipeDirection direction) async {
    final actions = ref.read(libraryActionsProvider);
    final now = ref.read(clockProvider)();
    final messenger = ScaffoldMessenger.maybeOf(context);
    unawaited(HapticFeedback.selectionClick());
    final Future<void> Function()? save = switch (direction) {
      SwipeDirection.right => () => actions.logWatch(title, WatchEvent(watchedAt: now, rating: Rating.liked)),
      SwipeDirection.left => () => actions.logWatch(title, WatchEvent(watchedAt: now, rating: Rating.disliked)),
      SwipeDirection.up => () => actions.setWatchlist(title, true),
      SwipeDirection.down => null,
    };
    if (save == null) return;
    // Counted at once: the deck can be left (Done) before the save lands.
    setState(() => _rated++);
    try {
      await save();
    } catch (e) {
      if (mounted) setState(() => _rated--);
      messenger?.showSnackBar(SnackBar(content: Text("Couldn't save ${title.name}: ${friendlyError(e)}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(seedCandidatesProvider);
    return AsyncBody<List<MediaTitle>>(
      value: candidates,
      onRetry: () => ref.invalidate(seedCandidatesProvider),
      data: (titles) => Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Stack(
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => _controller.currentIndex >= titles.length
                        ? EmptyMessage(
                            icon: Icons.check_circle_outline,
                            message: "That's all for now. You rated $_rated.",
                            action: FilledButton(onPressed: () => widget.onDone(_rated), child: Text(widget.doneLabel)),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SwipableStack(
                    controller: _controller,
                    itemCount: titles.length,
                    allowVerticalSwipe: true,
                    detectableSwipeDirections: const {
                      SwipeDirection.right,
                      SwipeDirection.left,
                      SwipeDirection.up,
                      SwipeDirection.down,
                    },
                    onSwipeCompleted: (index, direction) {
                      if (index < titles.length) _onSwipe(titles[index], direction);
                    },
                    builder: (context, properties) => _SeedCard(title: titles[properties.index]),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DeckButton(
                  icon: Icons.thumb_down_outlined,
                  label: "Didn't like",
                  onTap: () => _controller.next(swipeDirection: SwipeDirection.left),
                ),
                _DeckButton(
                  icon: Icons.visibility_off_outlined,
                  label: "Haven't seen",
                  onTap: () => _controller.next(swipeDirection: SwipeDirection.down),
                ),
                _DeckButton(
                  icon: Icons.bookmark_add_outlined,
                  label: 'Want to watch',
                  onTap: () => _controller.next(swipeDirection: SwipeDirection.up),
                ),
                _DeckButton(
                  icon: Icons.thumb_up_outlined,
                  label: 'Liked',
                  onTap: () => _controller.next(swipeDirection: SwipeDirection.right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => widget.onDone(_rated),
                child: Text(_rated == 0 ? 'Skip' : '${widget.doneLabel} · $_rated rated'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedCard extends StatelessWidget {
  final MediaTitle title;

  const _SeedCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PosterImage(title: title, radius: 0, size: 'w500'),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(titleMetaLine(title, withRating: false), style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DeckButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(onPressed: onTap, icon: Icon(icon), tooltip: label),
          Text(label, textAlign: TextAlign.center, maxLines: 2, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
