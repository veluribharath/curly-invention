import 'package:reel/domain/entities/media_type.dart';

/// Something that happened on a Discover card, used as a light taste
/// signal.
enum FeedSignalType {
  /// "Not for me": a strong negative; the title isn't shown again.
  notInterested,

  /// Swiped past in under about two seconds: a weak negative.
  skippedFast,

  /// Watched the whole clip at least once: a weak positive.
  watchedClip,

  /// Turned the sound on: a weak positive.
  unmuted,
  openedDetails,
  openedService;

  static FeedSignalType? parse(Object? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

class FeedSignal {
  final TitleId id;
  final FeedSignalType type;
  final DateTime at;

  const FeedSignal({required this.id, required this.type, required this.at});
}
