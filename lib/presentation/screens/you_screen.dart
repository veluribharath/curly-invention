import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/account_section.dart';
import 'package:reel/presentation/widgets/service_logo.dart';
import 'package:reel/presentation/widgets/stats_section.dart';
import 'package:reel/presentation/widgets/design_kit.dart';
import 'package:reel/presentation/widgets/design_picker.dart';

/// Stats, the preferences from first-run setup (country, services, taste),
/// account and app info.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final services = settings == null ? null : ref.watch(countryServicesProvider(settings.country)).value;
    final regions = ref.watch(regionsProvider).value;
    final rated = ref.watch(
      libraryProvider.select((library) => library.value?.values.where((e) => e.latestRating != null).length ?? 0),
    );
    final mine = [
      for (final s in services ?? const [])
        if (settings!.serviceIds.contains(s.providerId)) s,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        children: [
          const DesignPicker(),
          const StatsSection(),
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: const SectionHeader('Preferences')),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Country'),
            subtitle: Text(settings == null ? '' : regions?[settings.country] ?? settings.country),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/you/country'),
          ),
          ListTile(
            leading: const Icon(Icons.live_tv),
            title: const Text('My services'),
            subtitle: mine.isEmpty
                ? const Text('None picked yet. Discover shows what you can play on them.')
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final s in mine) ServiceLogo(service: s, size: 28)],
                    ),
                  ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/you/services'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.money_off),
            title: const Text('Also show free with ads'),
            subtitle: const Text('Tubi, Pluto TV and the like'),
            value: settings?.includeFreeWithAds ?? false,
            onChanged: settings == null ? null : ref.read(settingsActionsProvider).setIncludeFree,
          ),
          ListTile(
            leading: const Icon(Icons.thumbs_up_down_outlined),
            title: const Text('Your taste'),
            subtitle: Text(
              rated == 0
                  ? 'Not rated yet. Rate titles you know to tune Discover.'
                  : '$rated ${rated == 1 ? 'title' : 'titles'} rated. Rate more any time.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/you/rate'),
          ),
          const AccountSection(),
          if (!kReleaseMode)
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Reels spike'),
              subtitle: const Text('Trailer embed test from M0'),
              onTap: () => context.push('/spike'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
