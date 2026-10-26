import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/async_states.dart';
import 'package:reel/presentation/widgets/service_logo.dart';

/// A searchable grid of the services in [country], most popular first.
class ServicePicker extends ConsumerStatefulWidget {
  final String country;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const ServicePicker({super.key, required this.country, required this.selected, required this.onChanged});

  @override
  ConsumerState<ServicePicker> createState() => _ServicePickerState();
}

class _ServicePickerState extends ConsumerState<ServicePicker> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(countryServicesProvider(widget.country));
    return AsyncBody<List<StreamingService>>(
      value: services,
      onRetry: () => ref.invalidate(countryServicesProvider(widget.country)),
      data: (all) {
        final needle = _filter.toLowerCase();
        final shown = [
          for (final s in all)
            if (s.name.toLowerCase().contains(needle)) s,
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Find a service',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (text) => setState(() => _filter = text.trim()),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 110,
                  mainAxisExtent: 112,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: shown.length,
                itemBuilder: (context, index) {
                  final service = shown[index];
                  final on = widget.selected.contains(service.providerId);
                  final scheme = Theme.of(context).colorScheme;
                  return Semantics(
                    selected: on,
                    button: true,
                    label: service.name,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final next = {...widget.selected};
                        on ? next.remove(service.providerId) : next.add(service.providerId);
                        widget.onChanged(next);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: on ? scheme.primaryContainer : scheme.surfaceContainer,
                          border: Border.all(color: on ? scheme.primary : Colors.transparent, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ServiceLogo(service: service, size: 52),
                                  if (on)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: Icon(Icons.check_circle, size: 20, color: scheme.primary),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                service.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A searchable list of countries with provider data.
class CountryPicker extends ConsumerStatefulWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const CountryPicker({super.key, required this.selected, required this.onChanged});

  @override
  ConsumerState<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends ConsumerState<CountryPicker> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final regions = ref.watch(regionsProvider);
    return AsyncBody<Map<String, String>>(
      value: regions,
      onRetry: () => ref.invalidate(regionsProvider),
      data: (regions) {
        final needle = _filter.toLowerCase();
        final shown = regions.entries
            .where((e) => e.value.toLowerCase().contains(needle) || e.key.toLowerCase() == needle)
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Find a country',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (text) => setState(() => _filter = text.trim()),
              ),
            ),
            Expanded(
              child: RadioGroup<String>(
                groupValue: widget.selected,
                onChanged: (code) {
                  if (code != null) widget.onChanged(code);
                },
                child: ListView(
                  children: [
                    for (final entry in shown)
                      RadioListTile<String>(value: entry.key, title: Text(entry.value), secondary: Text(entry.key)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
