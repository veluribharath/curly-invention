import 'package:flutter/material.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/designs/aura_theme.dart';
import 'package:reel/core/theme/designs/marquee_theme.dart';
import 'package:reel/core/theme/designs/pop_theme.dart';
import 'package:reel/core/theme/reel_style.dart';

/// The app's themes, one light and one dark per [AppDesign]. Classic is
/// Material 3 seeded with resonance's indigo, dark by default since Discover
/// is video-first.
class AppTheme {
  const AppTheme._();

  static const seed = Colors.indigo;

  static ThemeData build(AppDesign design, Brightness brightness) => switch (design) {
    AppDesign.classic => _classic(brightness),
    AppDesign.marquee => marqueeTheme(brightness),
    AppDesign.aura => auraTheme(brightness),
    AppDesign.pop => popTheme(brightness),
  };

  static ThemeData dark([AppDesign design = AppDesign.classic]) => build(design, Brightness.dark);

  static ThemeData light([AppDesign design = AppDesign.classic]) => build(design, Brightness.light);

  static ThemeData _classic(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.dark ? const Color(0xFF0E0F14) : null,
    );
    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, scrolledUnderElevation: 0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: ChipThemeData(side: BorderSide(color: scheme.outlineVariant)),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      extensions: [ReelStyle.fallback(scheme)],
    );
  }
}

/// A text theme with [display] for display, headline and large titles and
/// [body] for the rest, tuned per role by the design.
TextTheme designTextTheme({
  required Brightness brightness,
  required String display,
  required String body,
  required FontWeight displayWeight,
  required double displayTracking,
  FontWeight titleWeight = FontWeight.w600,
  FontWeight bodyWeight = FontWeight.w400,
  FontWeight labelWeight = FontWeight.w600,
  double labelTracking = 0.2,
  double bodyHeight = 1.4,
}) {
  final base = (brightness == Brightness.dark ? Typography.material2021().white : Typography.material2021().black)
      .apply(fontFamily: body);
  TextStyle? shout(TextStyle? s, {double tracking = 0}) =>
      s?.copyWith(fontFamily: display, fontWeight: displayWeight, letterSpacing: displayTracking + tracking);
  return base.copyWith(
    displayLarge: shout(base.displayLarge, tracking: -1),
    displayMedium: shout(base.displayMedium, tracking: -0.6),
    displaySmall: shout(base.displaySmall, tracking: -0.3),
    headlineLarge: shout(base.headlineLarge),
    headlineMedium: shout(base.headlineMedium),
    headlineSmall: shout(base.headlineSmall),
    titleLarge: shout(base.titleLarge, tracking: 0.2),
    titleMedium: base.titleMedium?.copyWith(fontWeight: titleWeight),
    titleSmall: base.titleSmall?.copyWith(fontWeight: titleWeight),
    bodyLarge: base.bodyLarge?.copyWith(fontWeight: bodyWeight, height: bodyHeight),
    bodyMedium: base.bodyMedium?.copyWith(fontWeight: bodyWeight, height: bodyHeight),
    bodySmall: base.bodySmall?.copyWith(fontWeight: bodyWeight, height: bodyHeight),
    labelLarge: base.labelLarge?.copyWith(fontWeight: labelWeight, letterSpacing: labelTracking),
    labelMedium: base.labelMedium?.copyWith(fontWeight: labelWeight, letterSpacing: labelTracking),
    labelSmall: base.labelSmall?.copyWith(fontWeight: labelWeight, letterSpacing: labelTracking),
  );
}

/// [text] with Material's sizes merged in, the way `Theme.of` hands it out.
/// Styles for component themes come from this, so they blend with the
/// defaults while the app animates from one design to another.
TextTheme localized(TextTheme text) => Typography.material2021().englishLike.merge(text);

/// Page transitions for every platform.
PageTransitionsTheme allPlatforms(PageTransitionsBuilder builder) =>
    PageTransitionsTheme(builders: {for (final platform in TargetPlatform.values) platform: builder});
