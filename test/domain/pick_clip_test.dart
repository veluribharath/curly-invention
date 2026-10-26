import 'package:flutter_test/flutter_test.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/video.dart';
import 'package:reel/domain/usecases/pick_clip.dart';
import 'package:reel/domain/usecases/pick_video.dart';

void main() {
  const trailer = Video(key: 'trailer', kind: VideoKind.trailer);
  const unofficialClip = Video(key: 'fan', kind: VideoKind.clip, official: false);
  const clip = Video(key: 'clip', kind: VideoKind.clip);
  const teaserFr = Video(key: 'teaser-fr', kind: VideoKind.teaser, language: 'fr');
  const vimeo = Video(key: 'vimeo', kind: VideoKind.trailer, site: 'Vimeo');

  MediaTitle titleWith(List<Video> videos) => MediaTitle(id: const TitleId.movie(1), name: 'T', videos: videos);

  test('official clips and teasers come before trailers', () {
    final order = clipCandidates(titleWith([trailer, unofficialClip, teaserFr, clip, vimeo])).map((v) => v.key);
    expect(order, ['clip', 'teaser-fr', 'trailer']);
  });

  test('an override puts its video first', () {
    final order = clipCandidates(
      titleWith([trailer, clip]),
      override: const ClipOverride(videoKey: 'trailer', startSeconds: 42),
    ).map((v) => v.key);
    expect(order, ['trailer', 'clip']);
  });

  test('trailers skip the opening, clips play from the start', () {
    expect(clipWindow(trailer), const ClipWindow(20, 45));
    expect(clipWindow(trailer, durationSeconds: 150), const ClipWindow(22.5, 47.5));
    expect(clipWindow(clip, durationSeconds: 90), const ClipWindow(0, 25));
  });

  test('short trailers pull the start back so the clip fits', () {
    expect(clipWindow(trailer, durationSeconds: 40), const ClipWindow(10, 35));
    expect(clipWindow(trailer, durationSeconds: 20), const ClipWindow(0, 20));
  });

  test('an override sets the window, clamped to the video', () {
    const override = ClipOverride(startSeconds: 100, lengthSeconds: 30);
    expect(clipWindow(trailer, override: override), const ClipWindow(100, 130));
    expect(clipWindow(trailer, durationSeconds: 110, override: override), const ClipWindow(100, 110));
  });

  test('the details trailer prefers official trailers in your language', () {
    const es = Video(key: 'es', kind: VideoKind.trailer, language: 'es');
    const en = Video(key: 'en', kind: VideoKind.trailer, language: 'en', official: false);
    expect(pickTrailer([en, es], language: 'es')!.key, 'es');
    expect(pickTrailer([teaserFr, en])!.key, 'en');
    expect(pickTrailer([vimeo]), isNull);
  });
}
