import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/build_diary.dart';
import 'package:reel/domain/usecases/query_library.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/log_watch_sheet.dart';
import 'package:reel/presentation/widgets/title_tile.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// Everything you've watched, by date, month by month. Rewatches show
/// again on the day you watched them.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  KindFilter _kind = KindFilter.all;

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diary')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Log a watch'),
        onPressed: () => context.go('/search'),
      ),
      body: AsyncBody<Map<TitleId, LibraryEntry>>(
        value: library,
        onRetry: () => ref.invalidate(libraryProvider),
        data: (entries) {
          final diary = buildDiary(entries.values, kind: _kind);
          return Column(
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
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: diary.isEmpty
                    ? EmptyMessage(
                        icon: Icons.menu_book_outlined,
                        message: entries.values.any((e) => e.watched)
                            ? 'Nothing matches this filter.'
                            : 'Log what you watch and it shows up here by date. Add things whenever you remember them.',
                        action: FilledButton.tonal(
                          onPressed: () => context.push('/library/rate'),
                          child: const Text('Rate titles you know'),
                        ),
                      )
                    : _DiaryList(items: diary),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryList extends StatelessWidget {
  final List<DiaryItem> items;

  const _DiaryList({required this.items});

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final rows = <Widget>[];
    String? month;
    for (final item in items) {
      final date = item.watch.watchedAt.toLocal();
      final label = item.watch.dateKnown ? localizations.formatMonthYear(date) : 'Seen before, no date';
      if (label != month) {
        month = label;
        rows.add(Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: SectionHeader(label)));
      }
      rows.add(_DiaryRow(item: item, day: item.watch.dateKnown ? '${date.day}' : ''));
    }
    return ListView(
      padding: EdgeInsets.only(bottom: 96 + MediaQuery.paddingOf(context).bottom),
      children: rows,
    );
  }
}

class _DiaryRow extends StatelessWidget {
  final DiaryItem item;
  final String day;

  const _DiaryRow({required this.item, required this.day});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final watch = item.watch;
    final parts = [
      if (watch.rating != null) watch.rating!.label,
      if (item.rewatch) 'Rewatch',
      if (watch.note?.trim().isNotEmpty ?? false) '“${watch.note!.trim()}”',
    ];
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(day, textAlign: TextAlign.end, style: textTheme.titleLarge),
        ),
        Expanded(
          child: TitleTile(
            title: item.entry.snapshot,
            subtitle: parts.isEmpty
                ? null
                : Text(parts.join(' · '), style: textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit this watch',
              onPressed: () => showLogWatchSheet(context, item.entry.snapshot, editIndex: item.watchIndex),
            ),
          ),
        ),
      ],
    );
  }
}
