import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/core/theme/reel_style.dart';

/// The bottom navigation around the four tabs. Each tab keeps its own stack.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const HomeShell({super.key, required this.shell});

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.play_circle_outline),
      selectedIcon: Icon(Icons.play_circle),
      label: 'Discover',
    ),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
    NavigationDestination(
      icon: Icon(Icons.video_library_outlined),
      selectedIcon: Icon(Icons.video_library),
      label: 'Library',
    ),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final reel = context.reel;
    final scheme = Theme.of(context).colorScheme;
    final bar = NavigationBar(
      selectedIndex: shell.currentIndex,
      destinations: destinations,
      animationDuration: reel.motion,
      // Tapping the current tab again goes back to its first screen.
      onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
    );
    // Under a see-through bar, the tabs' buttons (a floating action button)
    // sit above it rather than behind.
    final body = Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        final bottom = max(media.viewPadding.bottom, media.padding.bottom);
        return MediaQuery(
          data: media.copyWith(viewPadding: media.viewPadding.copyWith(bottom: bottom)),
          child: shell,
        );
      },
    );
    return switch (reel.nav) {
      NavStyle.docked => Scaffold(body: shell, bottomNavigationBar: bar),
      // Content scrolls on under the bar, frosted.
      NavStyle.glass => Scaffold(
        extendBody: true,
        body: body,
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.72),
                border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.6)),
              ),
              child: bar,
            ),
          ),
        ),
      ),
      NavStyle.floating => Scaffold(
        extendBody: true,
        body: body,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: DecoratedBox(
              decoration: reel.surface(color: scheme.surfaceContainer, radius: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: MediaQuery.removePadding(context: context, removeBottom: true, child: bar),
              ),
            ),
          ),
        ),
      ),
    };
  }
}
