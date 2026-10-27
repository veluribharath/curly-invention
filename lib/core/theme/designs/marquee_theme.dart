import 'package:flutter/material.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/core/theme/reel_style.dart';

/// Marquee: a film-festival program. Ink black and warm paper, gold leaf
/// accents, Fraunces serif titles over Inter, hairline rules, square corners
/// and slow fades.
ThemeData marqueeTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFF3EDE2) : const Color(0xFF1B1712);
  final gold = dark ? const Color(0xFFE3B65B) : const Color(0xFF8A6212);
  final oxblood = dark ? const Color(0xFFE0705F) : const Color(0xFF9E2B1E);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFE3B65B),
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ).copyWith(
        primary: gold,
        onPrimary: dark ? const Color(0xFF1A1305) : const Color(0xFFFFFBF2),
        primaryContainer: dark ? const Color(0xFF3A2C10) : const Color(0xFFF1DFB4),
        onPrimaryContainer: dark ? const Color(0xFFF6DDA3) : const Color(0xFF2B1F05),
        secondary: oxblood,
        onSecondary: dark ? const Color(0xFF2A0B06) : Colors.white,
        secondaryContainer: dark ? const Color(0xFF2A211A) : const Color(0xFFEDE3D0),
        onSecondaryContainer: ink,
        tertiary: dark ? const Color(0xFF9DBFB4) : const Color(0xFF3E6A5E),
        surface: dark ? const Color(0xFF0B0A08) : const Color(0xFFF6F1E7),
        onSurface: ink,
        onSurfaceVariant: dark ? const Color(0xFFADA393) : const Color(0xFF5E554A),
        surfaceContainerLowest: dark ? const Color(0xFF080706) : const Color(0xFFFFFDF8),
        surfaceContainerLow: dark ? const Color(0xFF12100D) : const Color(0xFFF1EBDF),
        surfaceContainer: dark ? const Color(0xFF181511) : const Color(0xFFECE4D5),
        surfaceContainerHigh: dark ? const Color(0xFF201C17) : const Color(0xFFE5DCCB),
        surfaceContainerHighest: dark ? const Color(0xFF2A251E) : const Color(0xFFDDD2BE),
        outline: dark ? const Color(0xFF6B6255) : const Color(0xFF8C8273),
        outlineVariant: dark ? const Color(0xFF2E2922) : const Color(0xFFD5CAB6),
        inverseSurface: ink,
        onInverseSurface: dark ? const Color(0xFF0B0A08) : const Color(0xFFF6F1E7),
        inversePrimary: dark ? const Color(0xFF8A6212) : const Color(0xFFE3B65B),
      );
  final textTheme = designTextTheme(
    brightness: brightness,
    display: 'Fraunces',
    body: 'Inter',
    displayWeight: FontWeight.w600,
    displayTracking: -0.4,
    labelTracking: 1.1,
    bodyHeight: 1.5,
  ).apply(bodyColor: ink, displayColor: ink);
  final text = localized(textTheme);
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2)));
  final hairline = BorderSide(color: scheme.outlineVariant, width: 0.8);
  final buttonText = text.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1, fontSize: 13);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 16);

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'Inter',
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    dividerColor: scheme.outlineVariant,
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 0.8, space: 1),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: ink,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 24, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
      shape: Border(bottom: hairline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 66,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? gold : scheme.onSurfaceVariant),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 1.6,
          color: states.contains(WidgetState.selected) ? gold : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: square, textStyle: buttonText, padding: buttonPadding),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: square,
        textStyle: buttonText,
        padding: buttonPadding,
        side: BorderSide(color: gold, width: 0.8),
        foregroundColor: gold,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: square, textStyle: buttonText, foregroundColor: gold),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: square,
      backgroundColor: gold,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      highlightElevation: 0,
      extendedTextStyle: buttonText,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: square,
        side: hairline.copyWith(color: scheme.outline),
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        textStyle: text.labelMedium?.copyWith(letterSpacing: 1.2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: square,
      side: hairline.copyWith(color: scheme.outline),
      backgroundColor: Colors.transparent,
      selectedColor: scheme.primaryContainer,
      labelStyle: text.labelMedium?.copyWith(color: ink, letterSpacing: 1),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: hairline),
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant, titleTextStyle: text.bodyLarge),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
      shape: const WidgetStatePropertyAll(square),
      side: WidgetStatePropertyAll(hairline.copyWith(color: scheme.outline)),
      textStyle: WidgetStatePropertyAll(text.bodyLarge),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outline)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold, width: 1.4)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(scheme.outline),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.outline,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        side: hairline,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: hairline),
      titleTextStyle: text.headlineSmall,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: square,
      backgroundColor: scheme.inverseSurface,
      actionTextColor: dark ? const Color(0xFF8A6212) : const Color(0xFFE3B65B),
    ),
    pageTransitionsTheme: allPlatforms(const FadeForwardsPageTransitionsBuilder()),
    extensions: [
      ReelStyle(
        design: AppDesign.marquee,
        posterRadius: 2,
        cardRadius: 4,
        clipRadius: 2,
        borderWidth: 0.8,
        borderColor: dark ? const Color(0x33E3B65B) : const Color(0x338A6212),
        hardShadow: Offset.zero,
        hardShadowColor: Colors.transparent,
        softShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.6 : 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
        highlight: oxblood,
        onHighlight: dark ? const Color(0xFF1A0705) : Colors.white,
        accentGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFFF1D08A), Color(0xFFD5A443), Color(0xFFA77A22)]
              : const [Color(0xFFB08326), Color(0xFF8A6212), Color(0xFF6A4908)],
        ),
        capsLabels: true,
        nav: NavStyle.glass,
        motion: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        pressScale: 0.98,
        displayFamily: 'Fraunces',
      ),
    ],
  );
}
