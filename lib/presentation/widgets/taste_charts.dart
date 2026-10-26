import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:reel/domain/usecases/analyze_taste.dart';

/// Watched titles per genre as bars, tinted by how much you liked them.
/// Adapted from resonance's `GenreBreakdown`.
class GenreBreakdown extends StatelessWidget {
  final List<GenreTaste> genres;
  final int maxGenres;

  const GenreBreakdown({super.key, required this.genres, this.maxGenres = 6});

  @override
  Widget build(BuildContext context) {
    final shown = (genres.where((g) => g.watched > 0).toList()..sort((a, b) => b.watched.compareTo(a.watched)))
        .take(maxGenres)
        .toList();
    final most = shown.fold<int>(0, (m, g) => max(m, g.watched));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final genre in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(genre.genre, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 10,
                        width: constraints.maxWidth * (most == 0 ? 0 : genre.watched / most),
                        decoration: BoxDecoration(
                          // Liked genres in the primary color, disliked ones muted.
                          color: Color.lerp(scheme.outline, scheme.primary, (genre.affinity.score + 1) / 2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text('${genre.watched}', textAlign: TextAlign.end, style: textTheme.bodySmall),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Directors and actors you keep coming back to, as chips.
class PeopleBreakdown extends StatelessWidget {
  final List<PersonTaste> people;
  final int maxPeople;

  const PeopleBreakdown({super.key, required this.people, this.maxPeople = 6});

  @override
  Widget build(BuildContext context) {
    final shown = people.where((p) => p.watched >= 2 && p.affinity.score > 0).take(maxPeople);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in shown)
          Chip(
            avatar: Icon(
              p.role == PersonRole.director ? Icons.movie_creation_outlined : Icons.person_outline,
              size: 16,
            ),
            label: Text('${p.person.name} · ${p.watched}'),
          ),
      ],
    );
  }
}

/// Watches per week as bars, oldest week on the left.
class WeeklyActivityChart extends StatelessWidget {
  final List<WeeklyActivity> weeks;

  const WeeklyActivityChart({super.key, required this.weeks});

  @override
  Widget build(BuildContext context) {
    final maxY = max(4, maxWeekly(weeks)).toDouble();
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    final color = Theme.of(context).colorScheme.primary;
    final interval = max(1, (maxY / 4).ceil()).toDouble();
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: interval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  // Every third week, so dates don't crowd on phones.
                  if (index < 0 || index >= weeks.length || (weeks.length - 1 - index) % 3 != 0) {
                    return const SizedBox.shrink();
                  }
                  final start = weeks[index].weekStart;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${start.month}/${start.day}', style: labelStyle),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < weeks.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [BarChartRodData(toY: weeks[i].watches.toDouble(), color: color, width: 10)],
              ),
          ],
        ),
      ),
    );
  }
}
