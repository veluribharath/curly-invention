import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/core/theme/reel_style.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/usecases/discover_feed.dart';
import 'package:reel/domain/usecases/query_library.dart';
import 'package:reel/presentation/providers/account_providers.dart';
import 'package:reel/presentation/providers/discover_providers.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/design_kit.dart';
import 'package:reel/presentation/widgets/library_actions.dart';
import 'package:reel/presentation/widgets/log_watch_sheet.dart';
import 'package:reel/presentation/widgets/poster_image.dart';
import 'package:reel/presentation/widgets/reel_clip_player.dart';
import 'package:reel/presentation/widgets/service_logo.dart';
import 'package:reel/presentation/widgets/title_meta.dart';
import 'package:reel/presentation/widgets/where_to_watch.dart';

/// The reels feed: one title per full-screen card, swiped vertically.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  /// Swiping past faster than this is a weak "not interested".
  static const _quickSkip = Duration(seconds: 2);

  // Not kept in page storage: a feed that starts over starts at the top.
  final _pages = PageController(keepPage: false);
  int _current = 0;
  DateTime _shownAt = DateTime.now();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final cards = ref.read(discoverFeedProvider).cards;
    final previous = _current < cards.length ? cards[_current] : null;
    if (previous != null && index > _current && DateTime.now().difference(_shownAt) < _quickSkip) {
      ref.read(feedSignalsProvider.notifier).record(previous.id, FeedSignalType.skippedFast);
    }
    setState(() {
      _current = index;
      _shownAt = DateTime.now();
    });
    if (index >= cards.length - 3) ref.read(discoverFeedProvider.notifier).loadMore();
  }

  /// Takes the card out and stays at the same index, which is now the next.
  void _removeCard(TitleId id) {
    ref.read(discoverFeedProvider.notifier).dismiss(id);
    _shownAt = DateTime.now();
    final remaining = ref.read(discoverFeedProvider).cards.length;
    if (_current >= remaining - 3) ref.read(discoverFeedProvider.notifier).loadMore();
  }

  void _resetPosition() {
    _current = 0;
    _shownAt = DateTime.now();
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(discoverFeedProvider);
    final filter = ref.watch(discoverFilterProvider);
    ref.listen(discoverFilterProvider, (_, _) => _resetPosition());
    // The feed starts over when services or the country change, too.
    ref.listen(discoverFeedProvider, (previous, next) {
      if (next.cards.isEmpty && (previous?.cards.isNotEmpty ?? false)) _resetPosition();
    });
    final current = _current < feed.cards.length ? feed.cards[_current] : null;
    final design = ref.watch(appDesignProvider);

    final screen = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The current card's backdrop, blurred, fills the screen around the
          // video.
          if (current != null)
            AnimatedSwitcher(
              duration: design == AppDesign.classic ? const Duration(milliseconds: 400) : context.reel.motion,
              child: ImageFiltered(
                key: ValueKey(current.id),
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: BackdropImage(path: current.title.backdropPath ?? current.title.posterPath),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _scrim(design)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _FilterBar(filter: filter),
                Expanded(child: _body(feed)),
              ],
            ),
          ),
        ],
      ),
    );
    // Discover is a dark room in every design; Classic keeps its old mix.
    return design == AppDesign.classic ? screen : Theme(data: AppTheme.dark(design), child: screen);
  }

  /// Darkens the blurred backdrop so text reads over it.
  static List<Color> _scrim(AppDesign design) => switch (design) {
    AppDesign.classic => const [Color(0xCC000000), Color(0x99000000), Color(0xEE000000)],
    AppDesign.marquee => const [Color(0xF00B0A08), Color(0xB30B0A08), Color(0xFA0B0A08)],
    AppDesign.aura => const [Color(0x99000000), Color(0x66000000), Color(0xE6000000)],
    AppDesign.pop => const [Color(0xE6130E22), Color(0xA62A1458), Color(0xF5130E22)],
  };

  Widget _body(DiscoverState feed) {
    final filter = ref.read(discoverFilterProvider);
    if (feed.needsServices) {
      return EmptyMessage(
        icon: Icons.live_tv,
        message: 'Pick the services you pay for, and Discover shows what you can watch on them right now.',
        action: Column(
          children: [
            FilledButton(onPressed: () => context.push('/you/services'), child: const Text('Pick services')),
            TextButton(
              onPressed: () => ref.read(discoverFilterProvider.notifier).set(filter.copyWith(myServicesOnly: false)),
              child: const Text('Show everything instead'),
            ),
          ],
        ),
      );
    }
    if (feed.cards.isEmpty) {
      if (feed.error != null) {
        return ErrorMessage(
          message: friendlyError(feed.error!),
          onRetry: () => ref.read(discoverFeedProvider.notifier).refresh(),
        );
      }
      if (feed.loading) return const Center(child: CircularProgressIndicator());
      return EmptyMessage(
        icon: Icons.movie_filter_outlined,
        message: filter.myServicesOnly
            ? 'Nothing new on your services for this filter. Try another, or show everything.'
            : 'Nothing new here. Try another filter.',
        action: FilledButton.tonal(
          onPressed: () => ref.read(discoverFeedProvider.notifier).refresh(),
          child: const Text('Refresh'),
        ),
      );
    }

    final muted = ref.watch(reelMutedProvider);
    // Off while another tab is showing or a screen covers Discover (both
    // turn tickers off), so the clip doesn't keep playing out of sight.
    final onScreen = TickerMode.valuesOf(context).enabled;
    return RefreshIndicator(
      onRefresh: () async {
        _resetPosition();
        ref.read(discoverFeedProvider.notifier).refresh();
      },
      child: PageView.builder(
        controller: _pages,
        scrollDirection: Axis.vertical,
        // Builds the next card ahead of time so its details and still are
        // ready when you swipe; only the current card gets a player.
        allowImplicitScrolling: true,
        onPageChanged: _onPageChanged,
        itemCount: feed.cards.length + (feed.exhausted ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= feed.cards.length) {
            return feed.error != null
                ? ErrorMessage(
                    message: friendlyError(feed.error!),
                    onRetry: () => ref.read(discoverFeedProvider.notifier).loadMore(),
                  )
                : const Center(child: CircularProgressIndicator());
          }
          final card = feed.cards[index];
          return ReelCard(
            key: ValueKey(card.id),
            card: card,
            live: index == _current && onScreen,
            muted: muted,
            onRemove: () => _removeCard(card.id),
          );
        },
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final FeedFilter filter;

  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(discoverFilterProvider.notifier);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final kind in KindFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(kind.label),
                selected: filter.kind == kind,
                onSelected: (_) => notifier.set(filter.copyWith(kind: kind)),
              ),
            ),
          const SizedBox(width: 6),
          FilterChip(
            avatar: const Icon(Icons.live_tv, size: 18),
            label: const Text('My services'),
            selected: filter.myServicesOnly,
            onSelected: (on) => notifier.set(filter.copyWith(myServicesOnly: on)),
          ),
        ],
      ),
    );
  }
}

/// One reel: the clip, what the title is and where it streams, and actions.
class ReelCard extends ConsumerWidget {
  final FeedCard card;
  final bool live;
  final bool muted;
  final VoidCallback onRemove;

  const ReelCard({super.key, required this.card, required this.live, required this.muted, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(titleDetailsProvider(card.id)).value ?? card.title;
    final settings = ref.watch(settingsProvider).value;
    final availability = ref.watch(availabilityProvider(card.id)).value;
    final mine = availability == null || settings == null
        ? const <Offer>[]
        : availability.playableOn(settings.serviceIds, includeFree: settings.includeFreeWithAds);
    final elsewhere = availability == null
        ? const <Offer>[]
        : [
            for (final o in availability.offers)
              if (o.type.isStreaming && !mine.any((m) => m.service == o.service)) o,
          ];
    final openable = mine.isNotEmpty ? mine.first : elsewhere.firstOrNull;
    final entry = ref.watch(libraryEntryProvider(card.id));
    final signals = ref.read(feedSignalsProvider.notifier);
    final override = ref.watch(clipOverrideProvider(card.id)).value;
    final textTheme = Theme.of(context).textTheme;
    final onWatchlist = entry?.onWatchlist ?? false;
    final design = context.reel.design;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReelClipPlayer(
                  title: title,
                  live: live,
                  muted: muted,
                  clipOverride: override,
                  onClipWatched: () => signals.record(card.id, FeedSignalType.watchedClip),
                ),
                SizedBox(height: design == AppDesign.classic ? 16 : 20),
                if (design == AppDesign.marquee) ...[
                  Eyebrow(titleMetaLine(title, withRating: false), color: Colors.white70),
                  const SizedBox(height: 6),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.name,
                        style: _titleStyle(textTheme, design),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: muted ? 'Sound on' : 'Sound off',
                      color: Colors.white,
                      icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                      onPressed: () {
                        ref.read(reelMutedProvider.notifier).set(!muted);
                        if (muted) signals.record(card.id, FeedSignalType.unmuted);
                      },
                    ),
                  ],
                ),
                if (design != AppDesign.marquee)
                  Text(titleMetaLine(title), style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                if (title.genres.isNotEmpty)
                  Text(
                    title.genres.take(3).join(design == AppDesign.marquee ? '  /  ' : ' · '),
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                SizedBox(height: design == AppDesign.classic ? 6 : 10),
                _Reason(text: card.reason),
                const SizedBox(height: 10),
                if (mine.isNotEmpty)
                  ServiceLogoRow(offers: mine, size: 30)
                else if (elsewhere.isNotEmpty)
                  Row(
                    children: [
                      Text('On ', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      ServiceLogoRow(offers: elsewhere, size: 24),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ReelAction(
                      icon: onWatchlist ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      label: 'Watchlist',
                      selected: onWatchlist,
                      onTap: () => runLibraryAction(
                        context,
                        () => ref.read(libraryActionsProvider).setWatchlist(title, !onWatchlist),
                        done: onWatchlist ? 'Removed from watchlist' : 'Added to watchlist',
                      ),
                    ),
                    _ReelAction(
                      icon: Icons.check_circle_outline,
                      label: 'Watched',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        // The card goes away, and its ref and context with it; the
                        // snack bar's action needs ones that stay.
                        final sheetContext = Navigator.of(context).context;
                        final container = ProviderScope.containerOf(context, listen: false);
                        final saved = await runLibraryAction(
                          context,
                          () => ref.read(libraryActionsProvider).markWatched(title),
                        );
                        if (!saved) return;
                        onRemove();
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('Marked ${title.name} watched'),
                              action: SnackBarAction(
                                label: 'Rate it',
                                onPressed: () {
                                  final watches = container.read(libraryEntryProvider(title.id))?.watches ?? const [];
                                  if (watches.isEmpty || !sheetContext.mounted) return;
                                  showLogWatchSheet(sheetContext, title, editIndex: watches.length - 1);
                                },
                              ),
                            ),
                          );
                      },
                    ),
                    _ReelAction(
                      icon: Icons.close,
                      label: 'Not for me',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        signals.record(card.id, FeedSignalType.notInterested);
                        onRemove();
                      },
                    ),
                    _ReelAction(
                      icon: Icons.info_outline,
                      label: 'Details',
                      onTap: () {
                        signals.record(card.id, FeedSignalType.openedDetails);
                        openTitle(context, title);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (openable != null)
                  HeroButton(
                    icon: const Icon(Icons.play_arrow),
                    label: 'Open in ${openable.service.name}',
                    onPressed: () {
                      signals.record(card.id, FeedSignalType.openedService);
                      openOffer(context, title, openable, fallback: availability?.link);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle? _titleStyle(TextTheme textTheme, AppDesign design) => switch (design) {
  AppDesign.classic => textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
  AppDesign.marquee => textTheme.headlineLarge?.copyWith(color: Colors.white, height: 1.05),
  AppDesign.aura => textTheme.headlineMedium?.copyWith(color: Colors.white, height: 1.1),
  AppDesign.pop => textTheme.headlineLarge?.copyWith(color: Colors.white, height: 0.95),
};

/// Why the feed picked this title: an italic aside (Classic), a serif
/// whisper in gold (Marquee), a frosted pill (Aura), a tilted sticker (Pop).
class _Reason extends StatelessWidget {
  final String text;

  const _Reason({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reel = context.reel;
    final style = theme.textTheme.bodyMedium;
    switch (reel.design) {
      case AppDesign.classic:
        return Text(
          text,
          style: style?.copyWith(color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
        );
      case AppDesign.marquee:
        return Text(
          text,
          style: style?.copyWith(
            fontFamily: 'Fraunces',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: theme.colorScheme.primary,
          ),
        );
      case AppDesign.aura:
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.6),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        text,
                        style: style?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case AppDesign.pop:
        return Transform.rotate(
          angle: -0.025,
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: reel
                .surface(color: reel.highlight, radius: 10)
                .copyWith(border: Border.all(color: const Color(0xFF17112A), width: 2)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                text,
                style: style?.copyWith(color: reel.onHighlight, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
    }
  }
}

class _ReelAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _ReelAction({required this.icon, required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reel = context.reel;
    final labelStyle = theme.textTheme.labelSmall;
    final scheme = theme.colorScheme;
    switch (reel.design) {
      case AppDesign.classic:
        final color = selected ? scheme.primary : Colors.white;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 4),
                  Text(label, style: labelStyle?.copyWith(color: color)),
                ],
              ),
            ),
          ),
        );
      case AppDesign.marquee:
        final color = selected ? scheme.primary : Colors.white;
        return Expanded(
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: selected ? scheme.primary : Colors.white24, width: selected ? 1.6 : 0.8),
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(label, style: labelStyle?.copyWith(color: color, fontSize: 10, letterSpacing: 1.4)),
                ],
              ),
            ),
          ),
        );
      case AppDesign.aura:
        return Expanded(
          child: PressScale(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                children: [
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: AnimatedContainer(
                        duration: reel.motion,
                        curve: reel.curve,
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.6),
                        ),
                        child: Icon(icon, color: selected ? Colors.black : Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: labelStyle?.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
        );
      case AppDesign.pop:
        const ink = Color(0xFF17112A);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PressScale(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: AnimatedContainer(
                  duration: reel.motion,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? reel.highlight : scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: reel.borderColor, width: 2),
                    boxShadow: [BoxShadow(color: reel.hardShadowColor, offset: const Offset(3, 3))],
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: selected ? ink : Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: labelStyle?.copyWith(color: selected ? ink : Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
