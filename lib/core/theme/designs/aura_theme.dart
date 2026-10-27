import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/core/theme/reel_style.dart';

/// Aura: calm and native-feeling. Grouped grey backgrounds with white cards
/// (true black at night), frosted glass bars, squircle corners, soft depth,
/// Manrope in heavy, tight large titles, and Cupertino-style springs.
ThemeData auraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFF5F5F7) : const Color(0xFF0B0B0F);
  final indigo = dark ? const Color(0xFF8E8BFF) : const Color(0xFF5450E0);
  final pink = dark ? const Color(0xFFFF6482) : const Color(0xFFD1173F);
  final card = dark ? const Color(0xFF1C1C1E) : Colors.white;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF5E5CE6),
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ).copyWith(
        primary: indigo,
        onPrimary: dark ? const Color(0xFF0B0A33) : Colors.white,
        primaryContainer: dark ? const Color(0xFF2B2A5C) : const Color(0xFFE6E5FF),
        onPrimaryContainer: dark ? const Color(0xFFE2E1FF) : const Color(0xFF1C1A6B),
        secondary: pink,
        onSecondary: dark ? const Color(0xFF2A0010) : Colors.white,
        secondaryContainer: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EF),
        onSecondaryContainer: ink,
        tertiary: dark ? const Color(0xFF30D158) : const Color(0xFF248A3D),
        onTertiary: Colors.white,
        surface: dark ? Colors.black : const Color(0xFFF2F2F7),
        onSurface: ink,
        onSurfaceVariant: dark ? const Color(0xFF98989F) : const Color(0xFF6C6C72),
        surfaceContainerLowest: dark ? Colors.black : Colors.white,
        surfaceContainerLow: card,
        surfaceContainer: dark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceContainerHigh: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        surfaceContainerHighest: dark ? const Color(0xFF3A3A3C) : const Color(0xFFD9D9DF),
        outline: dark ? const Color(0xFF636366) : const Color(0xFFAEAEB2),
        outlineVariant: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E0E5),
        inverseSurface: ink,
        onInverseSurface: dark ? Colors.black : Colors.white,
      );
  final textTheme = designTextTheme(
    brightness: brightness,
    display: 'Manrope',
    body: 'Manrope',
    displayWeight: FontWeight.w800,
    displayTracking: -0.7,
    titleWeight: FontWeight.w700,
    bodyWeight: FontWeight.w500,
    labelWeight: FontWeight.w700,
    labelTracking: 0,
  ).apply(bodyColor: ink, displayColor: ink);
  final text = localized(textTheme);
  const squircle = RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(16)));
  final buttonText = text.labelLarge?.copyWith(fontSize: 15);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 15);

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'Manrope',
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 0.6, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: ink,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 20,
      titleTextStyle: text.headlineMedium?.copyWith(fontSize: 32, letterSpacing: -1.2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 62,
      indicatorColor: indigo.withValues(alpha: dark ? 0.24 : 0.12),
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? indigo : scheme.onSurfaceVariant),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall?.copyWith(
          fontSize: 11,
          color: states.contains(WidgetState.selected) ? indigo : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: squircle, textStyle: buttonText, padding: buttonPadding),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: squircle,
        textStyle: buttonText,
        padding: buttonPadding,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: squircle, textStyle: buttonText?.copyWith(fontSize: 15)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: const StadiumBorder(),
      backgroundColor: indigo,
      foregroundColor: scheme.onPrimary,
      elevation: 6,
      highlightElevation: 2,
      extendedTextStyle: buttonText,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(squircle),
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? card : scheme.surfaceContainerHigh,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? ink : scheme.onSurfaceVariant,
        ),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: indigo,
      secondarySelectedColor: indigo,
      checkmarkColor: scheme.onPrimary,
      labelStyle: text.labelLarge?.copyWith(fontSize: 13),
      secondaryLabelStyle: text.labelLarge?.copyWith(fontSize: 13, color: scheme.onPrimary),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: indigo,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
      shape: const WidgetStatePropertyAll(squircle),
      textStyle: WidgetStatePropertyAll(text.bodyLarge),
      constraints: const BoxConstraints(minHeight: 48),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? scheme.tertiary : scheme.surfaceContainerHighest,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.outline,
      shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
      titleTextStyle: text.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: squircle,
      backgroundColor: scheme.inverseSurface,
      actionTextColor: dark ? const Color(0xFF5450E0) : const Color(0xFF8E8BFF),
    ),
    pageTransitionsTheme: allPlatforms(const CupertinoPageTransitionsBuilder()),
    extensions: [
      ReelStyle(
        design: AppDesign.aura,
        posterRadius: 14,
        cardRadius: 22,
        clipRadius: 24,
        borderWidth: 0,
        borderColor: Colors.transparent,
        hardShadow: Offset.zero,
        hardShadowColor: Colors.transparent,
        softShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.5 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        highlight: pink,
        onHighlight: dark ? const Color(0xFF2A0010) : Colors.white,
        accentGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E6BFF), Color(0xFFB45CFF), Color(0xFFFF6482)],
        ),
        capsLabels: false,
        nav: NavStyle.glass,
        motion: const Duration(milliseconds: 380),
        curve: Curves.easeOutQuart,
        pressScale: 0.95,
        displayFamily: 'Manrope',
      ),
    ],
  );
}
