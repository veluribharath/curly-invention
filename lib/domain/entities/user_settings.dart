/// Where you live and what you pay for, which decide what "available"
/// means.
class UserSettings {
  /// ISO 3166-1 alpha-2, e.g. "US".
  final String country;

  /// TMDB provider ids of your subscriptions.
  final Set<int> serviceIds;

  /// Also count free and ad-supported services (Tubi, Pluto TV, ...).
  final bool includeFreeWithAds;

  /// When first-run setup was finished; null until then.
  final DateTime? onboardedAt;

  const UserSettings({
    required this.country,
    this.serviceIds = const {},
    this.includeFreeWithAds = false,
    this.onboardedAt,
  });

  bool get onboarded => onboardedAt != null;

  UserSettings copyWith({String? country, Set<int>? serviceIds, bool? includeFreeWithAds, DateTime? onboardedAt}) {
    return UserSettings(
      country: country ?? this.country,
      serviceIds: serviceIds ?? this.serviceIds,
      includeFreeWithAds: includeFreeWithAds ?? this.includeFreeWithAds,
      onboardedAt: onboardedAt ?? this.onboardedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.country == country &&
      other.serviceIds.length == serviceIds.length &&
      other.serviceIds.containsAll(serviceIds) &&
      other.includeFreeWithAds == includeFreeWithAds &&
      other.onboardedAt == onboardedAt;

  @override
  int get hashCode => Object.hash(country, Object.hashAllUnordered(serviceIds), includeFreeWithAds, onboardedAt);
}
