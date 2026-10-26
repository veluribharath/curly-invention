import 'package:flutter_test/flutter_test.dart';
import 'package:reel/domain/entities/media_type.dart';

void main() {
  test('a title id round-trips through its route and document forms', () {
    const id = TitleId.tv(1396);
    expect(id.encode(), 'tv:1396');
    expect(id.docId, 'tv_1396');
    expect(TitleId.tryParse(id.encode()), id);
    expect(TitleId.tryParse(id.docId), id);
  });

  test('malformed ids parse to null', () {
    for (final raw in [null, '', 'movie', 'movie:', 'film:1', 'movie:abc', 'movie:0', 'movie:1:2']) {
      expect(TitleId.tryParse(raw), isNull, reason: '$raw');
    }
  });

  test('movie and series ids with the same number differ', () {
    expect(const TitleId.movie(1), isNot(const TitleId.tv(1)));
  });
}
