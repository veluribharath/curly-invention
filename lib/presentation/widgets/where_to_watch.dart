import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reel/data/services/service_links.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/service_logo.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// Opens [offer] in its service: the deep link when there is one, the
/// service's search for the title otherwise, and the JustWatch page last.
Future<void> openOffer(BuildContext context, MediaTitle title, Offer offer, {Uri? fallback}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final target = offer.deepLink ?? serviceSearchUrl(offer.service, title.name) ?? fallback;
  if (target == null) {
    messenger?.showSnackBar(SnackBar(content: Text('Open ${offer.service.name} and search for ${title.name}.')));
    return;
  }
  final opened = await launchUrl(target, mode: LaunchMode.externalApplication).catchError((Object _) => false);
  if (!opened) messenger?.showSnackBar(SnackBar(content: Text("Couldn't open ${offer.service.name}.")));
}

/// Where to watch [title] in your country, grouped into Stream / Free /
/// Rent / Buy, your services first.
class WhereToWatch extends ConsumerWidget {
  final MediaTitle title;

  const WhereToWatch({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(availabilityProvider(title.id));
    final settings = ref.watch(settingsProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final attribution = ref.watch(availabilityRepositoryProvider).attribution;

    Widget body;
    switch (availability) {
      case AsyncData(:final value) when value.isEmpty:
        body = Text('Not streaming, renting or selling anywhere in ${value.country} right now.');
      case AsyncData(:final value):
        final mine = settings?.serviceIds ?? const <int>{};
        final groups = <String, List<Offer>>{};
        for (final type in OfferType.values) {
          final offers = value.ofType(type)
            ..sort((a, b) {
              final aMine = mine.contains(a.service.providerId) ? 0 : 1;
              final bMine = mine.contains(b.service.providerId) ? 0 : 1;
              return aMine.compareTo(bMine);
            });
          // Free and free-with-ads read as one group.
          final label = type == OfferType.ads ? OfferType.free.label : type.label;
          if (offers.isNotEmpty) groups.putIfAbsent(label, () => []).addAll(offers);
        }
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final group in groups.entries) ...[
              Text(group.key, style: textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final offer in group.value)
                    _OfferChip(
                      offer: offer,
                      mine: mine.contains(offer.service.providerId),
                      onTap: () => openOffer(context, title, offer, fallback: value.link),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      case AsyncError():
        body = Row(
          children: [
            const Expanded(child: Text("Couldn't load where to watch.")),
            TextButton(onPressed: () => ref.invalidate(availabilityProvider(title.id)), child: const Text('Retry')),
          ],
        );
      default:
        body = const LinearProgressIndicator();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Where to watch'),
          const SizedBox(height: 8),
          body,
          Text(attribution, style: textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  final Offer offer;
  final bool mine;
  final VoidCallback onTap;

  const _OfferChip({required this.offer, required this.mine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: ServiceLogo(service: offer.service, size: 22),
      label: Text(offer.type == OfferType.ads ? '${offer.service.name} · ads' : offer.service.name),
      backgroundColor: mine ? scheme.primaryContainer : null,
      side: mine ? BorderSide(color: scheme.primary) : null,
      tooltip: mine ? 'On your services' : null,
      onPressed: onTap,
    );
  }
}
