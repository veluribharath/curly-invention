import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/service_logo.dart';
import 'package:reel/presentation/widgets/stats_section.dart';

/// Stats, services and country, account and app info.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final services = settings == null ? null : ref.watch(countryServicesProvider(settings.country)).value;
    final regions = ref.watch(regionsProvider).value;
    final mine = [
      for (final s in services ?? const [])
        if (settings!.serviceIds.contains(s.providerId)) s,
    ];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        children: [
          const StatsSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Streaming', style: textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.live_tv),
            title: const Text('My services'),
            subtitle: mine.isEmpty
                ? const Text('None picked yet')
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
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Country'),
            subtitle: Text(settings == null ? '' : regions?[settings.country] ?? settings.country),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/you/country'),
          ),
          ...ref.watch(youSettingsTilesProvider),
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

/// Extra tiles under Streaming: account, data, about.
final youSettingsTilesProvider = Provider<List<Widget>>((ref) => const []);
