import 'package:reel/domain/entities/media_title.dart';

/// "Movie · 2010 · 2h 28m · ★ 8.4", leaving out what's unknown.
String titleMetaLine(MediaTitle title, {bool withKind = true, bool withRating = true}) {
  final parts = <String>[
    if (withKind) title.kindLabel,
    if (title.year != null) '${title.year}',
    if (title.seasonCount != null)
      '${title.seasonCount} season${title.seasonCount == 1 ? '' : 's'}'
    else if (title.runtimeMinutes != null)
      formatRuntime(title.runtimeMinutes!),
    if (withRating && title.voteAverage != null && title.voteAverage! > 0) '★ ${title.voteAverage!.toStringAsFixed(1)}',
  ];
  return parts.join(' · ');
}

/// "2h 28m", "45m".
String formatRuntime(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}
