import 'package:flutter/material.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/core/theme/reel_style.dart';

/// Pop: graphic and playful, neo-brutalist. Acid lime and hot pink on deep
/// violet (cream by day), Bricolage Grotesque headlines over Space Grotesk,
/// thick outlines, hard offset shadows, pills, and bouncy motion.
ThemeData popTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFFFF6E0) : const Color(0xFF17112A);
  const lime = Color(0xFFC6FF3D);
  const pink = Color(0xFFFF4FA3);
  const violet = Color(0xFF6B3BFF);
  final primary = dark ? lime : violet;
  final line = dark ? const Color(0xFFFFF6E0) : const Color(0xFF17112A);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: violet,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ).copyWith(
        primary: primary,
        onPrimary: dark ? const Color(0xFF17112A) : Colors.white,
        primaryContainer: dark ? const Color(0xFF3B2F6E) : const Color(0xFFE4DAFF),
        onPrimaryContainer: dark ? lime : const Color(0xFF22106B),
        secondary: pink,
        onSecondary: const Color(0xFF17112A),
        secondaryContainer: dark ? const Color(0xFF4A1D3A) : const Color(0xFFFFD6EA),
        onSecondaryContainer: dark ? const Color(0xFFFFC2DF) : const Color(0xFF5A0E35),
        tertiary: dark ? const Color(0xFF8C7BFF) : const Color(0xFF00A88F),
        onTertiary: dark ? const Color(0xFF17112A) : Colors.white,
        surface: dark ? const Color(0xFF130E22) : const Color(0xFFFFF4DE),
        onSurface: ink,
        onSurfaceVariant: dark ? const Color(0xFFC9BFE6) : const Color(0xFF51476B),
        surfaceContainerLowest: dark ? const Color(0xFF0D0919) : Colors.white,
        surfaceContainerLow: dark ? const Color(0xFF1B1530) : const Color(0xFFFFFAEE),
        surfaceContainer: dark ? const Color(0xFF221A3B) : Colors.white,
        surfaceContainerHigh: dark ? const Color(0xFF2C2348) : const Color(0xFFFFE9C2),
        surfaceContainerHighest: dark ? const Color(0xFF372C59) : const Color(0xFFFFDFA6),
        outline: line,
        outlineVariant: dark ? const Color(0xFF4A3F6E) : const Color(0xFFE5D3AE),
        inverseSurface: ink,
        onInverseSurface: dark ? const Color(0xFF130E22) : const Color(0xFFFFF4DE),
      );
  final textTheme = designTextTheme(
    brightness: brightness,
    display: 'BricolageGrotesque',
    body: 'SpaceGrotesk',
    displayWeight: FontWeight.w800,
    displayTracking: -0.6,
    titleWeight: FontWeight.w700,
    bodyWeight: FontWeight.w500,
    labelWeight: FontWeight.w700,
    labelTracking: 0.1,
  ).apply(bodyColor: ink, displayColor: ink);
  final text = localized(textTheme);
  final thick = BorderSide(color: line, width: 2);
  final pill = StadiumBorder(side: thick);
  final buttonText = text.labelLarge?.copyWith(fontSize: 15);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 15);

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'SpaceGrotesk',
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 2, space: 2),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: ink,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 20,
      titleTextStyle: text.headlineMedium?.copyWith(fontSize: 34, height: 1),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: primary,
      indicatorShape: StadiumBorder(side: BorderSide(color: line, width: 2)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? scheme.onPrimary : ink, size: 26),
      ),
      labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: pill, textStyle: buttonText, padding: buttonPadding),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        side: thick,
        textStyle: buttonText,
        padding: buttonPadding,
        foregroundColor: ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: const StadiumBorder(), textStyle: buttonText, foregroundColor: ink),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: pill,
      backgroundColor: pink,
      foregroundColor: const Color(0xFF17112A),
      elevation: 0,
      highlightElevation: 0,
      extendedTextStyle: buttonText,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const StadiumBorder(),
        side: thick,
        backgroundColor: scheme.surfaceContainer,
        selectedBackgroundColor: primary,
        selectedForegroundColor: scheme.onPrimary,
        textStyle: text.labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: pill,
      side: thick,
      backgroundColor: scheme.surfaceContainer,
      selectedColor: pink,
      labelStyle: text.labelLarge?.copyWith(fontSize: 13),
      secondaryLabelStyle: text.labelLarge?.copyWith(fontSize: 13, color: const Color(0xFF17112A)),
      checkmarkColor: const Color(0xFF17112A),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: thick),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: ink,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
      shape: WidgetStatePropertyAll(pill),
      textStyle: WidgetStatePropertyAll(text.bodyLarge),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(line),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : line,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : scheme.surfaceContainer,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: line,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: thick,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: thick),
      titleTextStyle: text.headlineSmall,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: thick),
      backgroundColor: pink,
      contentTextStyle: text.bodyMedium?.copyWith(color: const Color(0xFF17112A), fontWeight: FontWeight.w700),
      actionTextColor: const Color(0xFF17112A),
    ),
    pageTransitionsTheme: allPlatforms(const ZoomPageTransitionsBuilder()),
    extensions: [
      ReelStyle(
        design: AppDesign.pop,
        posterRadius: 14,
        cardRadius: 20,
        clipRadius: 20,
        borderWidth: 2,
        borderColor: line,
        hardShadow: const Offset(4, 4),
        hardShadowColor: dark ? Colors.black : line,
        softShadow: const [],
        highlight: lime,
        onHighlight: const Color(0xFF17112A),
        accentGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pink, Color(0xFFB04BFF), violet],
        ),
        capsLabels: false,
        nav: NavStyle.floating,
        motion: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        pressScale: 0.92,
        displayFamily: 'BricolageGrotesque',
      ),
    ],
  );
}
