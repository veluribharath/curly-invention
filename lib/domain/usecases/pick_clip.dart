import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/video.dart';
import 'package:reel/domain/usecases/pick_video.dart';

/// A hand-picked start time for a title's reel, which beats the defaults.
class ClipOverride {
  /// Play this video instead of the one picked; null keeps the pick.
  final String? videoKey;
  final double startSeconds;
  final double? lengthSeconds;

  const ClipOverride({this.videoKey, required this.startSeconds, this.lengthSeconds});
}

/// The stretch of a video a reel plays, then loops.
class ClipWindow {
  final double start;
  final double end;

  const ClipWindow(this.start, this.end);

  double get length => end - start;

  @override
  bool operator ==(Object other) => other is ClipWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ClipWindow($start, $end)';
}

/// How long a reel plays before looping.
const clipLength = 25.0;

/// Trailers open with studio logos and slow setup: skip about the first 15%,
/// and at least this much.
const trailerMinStart = 20.0;
const _trailerSkip = 0.15;

/// Leave the end alone: trailers close on title cards and release dates.
const _tailMargin = 5.0;

/// Videos to try on a reel, best first; the next is tried when one won't
/// play (embedding blocked, region locked).
///
/// Short official clips and teasers come first, since they're usually a
/// self-contained scene; then trailers; then featurettes. An override's video
/// goes first.
List<Video> clipCandidates(MediaTitle title, {String language = 'en', ClipOverride? override}) {
  final short = rankVideos(
    [
      for (final v in title.videos)
        if (v.official) v,
    ],
    language: language,
    kinds: const [VideoKind.clip, VideoKind.teaser],
  );
  final trailers = rankVideos(title.videos, language: language, kinds: const [VideoKind.trailer]);
  final rest = rankVideos(title.videos, language: language, kinds: const [VideoKind.featurette]);
  final ordered = [...short, ...trailers, ...rest];
  final overrideKey = override?.videoKey;
  if (overrideKey != null) {
    final picked = title.videos.where((v) => v.key == overrideKey && v.isYouTube);
    return [...picked, ...ordered.where((v) => v.key != overrideKey)];
  }
  return ordered;
}

/// The window to play of [video], given its length once the player knows it.
///
/// Clips and teasers play from the start. Trailers skip the opening. Without
/// a duration the trailer start is [trailerMinStart]. An override wins when
/// it's for this video, or names no video.
ClipWindow clipWindow(Video video, {double? durationSeconds, ClipOverride? override}) {
  final duration = durationSeconds != null && durationSeconds > 0 ? durationSeconds : null;
  if (override != null && (override.videoKey == null || override.videoKey == video.key)) {
    final length = override.lengthSeconds ?? clipLength;
    final start = duration == null ? override.startSeconds : override.startSeconds.clamp(0.0, duration).toDouble();
    final end = duration == null ? start + length : (start + length).clamp(start, duration).toDouble();
    return ClipWindow(start, end);
  }

  final skipsOpening = video.kind == VideoKind.trailer || video.kind == VideoKind.featurette;
  var start = 0.0;
  if (skipsOpening) {
    start = duration == null ? trailerMinStart : (duration * _trailerSkip).clamp(trailerMinStart, double.infinity);
  }
  if (duration == null) return ClipWindow(start, start + clipLength);

  // Short videos: pull the start back so a full clip fits, or play it all.
  final latestStart = duration - clipLength - (skipsOpening ? _tailMargin : 0);
  if (start > latestStart) start = latestStart < 0 ? 0 : latestStart;
  final end = (start + clipLength).clamp(start, duration).toDouble();
  return ClipWindow(start, end);
}
