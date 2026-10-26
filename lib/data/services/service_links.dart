import 'package:reel/domain/entities/streaming.dart';

/// Where "Open in (service)" goes when the offer has no deep link: the
/// service's own search for the title, which phones hand to the service's
/// app when it's installed. Null for services we don't know, so callers fall
/// back to the JustWatch page.
Uri? serviceSearchUrl(StreamingService service, String title) {
  final q = Uri.encodeQueryComponent(title);
  final template = _searchTemplates[service.providerId];
  return template == null ? null : Uri.parse(template.replaceAll('{q}', q));
}

const _searchTemplates = <int, String>{
  8: 'https://www.netflix.com/search?q={q}', // Netflix
  1796: 'https://www.netflix.com/search?q={q}', // Netflix basic with ads
  9: 'https://www.primevideo.com/search/?phrase={q}', // Prime Video
  119: 'https://www.primevideo.com/search/?phrase={q}', // Prime Video (other regions)
  337: 'https://www.disneyplus.com/search?q={q}', // Disney+
  1899: 'https://play.max.com/search?q={q}', // Max
  15: 'https://www.hulu.com/search?q={q}', // Hulu
  350: 'https://tv.apple.com/search?term={q}', // Apple TV+
  2: 'https://tv.apple.com/search?term={q}', // Apple TV store
  3: 'https://play.google.com/store/search?q={q}&c=movies', // Google Play
  386: 'https://www.peacocktv.com/search?q={q}', // Peacock
  531: 'https://www.paramountplus.com/search/?q={q}', // Paramount+
  73: 'https://tubitv.com/search/{q}', // Tubi
  192: 'https://www.youtube.com/results?search_query={q}', // YouTube
  122: 'https://www.hotstar.com/in/explore?search_query={q}', // Hotstar
  2336: 'https://www.hotstar.com/in/explore?search_query={q}', // JioHotstar
  237: 'https://www.sonyliv.com/search?searchTerm={q}', // SonyLIV
};
