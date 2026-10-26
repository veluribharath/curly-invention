/// URLs for TMDB image paths at a given width.
class TmdbImages {
  const TmdbImages._();

  static const _base = 'https://image.tmdb.org/t/p';

  static String? poster(String? path, {String size = 'w500'}) => _url(path, size);

  static String? backdrop(String? path, {String size = 'w1280'}) => _url(path, size);

  static String? logo(String? path, {String size = 'w92'}) => _url(path, size);

  static String? _url(String? path, String size) {
    if (path == null || path.isEmpty) return null;
    // Mock data and older records may carry a full URL already.
    if (path.startsWith('http')) return path;
    return '$_base/$size$path';
  }
}
