import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/title_tile.dart';

/// Titles an actor, director or creator worked on, most popular first.
class PersonScreen extends ConsumerWidget {
  final String personId;
  final String name;

  const PersonScreen({super.key, required this.personId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titles = ref.watch(personTitlesProvider(personId));
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: AsyncBody<List<MediaTitle>>(
        value: titles,
        onRetry: () => ref.invalidate(personTitlesProvider(personId)),
        data: (titles) => titles.isEmpty
            ? const EmptyMessage(icon: Icons.movie_filter_outlined, message: 'No titles found.')
            : ListView.builder(
                itemCount: titles.length,
                itemBuilder: (context, i) => TitleTile(title: titles[i]),
              ),
      ),
    );
  }
}
