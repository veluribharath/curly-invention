import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/providers/recent_searches.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/library_actions.dart';
import 'package:reel/presentation/widgets/title_tile.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// Search movies and series together. Recent searches and trending titles
/// show while the field is empty.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _query = text.trim()));
  }

  void _submit(String text) {
    _debounce?.cancel();
    setState(() => _query = text.trim());
    ref.read(recentSearchesProvider.notifier).add(text);
  }

  void _searchFor(String text) {
    _controller.text = text;
    _submit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _controller,
              hintText: 'Movies, series, people',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _submit('');
                    },
                  ),
              ],
              onChanged: _onChanged,
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: _query.isEmpty ? _EmptySearch(onPick: _searchFor) : _Results(query: _query, onOpen: () => _submit(_query)),
    );
  }
}

class _Results extends ConsumerWidget {
  final String query;
  final VoidCallback onOpen;

  const _Results({required this.query, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));
    return AsyncBody<List<MediaTitle>>(
      value: results,
      onRetry: () => ref.invalidate(searchResultsProvider(query)),
      data: (titles) {
        if (titles.isEmpty) return EmptyMessage(icon: Icons.search_off, message: 'Nothing found for "$query".');
        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: titles.length,
          itemBuilder: (context, index) => TitleTile(
            title: titles[index],
            onTap: () {
              // Remember a search once it led somewhere.
              onOpen();
              openTitle(context, titles[index]);
            },
          ),
        );
      },
    );
  }
}

class _EmptySearch extends ConsumerWidget {
  final ValueChanged<String> onPick;

  const _EmptySearch({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    final trending = ref.watch(trendingProvider);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(child: const SectionHeader('Recent')),
                TextButton(
                  onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [for (final q in recent) ActionChip(label: Text(q), onPressed: () => onPick(q))],
            ),
          ),
        ],
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: const SectionHeader('Trending this week')),
        ...switch (trending) {
          AsyncData(:final value) => [for (final title in value) TitleTile(title: title)],
          AsyncError() => [
            ErrorMessage(message: "Couldn't load trending titles.", onRetry: () => ref.invalidate(trendingProvider)),
          ],
          _ => [
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        },
      ],
    );
  }
}
