import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/core/theme/reel_style.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('design names parse loosely and unknown ones are null', () {
    expect(AppDesign.tryParse('marquee'), AppDesign.marquee);
    expect(AppDesign.tryParse(' Pop '), AppDesign.pop);
    expect(AppDesign.tryParse(''), isNull);
    expect(AppDesign.tryParse('neon'), isNull);
    expect(AppDesign.tryParse(null), isNull);
  });

  for (final design in AppDesign.values) {
    for (final brightness in Brightness.values) {
      group('${design.name} ${brightness.name}', () {
        final theme = AppTheme.build(design, brightness);
        final scheme = theme.colorScheme;

        test('carries its own tokens', () {
          expect(theme.brightness, brightness);
          expect(theme.extension<ReelStyle>()?.design, design);
        });

        // WCAG AA: 4.5:1 for body text, 3:1 for large text and icons.
        test('text is readable', () {
          expect(contrast(scheme.onSurface, scheme.surface), greaterThanOrEqualTo(4.5));
          expect(contrast(scheme.onSurfaceVariant, scheme.surface), greaterThanOrEqualTo(4.5));
          expect(contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
          expect(contrast(scheme.onPrimaryContainer, scheme.primaryContainer), greaterThanOrEqualTo(4.5));
          expect(contrast(scheme.primary, scheme.surface), greaterThanOrEqualTo(3));
          final reel = theme.extension<ReelStyle>()!;
          expect(contrast(reel.onHighlight, reel.highlight), greaterThanOrEqualTo(4.5));
        });
      });
    }
  }

  test('switching designs blends tokens and flips choices halfway', () {
    final from = AppTheme.dark(AppDesign.marquee).extension<ReelStyle>()!;
    final to = AppTheme.dark(AppDesign.pop).extension<ReelStyle>()!;
    final early = from.lerp(to, 0.25);
    final late = from.lerp(to, 0.75);
    expect(early.design, AppDesign.marquee);
    expect(late.design, AppDesign.pop);
    expect(early.cardRadius, inExclusiveRange(from.cardRadius, to.cardRadius));
  });
}
