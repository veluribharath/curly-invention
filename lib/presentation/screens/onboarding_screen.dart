import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/service_picker.dart';

/// First run: what the app does, your country, your services. Each step
/// saves as you go, so leaving halfway keeps what you picked.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Extra steps after the services, e.g. seeding your taste. Each returns a
/// page given a callback that moves on.
final onboardingExtraStepsProvider = Provider<List<Widget Function(VoidCallback next)>>((ref) => const []);

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    final extra = ref.read(onboardingExtraStepsProvider);
    if (_step >= 2 + extra.length) {
      ref.read(settingsActionsProvider).finishOnboarding();
      return;
    }
    setState(() => _step++);
    _pages.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pages.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final extra = ref.watch(onboardingExtraStepsProvider);
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final actions = ref.read(settingsActionsProvider);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: _step == 0
            ? null
            : AppBar(
                leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: _back),
                title: Text('Step $_step of ${2 + extra.length}'),
              ),
        body: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _Welcome(onStart: _next),
            _Step(
              title: 'Where do you watch?',
              subtitle: 'What streams where depends on the country.',
              onNext: _next,
              child: CountryPicker(
                selected: settings.country,
                // A new country has different services; start that list over.
                onChanged: (code) => actions.setCountry(code, keepServices: code == settings.country ? null : {}),
              ),
            ),
            _Step(
              title: 'Your services',
              subtitle: 'Pick what you pay for. Discover shows what you can play on them.',
              nextLabel: settings.serviceIds.isEmpty ? 'Skip for now' : 'Continue',
              onNext: _next,
              footer: SwitchListTile(
                title: const Text('Also show free with ads'),
                subtitle: const Text('Tubi, Pluto TV and the like'),
                value: settings.includeFreeWithAds,
                onChanged: actions.setIncludeFree,
              ),
              child: ServicePicker(
                country: settings.country,
                selected: settings.serviceIds,
                onChanged: actions.setServices,
              ),
            ),
            for (final step in extra) step(_next),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final VoidCallback onStart;

  const _Welcome({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Icon(Icons.movie_filter, size: 64, color: scheme.primary),
            const SizedBox(height: 24),
            Text('Reel', style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "Know what you've seen, and find something good you can watch tonight without opening five apps.",
              style: textTheme.titleMedium,
            ),
            const Spacer(flex: 2),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onStart, child: const Text('Get started')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback onNext;
  final String nextLabel;

  const _Step({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.footer,
    this.nextLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(child: child),
          ?footer,
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onNext, child: Text(nextLabel)),
            ),
          ),
        ],
      ),
    );
  }
}
