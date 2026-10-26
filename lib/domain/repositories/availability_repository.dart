import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';

/// Where titles stream. TMDB's watch provider data (from JustWatch) first;
/// a paid source with deep links can replace it without touching the UI.
abstract class AvailabilityRepository {
  Future<Availability> forTitle(TitleId id, String country);

  /// Whether offers come with links that open the title in the service's
  /// app. When false, "Open" goes to the service's search instead.
  bool get hasDeepLinks;

  /// Text to show wherever this data appears, as the source requires.
  String get attribution;
}
