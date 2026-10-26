import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/log_watch_sheet.dart';

/// Opens a title's details. The title passed along shows at once while the
/// full details load.
void openTitle(BuildContext context, MediaTitle title) {
  context.push('/title/${title.type.name}/${title.id.tmdbId}', extra: title);
}

/// Runs a library change, with a haptic tap, and shows a message if it fails.
Future<void> runLibraryAction(BuildContext context, Future<void> Function() action, {String? done}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  unawaited(HapticFeedback.lightImpact());
  try {
    await action();
    if (done != null) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done), duration: const Duration(seconds: 2)));
    }
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
  }
}

/// Watchlist and Watched buttons for a row.
class QuickLibraryButtons extends ConsumerWidget {
  final MediaTitle title;

  const QuickLibraryButtons({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(libraryEntryProvider(title.id));
    final actions = ref.read(libraryActionsProvider);
    final onWatchlist = entry?.onWatchlist ?? false;
    final watched = entry?.watched ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: onWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
          isSelected: onWatchlist,
          icon: const Icon(Icons.bookmark_add_outlined),
          selectedIcon: const Icon(Icons.bookmark_added),
          onPressed: () => runLibraryAction(
            context,
            () => actions.setWatchlist(title, !onWatchlist),
            done: onWatchlist ? 'Removed from watchlist' : 'Added to watchlist',
          ),
        ),
        IconButton(
          tooltip: watched ? 'Log another watch' : 'Mark watched',
          isSelected: watched,
          icon: const Icon(Icons.check_circle_outline),
          selectedIcon: const Icon(Icons.check_circle),
          onPressed: () => showLogWatchSheet(context, title),
        ),
      ],
    );
  }
}
