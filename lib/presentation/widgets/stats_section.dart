import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/domain/usecases/analyze_taste.dart';
import 'package:reel/presentation/providers/discover_providers.dart';
import 'package:reel/presentation/widgets/taste_charts.dart';

/// The You tab's stats: counts, hours, top genres and people, activity.
class StatsSection extends ConsumerWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taste = ref.watch(tasteProfileProvider);
    final textTheme = Theme.of(context).textTheme;
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
          Row(
            children: [
              _Stat(value: '${taste.watchedThisMonth}', label: 'this month'),
              _Stat(value: '${taste.watchedThisYear}', label: 'this year'),
              _Stat(value: formatHours(taste.minutesWatched), label: 'hours'),
              _Stat(value: '${taste.titlesWatched}', label: 'titles'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Last 12 weeks', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          WeeklyActivityChart(weeks: taste.weeks),
          if (taste.genres.any((g) => g.watched > 0)) ...[
            const SizedBox(height: 20),
            Text('Top genres', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            GenreBreakdown(genres: taste.genres),
          ],
          if (people.any((p) => p.watched >= 2 && p.affinity.score > 0)) ...[
            const SizedBox(height: 20),
            Text('People you keep coming back to', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            PeopleBreakdown(people: people),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.swipe),
              label: const Text('Rate more titles'),
              onPressed: () => context.push('/you/rate'),
            ),
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
