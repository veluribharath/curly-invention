import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/screens/about_screen.dart';
import 'package:reel/presentation/screens/diary_screen.dart';
import 'package:reel/presentation/screens/discover_screen.dart';
import 'package:reel/presentation/screens/home_shell.dart';
import 'package:reel/presentation/screens/library_screen.dart';
import 'package:reel/presentation/screens/onboarding_screen.dart';
import 'package:reel/presentation/screens/person_screen.dart';
import 'package:reel/presentation/screens/reels_spike_screen.dart';
import 'package:reel/presentation/screens/search_screen.dart';
import 'package:reel/presentation/screens/services_screen.dart';
import 'package:reel/presentation/screens/title_details_screen.dart';
import 'package:reel/presentation/screens/you_screen.dart';
import 'package:reel/presentation/widgets/taste_seed.dart';

/// The app's router. First run goes to onboarding until it's finished.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);
  final router = buildRouter(refresh: refresh, onboarded: () => ref.read(settingsProvider).value?.onboarded);
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// [onboarded] is null while settings load.
GoRouter buildRouter({required Listenable refresh, required bool? Function() onboarded}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/discover',
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = onboarded();
      final path = state.matchedLocation;
      if (done == null) {
        return path == '/loading' ? null : '/loading?from=${Uri.encodeQueryComponent(state.uri.toString())}';
      }
      if (!done) return path == '/onboarding' ? null : '/onboarding';
      if (path == '/onboarding') return '/discover';
      if (path == '/loading') return state.uri.queryParameters['from'] ?? '/discover';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/discover', builder: (context, state) => const DiscoverScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/search', builder: (context, state) => const SearchScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(path: 'diary', builder: (context, state) => const DiaryScreen()),
                  GoRoute(path: 'rate', builder: (context, state) => const _RateTitlesScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) => const YouScreen(),
                routes: [
                  GoRoute(path: 'services', builder: (context, state) => const ServicesScreen()),
                  GoRoute(path: 'country', builder: (context, state) => const ServicesScreen(country: true)),
                  GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
                  GoRoute(path: 'rate', builder: (context, state) => const _RateTitlesScreen()),
                ],
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

/// The onboarding swipe deck, to keep adding what you've seen or want to.
class _RateTitlesScreen extends StatelessWidget {
  const _RateTitlesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate titles')),
      body: TasteSeedDeck(onDone: (_) => context.pop()),
    );
  }
}

TitleId? _titleId(GoRouterState state) =>
    TitleId.tryParse('${state.pathParameters['type']}:${state.pathParameters['id']}');
