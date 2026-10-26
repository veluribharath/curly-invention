import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/presentation/screens/home_shell.dart';
import 'package:reel/presentation/screens/placeholder_screen.dart';
import 'package:reel/presentation/screens/reels_spike_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
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
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const PlaceholderScreen(title: 'Search', icon: Icons.search),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Library', icon: Icons.video_library_outlined),
              ),
            ],
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
      GoRoute(path: '/spike', builder: (context, state) => const ReelsSpikeScreen()),
    ],
  );
}
