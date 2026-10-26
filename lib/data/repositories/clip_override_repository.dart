import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/pick_clip.dart';

/// Hand-picked clip windows in `clipOverrides/{type_tmdbId}`, edited in the
/// Firebase console so popular titles can get a better clip without an app
/// release. Fields: `start` (seconds, required), `length`, `videoKey`.
class ClipOverrideRepository {
  final FirebaseFirestore _firestore;
  final Map<TitleId, ClipOverride?> _cache = {};

  ClipOverrideRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ClipOverride?> forTitle(TitleId id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final data = (await _firestore.collection('clipOverrides').doc(id.docId).get()).data();
    final start = data?['start'];
    final length = data?['length'];
    final key = data?['videoKey'];
    final override = start is num
        ? ClipOverride(
            startSeconds: start.toDouble(),
            lengthSeconds: length is num && length > 0 ? length.toDouble() : null,
            videoKey: key is String && key.isNotEmpty ? key : null,
          )
        : null;
    return _cache[id] = override;
  }
}
