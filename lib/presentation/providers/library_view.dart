import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/usecases/query_library.dart';

/// The Library tab's segment, filters and sort, kept while the app runs.
class LibraryView extends Notifier<LibraryQuery> {
  @override
  LibraryQuery build() => const LibraryQuery();

  void update(LibraryQuery Function(LibraryQuery query) change) => state = change(state);

  void setSegment(LibrarySegment segment) {
    // Each segment has its natural order; keep a sort the user picked.
    final defaultSort = state.sort == LibrarySort.dateAdded || state.sort == LibrarySort.dateWatched;
    state = state.copyWith(
      segment: segment,
      sort: defaultSort
          ? (segment == LibrarySegment.watchlist ? LibrarySort.dateAdded : LibrarySort.dateWatched)
          : null,
    );
  }
}

final libraryViewProvider = NotifierProvider<LibraryView, LibraryQuery>(LibraryView.new);

/// Grid of posters (true) or list rows (false).
class LibraryLayout extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final libraryGridProvider = NotifierProvider<LibraryLayout, bool>(LibraryLayout.new);
