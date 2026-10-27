import 'package:flutter/material.dart';

import 'package:reel/core/theme/app_design.dart';
import 'package:reel/core/theme/reel_style.dart';

/// Building blocks that look different in each design. Screens use these
/// instead of styling by hand, so a new design only changes this file and
/// the theme.

/// A section's heading: a plain title (Classic), a tracked gold caption with a
/// rule (Marquee), a heavy large title (Aura), or a title on a marker
/// stroke (Pop).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final reel = context.reel;
    final Widget label = switch (reel.design) {
      AppDesign.classic => Text(title, style: textTheme.titleMedium),
      AppDesign.marquee => Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(color: scheme.primary, letterSpacing: 2.2, fontWeight: FontWeight.w700),
      ),
      AppDesign.aura => Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 21, letterSpacing: -0.5)),
      AppDesign.pop => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.58, 0.58, 0.92, 0.92],
            colors: [
              Colors.transparent,
              Colors.transparent,
              reel.highlight.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 1),
              reel.highlight.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 1),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 22)),
        ),
      ),
    };
    return Row(
      children: [
        if (reel.design == AppDesign.marquee) ...[
          label,
          const SizedBox(width: 12),
          Expanded(child: Divider(color: scheme.primary.withValues(alpha: 0.35))),
        ] else
          Flexible(
            fit: FlexFit.tight,
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
        ?trailing,
      ],
    );
  }
}

/// A short label above or beside a title, such as what kind of title it is.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;

  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reel = context.reel;
    final style = theme.textTheme.labelSmall;
    return switch (reel.design) {
      AppDesign.marquee => Text(
        text.toUpperCase(),
        style: style?.copyWith(color: color ?? theme.colorScheme.primary, letterSpacing: 2, fontSize: 10.5),
      ),
      AppDesign.pop => DecoratedBox(
        decoration: BoxDecoration(
          color: reel.highlight,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: reel.borderColor, width: reel.borderWidth),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          child: Text(text, style: style?.copyWith(color: reel.onHighlight)),
        ),
      ),
      _ => Text(text, style: style?.copyWith(color: color ?? theme.colorScheme.primary)),
    };
  }
}

/// A card-like surface with the design's corners, outline and shadow.
class ReelSurface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ReelSurface({
    super.key,
    required this.child,
    this.color,
    this.radius,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reel = context.reel;
    final r = radius ?? reel.cardRadius;
    final decoration = reel.surface(color: color ?? Theme.of(context).colorScheme.surfaceContainerLow, radius: r);
    final content = Padding(padding: padding, child: child);
    return PressScale(
      enabled: onTap != null,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          child: onTap == null
              ? content
              : InkWell(borderRadius: BorderRadius.circular(r), onTap: onTap, child: content),
        ),
      ),
    );
  }
}

/// Shrinks its child a little while pressed, by the design's
/// [ReelStyle.pressScale], and springs back on release.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PressScale({super.key, required this.child, this.enabled = true});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reel = context.reel;
    if (!widget.enabled || reel.pressScale >= 1 || MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? reel.pressScale : 1,
        duration: Duration(milliseconds: _down ? 90 : 320),
        curve: _down ? Curves.easeOut : reel.curve,
        child: widget.child,
      ),
    );
  }
}

/// The screen's one main action, full width: a gradient in Aura, a pill on a
/// hard shadow in Pop, the themed button elsewhere.
class HeroButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const HeroButton({super.key, required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final reel = context.reel;
    final scheme = Theme.of(context).colorScheme;
    final button = FilledButton.icon(icon: icon, label: Text(label), onPressed: onPressed);
    final Widget styled = switch (reel.design) {
      AppDesign.aura => DecoratedBox(
        decoration: ShapeDecoration(
          gradient: reel.accentGradient,
          shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          shadows: [
            BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: FilledButton.icon(
          icon: icon,
          label: Text(label),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
      AppDesign.pop => DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: [BoxShadow(color: reel.hardShadowColor, offset: reel.hardShadow)],
        ),
        child: button,
      ),
      _ => button,
    };
    return SizedBox(
      width: double.infinity,
      child: PressScale(child: styled),
    );
  }
}

/// A round or rounded badge holding an icon, for empty and error states.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const IconBadge({super.key, required this.icon, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final reel = context.reel;
    final scheme = Theme.of(context).colorScheme;
    return switch (reel.design) {
      AppDesign.classic => Icon(icon, size: size, color: scheme.outline),
      AppDesign.marquee => Container(
        width: size * 1.8,
        height: size * 1.8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Icon(icon, size: size * 0.7, color: scheme.primary),
      ),
      AppDesign.aura => Container(
        width: size * 1.8,
        height: size * 1.8,
        decoration: ShapeDecoration(
          gradient: reel.accentGradient,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(size * 0.6)),
          shadows: reel.softShadow,
        ),
        child: Icon(icon, size: size * 0.75, color: Colors.white),
      ),
      AppDesign.pop => Transform.rotate(
        angle: -0.08,
        child: Container(
          width: size * 1.8,
          height: size * 1.8,
          decoration: reel.surface(color: reel.highlight, radius: size * 0.5),
          child: Icon(icon, size: size * 0.8, color: reel.onHighlight),
        ),
      ),
    };
  }
}
