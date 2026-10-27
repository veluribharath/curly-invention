import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:reel/core/theme/app_design.dart';

/// How the bottom bar sits on screen.
enum NavStyle {
  /// Material's bar, flat on the bottom edge.
  docked,

  /// Full width and see-through, with content scrolling under a blur.
  glass,

  /// A pill floating above the bottom edge.
  floating,
}

/// The design tokens Material's theme has no slot for: corners, outlines,
/// shadows, motion and a few layout choices. Read with `context.reel`.
@immutable
class ReelStyle extends ThemeExtension<ReelStyle> {
  final AppDesign design;

  /// Corners of posters, cards and the Discover clip.
  final double posterRadius;
  final double cardRadius;
  final double clipRadius;

  /// Outline around cards and posters; 0 for none.
  final double borderWidth;
  final Color borderColor;

  /// A solid, unblurred shadow offset (Pop); zero for none.
  final Offset hardShadow;
  final Color hardShadowColor;

  /// Blurred depth under posters and cards (Aura); empty for none.
  final List<BoxShadow> softShadow;

  /// A second accent for stickers, badges and highlights.
  final Color highlight;
  final Color onHighlight;

  /// Fills hero moments: the Discover call to action, stat tiles.
  final Gradient accentGradient;

  /// Small labels ("eyebrows") set in tracked capitals, like film credits.
  final bool capsLabels;

  final NavStyle nav;

  /// Standard length and curve of the design's own animations.
  final Duration motion;
  final Curve curve;

  /// How far a pressed button shrinks; 1 for no change.
  final double pressScale;

  /// Font of display text, or null for the theme's.
  final String? displayFamily;

  const ReelStyle({
    required this.design,
    required this.posterRadius,
    required this.cardRadius,
    required this.clipRadius,
    required this.borderWidth,
    required this.borderColor,
    required this.hardShadow,
    required this.hardShadowColor,
    required this.softShadow,
    required this.highlight,
    required this.onHighlight,
    required this.accentGradient,
    required this.capsLabels,
    required this.nav,
    required this.motion,
    required this.curve,
    required this.pressScale,
    this.displayFamily,
  });

  /// The look before there were designs, for a theme without the extension.
  factory ReelStyle.fallback(ColorScheme scheme) => ReelStyle(
    design: AppDesign.classic,
    posterRadius: 8,
    cardRadius: 12,
    clipRadius: 14,
    borderWidth: 0,
    borderColor: scheme.outlineVariant,
    hardShadow: Offset.zero,
    hardShadowColor: Colors.transparent,
    softShadow: const [],
    highlight: scheme.tertiary,
    onHighlight: scheme.onTertiary,
    accentGradient: LinearGradient(colors: [scheme.primary, scheme.primary]),
    capsLabels: false,
    nav: NavStyle.docked,
    motion: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
    pressScale: 1,
  );

  /// Outline, shadows and corners for a card-like surface in this design.
  BoxDecoration surface({Color? color, Gradient? gradient, double? radius, bool shadow = true}) => BoxDecoration(
    color: gradient == null ? color : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius ?? cardRadius),
    border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
    boxShadow: [
      if (shadow && hardShadow != Offset.zero) BoxShadow(color: hardShadowColor, offset: hardShadow),
      if (shadow) ...softShadow,
    ],
  );

  @override
  ReelStyle copyWith({AppDesign? design, NavStyle? nav}) => ReelStyle(
    design: design ?? this.design,
    posterRadius: posterRadius,
    cardRadius: cardRadius,
    clipRadius: clipRadius,
    borderWidth: borderWidth,
    borderColor: borderColor,
    hardShadow: hardShadow,
    hardShadowColor: hardShadowColor,
    softShadow: softShadow,
    highlight: highlight,
    onHighlight: onHighlight,
    accentGradient: accentGradient,
    capsLabels: capsLabels,
    nav: nav ?? this.nav,
    motion: motion,
    curve: curve,
    pressScale: pressScale,
    displayFamily: displayFamily,
  );

  /// Numbers and colors blend while the app animates from one theme to the
  /// next; choices flip halfway.
  @override
  ReelStyle lerp(ReelStyle? other, double t) {
    if (other == null) return this;
    final near = t < 0.5 ? this : other;
    return ReelStyle(
      design: near.design,
      posterRadius: lerpDouble(posterRadius, other.posterRadius, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      clipRadius: lerpDouble(clipRadius, other.clipRadius, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      hardShadow: Offset.lerp(hardShadow, other.hardShadow, t)!,
      hardShadowColor: Color.lerp(hardShadowColor, other.hardShadowColor, t)!,
      softShadow: BoxShadow.lerpList(softShadow, other.softShadow, t) ?? const [],
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
      accentGradient: Gradient.lerp(accentGradient, other.accentGradient, t) ?? near.accentGradient,
      capsLabels: near.capsLabels,
      nav: near.nav,
      motion: near.motion,
      curve: near.curve,
      pressScale: lerpDouble(pressScale, other.pressScale, t)!,
      displayFamily: near.displayFamily,
    );
  }
}

extension ReelStyleContext on BuildContext {
  /// The current design's tokens.
  ReelStyle get reel {
    final theme = Theme.of(this);
    return theme.extension<ReelStyle>() ?? ReelStyle.fallback(theme.colorScheme);
  }
}
