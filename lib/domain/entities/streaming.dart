import 'package:reel/domain/entities/media_type.dart';

/// A streaming, rental or purchase service, identified by its TMDB provider
/// id (JustWatch data).
class StreamingService {
  final int providerId;
  final String name;

  /// TMDB image path of the logo, e.g. "/pbpMk2JmcoNnQwx5JGpXngfoWtp.jpg".
  final String? logoPath;

  /// Lower comes first in TMDB's per-country ordering.
  final int displayPriority;

  const StreamingService({required this.providerId, required this.name, this.logoPath, this.displayPriority = 999});

  @override
  bool operator ==(Object other) => other is StreamingService && other.providerId == providerId;

  @override
  int get hashCode => providerId.hashCode;

  @override
  String toString() => 'StreamingService($providerId, $name)';
}

enum OfferType {
  subscription,
  free,
  ads,
  rent,
  buy;

  /// Offers you can start without paying beyond your subscriptions.
  bool get isStreaming => this == subscription || this == free || this == ads;

  String get label => switch (this) {
    OfferType.subscription => 'Stream',
    OfferType.free => 'Free',
    OfferType.ads => 'Free with ads',
    OfferType.rent => 'Rent',
    OfferType.buy => 'Buy',
  };
}

/// One way to watch a title on one service.
class Offer {
  final StreamingService service;
  final OfferType type;

  /// Opens the title in the service's app. Null when the source doesn't
  /// provide one, as with TMDB's watch provider data.
  final Uri? deepLink;

  /// When the title leaves the service, if the source knows.
  final DateTime? leavingAt;

  const Offer({required this.service, required this.type, this.deepLink, this.leavingAt});
}

/// Where a title can be watched in one country.
class Availability {
  final TitleId id;

  /// ISO 3166-1 alpha-2, e.g. "US".
  final String country;
  final List<Offer> offers;

  /// JustWatch's page for the title, which TMDB links to.
  final Uri? link;
  final DateTime fetchedAt;

  const Availability({
    required this.id,
    required this.country,
    required this.offers,
    this.link,
    required this.fetchedAt,
  });

  bool get isEmpty => offers.isEmpty;

  /// Offers of [type], in the source's order.
  List<Offer> ofType(OfferType type) => [
    for (final offer in offers)
      if (offer.type == type) offer,
  ];

  /// Streaming offers on [serviceIds], plus free ones on any service when
  /// [includeFree]. Each service once, subscription offers first.
  List<Offer> playableOn(Set<int> serviceIds, {bool includeFree = false}) {
    final byService = <int, Offer>{};
    for (final offer in offers) {
      if (!offer.type.isStreaming) continue;
      final mine = serviceIds.contains(offer.service.providerId);
      if (!mine && !(includeFree && offer.type != OfferType.subscription)) continue;
      final seen = byService[offer.service.providerId];
      if (seen == null || offer.type.index < seen.type.index) {
        byService[offer.service.providerId] = offer;
      }
    }
    return byService.values.toList()..sort((a, b) => a.type.index.compareTo(b.type.index));
  }

  bool isPlayableOn(Set<int> serviceIds, {bool includeFree = false}) =>
      playableOn(serviceIds, includeFree: includeFree).isNotEmpty;
}
