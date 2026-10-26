import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/service_picker.dart';

/// Edit your subscriptions, or with [country] true, your country.
class ServicesScreen extends ConsumerWidget {
  final bool country;

  const ServicesScreen({super.key, this.country = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final actions = ref.read(settingsActionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(country ? 'Country' : 'My services')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : country
          ? CountryPicker(
              selected: settings.country,
              onChanged: (code) async {
                if (code == settings.country) return;
                // Keep the services the new country also has.
                final there = await ref
                    .read(countryServicesProvider(code).future)
                    .catchError((Object _) => const <StreamingService>[]);
                final ids = {for (final s in there) s.providerId};
                await actions.setCountry(code, keepServices: settings.serviceIds.where(ids.contains).toSet());
              },
            )
          : Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: ServicePicker(
                    country: settings.country,
                    selected: settings.serviceIds,
                    onChanged: actions.setServices,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Also show free with ads'),
                  subtitle: const Text('Tubi, Pluto TV and the like'),
                  value: settings.includeFreeWithAds,
                  onChanged: actions.setIncludeFree,
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}
