import 'package:reel/domain/entities/video.dart';

/// The video to show as a title's trailer: an official trailer in
/// [language], then in English, then any trailer, then a teaser.
Video? pickTrailer(List<Video> videos, {String language = 'en'}) {
  final playable = videos.where((v) => v.isYouTube).toList();
  return rankVideos(playable, language: language, kinds: const [VideoKind.trailer, VideoKind.teaser]).firstOrNull;
}

/// [videos] of [kinds], best first: kind in the order given, then official
/// before unofficial, then [language], English, and the rest.
List<Video> rankVideos(List<Video> videos, {required String language, required List<VideoKind> kinds}) {
  int languageRank(Video v) => v.language == language ? 0 : (v.language == 'en' ? 1 : 2);
  final ranked = [
    for (final v in videos)
      if (v.isYouTube && kinds.contains(v.kind)) v,
  ];
  // List.sort isn't stable; break ties by the original order.
  final order = {for (var i = 0; i < videos.length; i++) videos[i]: i};
  ranked.sort((a, b) {
    final byKind = kinds.indexOf(a.kind).compareTo(kinds.indexOf(b.kind));
    if (byKind != 0) return byKind;
    final byOfficial = (b.official ? 1 : 0).compareTo(a.official ? 1 : 0);
    if (byOfficial != 0) return byOfficial;
    final byLanguage = languageRank(a).compareTo(languageRank(b));
    if (byLanguage != 0) return byLanguage;
    return order[a]!.compareTo(order[b]!);
  });
  return ranked;
}
