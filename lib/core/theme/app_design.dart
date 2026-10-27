/// The app's design directions. Behavior and data are the same in each; only
/// the look changes. Picked on the You tab, or the first-run default set with
/// `--dart-define=REEL_DESIGN=marquee`.
enum AppDesign {
  classic('Classic', 'The current look', 'Material 3, indigo, nothing changed.'),
  marquee(
    'Marquee',
    'Cinematic and editorial',
    'A film-festival program: ink black, gold leaf, serif titles, credits-style labels and slow fades.',
  ),
  aura(
    'Aura',
    'Calm, glassy, light',
    'Frosted glass, soft depth and squircle shapes, big quiet titles, with springy, native-feeling motion.',
  ),
  pop(
    'Pop',
    'Loud, graphic, playful',
    'Acid lime on deep violet, thick outlines and hard shadows, sticker labels and bouncy motion.',
  );

  final String label;
  final String tagline;
  final String description;

  const AppDesign(this.label, this.tagline, this.description);

  /// The design named [name], or null for an unknown or empty name.
  static AppDesign? tryParse(String? name) {
    final key = name?.trim().toLowerCase();
    return values.where((d) => d.name == key).firstOrNull;
  }
}
