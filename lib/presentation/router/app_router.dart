import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/presentation/screens/home_shell.dart';
import 'package:reel/presentation/screens/library_screen.dart';
import 'package:reel/presentation/screens/person_screen.dart';
import 'package:reel/presentation/screens/placeholder_screen.dart';
import 'package:reel/presentation/screens/reels_spike_screen.dart';
import 'package:reel/presentation/screens/search_screen.dart';
import 'package:reel/presentation/screens/title_details_screen.dart';

GoRouter buildRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/discover',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Discover', icon: Icons.play_circle_outline),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/search', builder: (context, state) => const SearchScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/library', builder: (context, state) => const LibraryScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) => PlaceholderScreen(
                  title: 'You',
                  icon: Icons.person_outline,
                  action: OutlinedButton(onPressed: () => context.push('/spike'), child: const Text('Reels spike')),
                ),
              ),
            ],
          ),
        ],
      ),
      // Details sit above the tabs, so the bottom bar stays put underneath.
      GoRoute(
        path: '/title/:type/:id',
        parentNavigatorKey: rootKey,
        redirect: (context, state) => _titleId(state) == null ? '/discover' : null,
        builder: (context, state) {
          final extra = state.extra;
          return TitleDetailsScreen(id: _titleId(state)!, preview: extra is MediaTitle ? extra : null);
        },
      ),
      GoRoute(
        path: '/person/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            PersonScreen(personId: state.pathParameters['id']!, name: state.uri.queryParameters['name'] ?? ''),
      ),
      GoRoute(path: '/spike', parentNavigatorKey: rootKey, builder: (context, state) => const ReelsSpikeScreen()),
    ],
  );
}

TitleId? _titleId(GoRouterState state) =>
    TitleId.tryParse('${state.pathParameters['type']}:${state.pathParameters['id']}');
