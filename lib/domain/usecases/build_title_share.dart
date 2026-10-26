import 'package:reel/domain/entities/media_type.dart';

/// Text and subject for sharing a title with someone outside the app.
class TitleShare {
  final String subject;
  final String text;
  final Uri link;

  const TitleShare({required this.subject, required this.text, required this.link});
}

/// A share message that links to the title's TMDB page. Adapted from
/// resonance's `buildMovieShare`.
TitleShare buildTitleShare({required TitleId id, required String name, int? year}) {
  final link = Uri.https('www.themoviedb.org', '/${id.type.name}/${id.tmdbId}');
  final label = year == null ? name : '$name ($year)';
  return TitleShare(subject: label, text: 'Check out $label: $link', link: link);
}
