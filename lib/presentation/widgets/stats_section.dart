import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/reel_style.dart';
import 'package:reel/domain/usecases/analyze_taste.dart';
import 'package:reel/presentation/providers/discover_providers.dart';
import 'package:reel/presentation/widgets/taste_charts.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// The You tab's stats: counts, hours, top genres and people, activity.
class StatsSection extends ConsumerWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taste = ref.watch(tasteProfileProvider);
    if (taste.titlesWatched == 0) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: ListTile(
          leading: const Icon(Icons.insights),
          title: const Text('Your stats start with your first watch'),
          subtitle: const Text('Rate a few titles you know to get going.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/you/rate'),
        ),
      );
    }
    final people = [...taste.directors, ...taste.actors]..sort((a, b) => b.watched.compareTo(a.watched));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Stats(
            stats: [
              ('${taste.watchedThisMonth}', 'this month'),
              ('${taste.watchedThisYear}', 'this year'),
              (formatHours(taste.minutesWatched), 'hours'),
              ('${taste.titlesWatched}', 'titles'),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader('Last 12 weeks'),
          const SizedBox(height: 8),
          WeeklyActivityChart(weeks: taste.weeks),
          if (taste.genres.any((g) => g.watched > 0)) ...[
            const SizedBox(height: 20),
            const SectionHeader('Top genres'),
            const SizedBox(height: 8),
            GenreBreakdown(genres: taste.genres),
          ],
          if (people.any((p) => p.watched >= 2 && p.affinity.score > 0)) ...[
            const SizedBox(height: 20),
            const SectionHeader('People you keep coming back to'),
            const SizedBox(height: 8),
            PeopleBreakdown(people: people),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.thumbs_up_down_outlined),
              label: const Text('Rate more titles'),
              onPressed: () => context.push('/you/rate'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline numbers: a plain row (Classic), a credits-style row with
/// hairline rules (Marquee), soft tiles led by a gradient one (Aura), or
/// colored stickers (Pop).
class _Stats extends StatelessWidget {
  final List<(String, String)> stats;

  const _Stats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final reel = context.reel;
    switch (reel.design) {
      case AppDesign.classic:
        return Row(
          children: [for (final (value, label) in stats) _Stat(value: value, label: label)],
        );
      case AppDesign.marquee:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: scheme.primary.withValues(alpha: 0.4), width: 0.8)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, (value, label)) in stats.indexed) ...[
                  if (i > 0) VerticalDivider(width: 1, color: scheme.outlineVariant),
                  Expanded(
                    child: Column(
                      children: [
                        Text(value, style: textTheme.headlineMedium?.copyWith(color: scheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case AppDesign.aura:
      case AppDesign.pop:
        final pop = reel.design == AppDesign.pop;
        final fills = pop
            ? [reel.highlight, scheme.secondary, scheme.primaryContainer, scheme.surfaceContainer]
            : [null, scheme.surfaceContainerLow, scheme.surfaceContainerLow, scheme.surfaceContainerLow];
        Widget tile(int i) => Transform.rotate(
          angle: pop ? (i.isEven ? -0.015 : 0.015) : 0,
          child: _Tile(value: stats[i].$1, label: stats[i].$2, fill: fills[i]),
        );
        // Rows size to their text, so large text scales don't clip.
        return Column(
          children: [
            for (var i = 0; i < stats.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tile(i)),
                    const SizedBox(width: 12),
                    Expanded(child: i + 1 < stats.length ? tile(i + 1) : const SizedBox()),
                  ],
                ),
              ),
            ],
          ],
        );
    }
  }
}

class _Tile extends StatelessWidget {
  final String value;
  final String label;

  /// Null fills the tile with the design's gradient.
  final Color? fill;

  const _Tile({required this.value, required this.label, required this.fill});

  @override
  Widget build(BuildContext context) {
    final reel = context.reel;
    final textTheme = Theme.of(context).textTheme;
    final fill = this.fill;
    final ink = fill == null
        ? Colors.white
        : ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : const Color(0xFF17112A);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: reel.surface(color: fill, gradient: fill == null ? reel.accentGradient : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelLarge?.copyWith(color: ink.withValues(alpha: 0.8))),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: textTheme.headlineLarge?.copyWith(color: ink, height: 1)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
