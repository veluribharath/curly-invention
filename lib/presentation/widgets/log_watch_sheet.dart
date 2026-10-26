import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/library_actions.dart';

/// Opens the sheet to log a watch of [title], or to edit the watch at
/// [editIndex] when given.
Future<void> showLogWatchSheet(BuildContext context, MediaTitle title, {int? editIndex}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => LogWatchSheet(title: title, editIndex: editIndex),
  );
}

class LogWatchSheet extends ConsumerStatefulWidget {
  final MediaTitle title;
  final int? editIndex;

  const LogWatchSheet({super.key, required this.title, this.editIndex});

  @override
  ConsumerState<LogWatchSheet> createState() => _LogWatchSheetState();
}

class _LogWatchSheetState extends ConsumerState<LogWatchSheet> {
  late DateTime _date;
  Rating? _rating;
  late bool _favorite;
  final _note = TextEditingController();

  WatchEvent? get _editing {
    final index = widget.editIndex;
    final watches = ref.read(libraryEntryProvider(widget.title.id))?.watches;
    return index == null || watches == null || index >= watches.length ? null : watches[index];
  }

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final editing = _editing;
    _date = editing?.watchedAt ?? DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _rating = editing?.rating;
    _note.text = editing?.note ?? '';
    _favorite = ref.read(libraryEntryProvider(widget.title.id))?.favorite ?? false;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    // An evening watch, unless that's still to come today.
    final evening = DateTime(picked.year, picked.month, picked.day, 20);
    setState(
      () => _date = evening.isAfter(now) ? DateTime(now.year, now.month, now.day, now.hour, now.minute) : evening,
    );
  }

  Future<void> _save() async {
    final actions = ref.read(libraryActionsProvider);
    final note = _note.text.trim();
    final watch = WatchEvent(watchedAt: _date, rating: _rating, note: note.isEmpty ? null : note);
    final index = widget.editIndex;
    final editing = index != null && _editing != null;
    Navigator.of(context).pop();
    // One save: a second one would start from the library before the first
    // landed (and, offline, Firestore's first write doesn't finish).
    await runLibraryAction(
      context,
      () => editing
          ? actions.editWatch(widget.title, index, watch, favorite: _favorite)
          : actions.logWatch(widget.title, watch, favorite: _favorite),
      done: editing ? 'Watch updated' : 'Logged ${widget.title.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final watchedBefore = ref.watch(libraryEntryProvider(widget.title.id))?.watches.length ?? 0;
    final localizations = MaterialLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.editIndex == null ? 'Log a watch' : 'Edit watch', style: textTheme.titleLarge),
          Text(
            widget.editIndex == null && watchedBefore > 0
                ? '${widget.title.name} · rewatch #${watchedBefore + 1}'
                : widget.title.name,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Watched on'),
            trailing: Text(localizations.formatMediumDate(_date)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          SegmentedButton<Rating?>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: Rating.disliked, icon: Icon(Icons.thumb_down_outlined), label: Text('Nah')),
              ButtonSegment(value: Rating.liked, icon: Icon(Icons.thumb_up_outlined), label: Text('Liked')),
              ButtonSegment(value: Rating.loved, icon: Icon(Icons.favorite_border), label: Text('Loved')),
            ],
            selected: {_rating},
            onSelectionChanged: (selection) => setState(() => _rating = selection.isEmpty ? null : selection.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(_favorite ? Icons.star : Icons.star_border),
            title: const Text('Favorite'),
            value: _favorite,
            onChanged: (value) => setState(() => _favorite = value),
          ),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
