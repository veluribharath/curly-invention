import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/repositories/settings_repository.dart';

/// Settings on the device, used when Firebase is off.
class LocalSettingsRepository implements SettingsRepository {
  static const _country = 'settings.country';
  static const _services = 'settings.serviceIds';
  static const _free = 'settings.includeFreeWithAds';
  static const _onboarded = 'settings.onboardedAt';

  final Future<SharedPreferences> _prefs;
  final _changes = StreamController<UserSettings>.broadcast();

  LocalSettingsRepository({Future<SharedPreferences>? prefs}) : _prefs = prefs ?? SharedPreferences.getInstance();

  @override
  Stream<UserSettings> watchSettings({required UserSettings fallback}) async* {
    final prefs = await _prefs;
    final country = prefs.getString(_country);
    yield country == null
        ? fallback
        : UserSettings(
            country: country,
            serviceIds: {...?prefs.getStringList(_services)?.map(int.tryParse).whereType<int>()},
            includeFreeWithAds: prefs.getBool(_free) ?? false,
            onboardedAt: DateTime.tryParse(prefs.getString(_onboarded) ?? ''),
          );
    yield* _changes.stream;
  }

  @override
  Future<void> save(UserSettings settings) async {
    _changes.add(settings);
    final prefs = await _prefs;
    await prefs.setString(_country, settings.country);
    await prefs.setStringList(_services, [for (final id in settings.serviceIds) '$id']);
    await prefs.setBool(_free, settings.includeFreeWithAds);
    if (settings.onboardedAt != null) {
      await prefs.setString(_onboarded, settings.onboardedAt!.toUtc().toIso8601String());
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    for (final key in [_country, _services, _free, _onboarded]) {
      await prefs.remove(key);
    }
  }
}

/// Settings in the `users/{uid}` document.
class FirestoreSettingsRepository implements SettingsRepository {
  final FirebaseFirestore _firestore;
  final String uid;

  FirestoreSettingsRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore.collection('users').doc(uid);

  @override
  Stream<UserSettings> watchSettings({required UserSettings fallback}) {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      final country = data?['country'];
      if (data == null || country is! String) return fallback;
      final ids = data['serviceIds'];
      final onboarded = data['onboardedAt'];
      return UserSettings(
        country: country,
        serviceIds: {if (ids is List) ...ids.whereType<num>().map((n) => n.toInt())},
        includeFreeWithAds: data['includeFreeWithAds'] == true,
        onboardedAt: onboarded is Timestamp ? onboarded.toDate() : null,
      );
    });
  }

  @override
  Future<void> save(UserSettings settings) {
    return _doc.set({
      'country': settings.country,
      'serviceIds': settings.serviceIds.toList()..sort(),
      'includeFreeWithAds': settings.includeFreeWithAds,
      if (settings.onboardedAt != null) 'onboardedAt': Timestamp.fromDate(settings.onboardedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clear() => _doc.delete();
}
