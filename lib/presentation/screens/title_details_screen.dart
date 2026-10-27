import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/reel_style.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';
import 'package:reel/domain/usecases/build_title_share.dart';
import 'package:reel/domain/usecases/pick_video.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/design_kit.dart';
import 'package:reel/presentation/widgets/inline_youtube_view.dart';
import 'package:reel/presentation/widgets/library_actions.dart';
import 'package:reel/presentation/widgets/log_watch_sheet.dart';
import 'package:reel/presentation/widgets/poster_image.dart';
import 'package:reel/presentation/widgets/title_meta.dart';
import 'package:reel/presentation/widgets/where_to_watch.dart';

/// Everything about one movie or series, and what you've done with it.
class TitleDetailsScreen extends ConsumerWidget {
  final TitleId id;

  /// What the previous screen knew, shown while the details load.
  final MediaTitle? preview;

  const TitleDetailsScreen({super.key, required this.id, this.preview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(titleDetailsProvider(id));
    final saved = ref.watch(libraryEntryProvider(id))?.snapshot;
    final title = details.value ?? preview ?? saved;

    if (title == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncBody(
          value: details,
          onRetry: () => ref.invalidate(titleDetailsProvider(id)),
          data: (_) => const SizedBox(),
        ),
      );
    }

    final design = context.reel.design;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: title.backdropPath == null ? null : _backdropHeight(design),
            actions: [
              IconButton(tooltip: 'Share', icon: const Icon(Icons.share), onPressed: () => _share(context, title)),
            ],
            flexibleSpace: title.backdropPath == null
                ? null
                : FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        BackdropImage(path: title.backdropPath),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Theme.of(context).colorScheme.surface],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SliverToBoxAdapter(child: _Header(title: title)),
          SliverToBoxAdapter(child: _LibraryBar(title: title)),
          SliverToBoxAdapter(child: _WatchHistory(title: title)),
          if (details.hasError && !details.hasValue)
            SliverToBoxAdapter(
              child: ErrorMessage(
                message: "Couldn't load all details. ${friendlyError(details.error!)}",
                onRetry: () => ref.invalidate(titleDetailsProvider(id)),
              ),
            ),
          if (details.isLoading && !details.hasValue)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (details.value case final full?) ...[
            SliverToBoxAdapter(child: _Trailer(title: full)),
            if (full.overview.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    full.overview,
                    style: design == AppDesign.marquee
                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)
                        : null,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: WhereToWatch(title: full)),
            SliverToBoxAdapter(child: _People(title: full)),
          ],
          SliverToBoxAdapter(child: _MoreLikeThis(id: id)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  static double _backdropHeight(AppDesign design) => switch (design) {
    AppDesign.classic => 220,
    AppDesign.marquee => 300,
    AppDesign.aura => 260,
    AppDesign.pop => 240,
  };

  Future<void> _share(BuildContext context, MediaTitle title) async {
    final share = buildTitleShare(id: title.id, name: title.name, year: title.year);
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: share.text,
        subject: share.subject,
        // iPad shows the share sheet as a popover.
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MediaTitle title;

  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final reel = context.reel;
    switch (reel.design) {
      case AppDesign.classic:
        break;
      // A program note: credits caption, serif title, genres in gold.
      case AppDesign.marquee:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PosterImage(title: title, width: 112),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(titleMetaLine(title, withRating: false)),
                    const SizedBox(height: 8),
                    Text(title.name, style: textTheme.headlineMedium?.copyWith(height: 1.08)),
                    if (title.voteAverage != null && title.voteAverage! > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '★ ${title.voteAverage!.toStringAsFixed(1)}',
                        style: textTheme.titleSmall?.copyWith(color: scheme.primary),
                      ),
                    ],
                    if (title.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        title.genres.join('  /  '),
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'Fraunces',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      // Centered and quiet: a floating poster over the backdrop.
      case AppDesign.aura:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              PosterImage(title: title, width: 150),
              const SizedBox(height: 20),
              Column(
                children: [
                  Text(title.name, textAlign: TextAlign.center, style: textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    titleMetaLine(title),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (title.genres.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final genre in title.genres)
                          Chip(label: Text(genre), visualDensity: VisualDensity.compact),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      // Big type and a sticker per genre.
      case AppDesign.pop:
        final stickers = [reel.highlight, scheme.secondary, scheme.tertiary, scheme.primaryContainer];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.rotate(angle: -0.04, child: PosterImage(title: title, width: 110)),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      titleMetaLine(title),
                      style: textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(title.name, style: textTheme.displaySmall?.copyWith(height: 0.98)),
              if (title.genres.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, genre) in title.genres.indexed)
                      Transform.rotate(
                        angle: i.isEven ? -0.03 : 0.03,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: reel
                              .surface(color: stickers[i % stickers.length], radius: 99)
                              .copyWith(
                                boxShadow: [BoxShadow(color: reel.hardShadowColor, offset: const Offset(2, 2))],
                              ),
                          child: Text(
                            genre,
                            style: textTheme.labelLarge?.copyWith(
                              color:
                                  ThemeData.estimateBrightnessForColor(stickers[i % stickers.length]) == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF17112A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PosterImage(title: title, width: 110),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(titleMetaLine(title), style: textTheme.bodyMedium),
                const SizedBox(height: 6),
                if (title.genres.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final genre in title.genres)
                        Chip(label: Text(genre), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBar extends ConsumerWidget {
  final MediaTitle title;

  const _LibraryBar({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(libraryEntryProvider(title.id));
    final actions = ref.read(libraryActionsProvider);
    final onWatchlist = entry?.onWatchlist ?? false;
    final favorite = entry?.favorite ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: onWatchlist
                ? FilledButton.icon(
                    icon: const Icon(Icons.bookmark_added),
                    label: const Text('On watchlist'),
                    onPressed: () => runLibraryAction(context, () => actions.setWatchlist(title, false)),
                  )
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Watchlist'),
                    onPressed: () =>
                        runLibraryAction(context, () => actions.setWatchlist(title, true), done: 'Added to watchlist'),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              icon: Icon(entry?.watched ?? false ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(entry?.watched ?? false ? 'Log again' : 'Log a watch'),
              onPressed: () => showLogWatchSheet(context, title),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: favorite ? 'Remove favorite' : 'Favorite',
            isSelected: favorite,
            icon: const Icon(Icons.star_border),
            selectedIcon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () => runLibraryAction(context, () => actions.setFavorite(title, !favorite)),
          ),
        ],
      ),
    );
  }
}

class _WatchHistory extends ConsumerWidget {
  final MediaTitle title;

  const _WatchHistory({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watches = ref.watch(libraryEntryProvider(title.id))?.watches ?? const [];
    if (watches.isEmpty) return const SizedBox.shrink();
    final localizations = MaterialLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = watches.length - 1; i >= 0; i--)
            ListTile(
              dense: true,
              leading: Icon(_ratingIcon(watches[i].rating)),
              title: Text(
                '${i == 0 ? 'Watched' : 'Rewatched'} '
                '${watches[i].dateKnown ? localizations.formatMediumDate(watches[i].watchedAt) : 'before'}'
                '${watches[i].rating == null ? '' : ' · ${watches[i].rating!.label}'}',
              ),
              subtitle: watches[i].note == null ? null : Text(watches[i].note!),
              onTap: () => showLogWatchSheet(context, title, editIndex: i),
              trailing: IconButton(
                tooltip: 'Delete this watch',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => runLibraryAction(
                  context,
                  () => ref.read(libraryActionsProvider).removeWatch(title, i),
                  done: 'Watch removed',
                ),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _ratingIcon(Rating? rating) => switch (rating) {
    Rating.loved => Icons.favorite,
    Rating.liked => Icons.thumb_up,
    Rating.disliked => Icons.thumb_down,
    null => Icons.check,
  };
}

class _Trailer extends ConsumerStatefulWidget {
  final MediaTitle title;

  const _Trailer({required this.title});

  @override
  ConsumerState<_Trailer> createState() => _TrailerState();
}

class _TrailerState extends ConsumerState<_Trailer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final video = pickTrailer(widget.title.videos);
    if (video != null && ref.read(videoEmbedsEnabledProvider)) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: video.key,
        // Not inline: on iOS the trailer opens in the system player, which is
        // full screen.
        params: const YoutubePlayerParams(showFullscreenButton: true, playsInline: false),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: InlineYoutubeView(controller: controller),
        ),
      ),
    );
  }
}

class _People extends StatelessWidget {
  final MediaTitle title;

  const _People({required this.title});

  @override
  Widget build(BuildContext context) {
    if (!title.hasCredits) return const SizedBox.shrink();
    final makers = title.type == MediaType.movie ? 'Directed by' : 'Created by';
    Widget chips(List<Person> people) => Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final person in people)
          ActionChip(
            label: Text(person.name),
            onPressed: () => context.push('/person/${person.id}?name=${Uri.encodeQueryComponent(person.name)}'),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.directors.isNotEmpty) ...[
            SectionHeader(makers),
            const SizedBox(height: 6),
            chips(title.directors),
            const SizedBox(height: 12),
          ],
          if (title.cast.isNotEmpty) ...[const SectionHeader('Cast'), const SizedBox(height: 6), chips(title.cast)],
        ],
      ),
    );
  }
}

class _MoreLikeThis extends ConsumerWidget {
  final TitleId id;

  const _MoreLikeThis({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(similarTitlesProvider(id)).value ?? const [];
    if (similar.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: TitleRow(label: 'More like this', titles: similar),
    );
  }
}

/// A labeled, horizontally scrolling row of posters.
class TitleRow extends StatelessWidget {
  final String label;
  final List<MediaTitle> titles;

  const TitleRow({super.key, required this.label, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SectionHeader(label)),
        const SizedBox(height: 8),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: titles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final title = titles[index];
              return SizedBox(
                width: 100,
                child: InkWell(
                  onTap: () => openTitle(context, title),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosterImage(title: title, width: 100, size: 'w185', compact: true),
                      const SizedBox(height: 4),
                      Text(
                        title.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
