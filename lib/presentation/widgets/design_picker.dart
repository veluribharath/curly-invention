import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/core/theme/reel_style.dart';
import 'package:reel/presentation/providers/account_providers.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// Flips the whole app between design directions, each previewed in its own
/// theme. Nothing but the look changes.
class DesignPicker extends ConsumerWidget {
  const DesignPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appDesignProvider);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 4), child: SectionHeader('Design preview')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            '${current.label}: ${current.description}',
            style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            itemCount: AppDesign.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final design = AppDesign.values[index];
              return _DesignCard(
                design: design,
                selected: design == current,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(appDesignProvider.notifier).set(design);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A swatch of one design, drawn in that design's own theme.
class _DesignCard extends StatelessWidget {
  final AppDesign design;
  final bool selected;
  final VoidCallback onTap;

  const _DesignCard({required this.design, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final outer = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${design.label} design',
      child: Theme(
        data: AppTheme.build(design, Theme.of(context).brightness),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final reel = context.reel;
            final radius = reel.cardRadius.clamp(4.0, 22.0);
            return GestureDetector(
              onTap: onTap,
              child: PressScale(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: reel
                      .surface(color: scheme.surface, radius: radius)
                      .copyWith(
                        border: Border.all(
                          color: selected ? outer.primary : scheme.outlineVariant,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Aa', style: theme.textTheme.headlineMedium?.copyWith(height: 1)),
                          const Spacer(),
                          if (selected) Icon(Icons.check_circle, size: 20, color: outer.primary),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final color in [scheme.primary, scheme.secondary, reel.highlight])
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(design.label, style: theme.textTheme.titleMedium),
                      Text(
                        design.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
