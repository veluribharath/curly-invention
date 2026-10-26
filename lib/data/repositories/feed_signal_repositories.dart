import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/feed_signal_repository.dart';

/// Signals older than this are dropped; they say little about taste now.
const signalLifetime = Duration(days: 90);

Map<String, dynamic> _toJson(FeedSignal s) => {
  'id': s.id.encode(),
  'signal': s.type.name,
  'at': s.at.toUtc().toIso8601String(),
};

FeedSignal? _fromJson(Object? raw) {
  if (raw is! Map) return null;
  final id = TitleId.tryParse(raw['id'] as String?);
  final type = FeedSignalType.parse(raw['signal']);
  final at = DateTime.tryParse('${raw['at']}');
  if (id == null || type == null || at == null) return null;
  return FeedSignal(id: id, type: type, at: at.toLocal());
}

/// The most recent signals on the device, at most [maxCount].
class LocalFeedSignalRepository implements FeedSignalRepository {
  static const _key = 'feedSignals.v1';
  static const maxCount = 1000;

  final Future<SharedPreferences> _prefs;
  final DateTime Function() _now;

  LocalFeedSignalRepository({Future<SharedPreferences>? prefs, DateTime Function()? now})
    : _prefs = prefs ?? SharedPreferences.getInstance(),
      _now = now ?? DateTime.now;

  Future<List<FeedSignal>> _load() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null) return [];
    try {
      return [for (final item in json.decode(raw) as List) ?_fromJson(item)];
    } on FormatException {
      return [];
    }
  }

  /// Writes run one at a time, so two signals at once (watched the clip,
  /// then unmuted) both stay.
  Future<void> _pending = Future.value();

  @override
  Future<void> record(FeedSignal signal) {
    final done = _pending.then((_) async {
      final cutoff = _now().subtract(signalLifetime);
      final kept = [
        for (final s in await _load())
          if (s.at.isAfter(cutoff)) s,
        signal,
      ];
      final trimmed = kept.length > maxCount ? kept.sublist(kept.length - maxCount) : kept;
      await (await _prefs).setString(_key, json.encode([for (final s in trimmed) _toJson(s)]));
    });
    _pending = done.catchError((Object _) {});
    return done;
  }

  @override
  Future<List<FeedSignal>> since(DateTime since) async => [
    for (final s in await _load())
      if (s.at.isAfter(since)) s,
  ];

  @override
  Future<void> clear() {
    final done = _pending.then((_) async => (await _prefs).remove(_key));
    _pending = done.catchError((Object _) => true);
    return done;
  }
}

/// Signals in `users/{uid}/signals`. `expireAt` drives a Firestore TTL
/// policy (set it up on the collection group `signals`, field `expireAt`).
class FirestoreFeedSignalRepository implements FeedSignalRepository {
  final FirebaseFirestore _firestore;
  final String uid;

  FirestoreFeedSignalRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _signals =>
      _firestore.collection('users').doc(uid).collection('signals');

  @override
  Future<void> record(FeedSignal signal) async {
    await _signals.add({
      'type': signal.id.type.name,
      'tmdbId': signal.id.tmdbId,
      'signal': signal.type.name,
      'at': Timestamp.fromDate(signal.at),
      'expireAt': Timestamp.fromDate(signal.at.add(signalLifetime)),
    });
  }

  @override
  Future<List<FeedSignal>> since(DateTime since) async {
    final snapshot = await _signals.where('at', isGreaterThan: Timestamp.fromDate(since)).orderBy('at').get();
    return [
      for (final doc in snapshot.docs)
        if ((
              MediaType.parse(doc.data()['type']),
              doc.data()['tmdbId'],
              FeedSignalType.parse(doc.data()['signal']),
              doc.data()['at'],
            )
            case (final MediaType type, final num tmdbId, final FeedSignalType signal, final Timestamp at))
          FeedSignal(id: TitleId(type, tmdbId.toInt()), type: signal, at: at.toDate()),
    ];
  }

  @override
  Future<void> clear() async {
    final docs = await _signals.get();
    for (var i = 0; i < docs.docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final doc in docs.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
