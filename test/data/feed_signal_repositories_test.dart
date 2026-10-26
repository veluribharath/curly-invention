import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/feed_signal_repositories.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 26, 20);

  test('signals recorded at the same moment all stay', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalFeedSignalRepository(now: () => now);
    await Future.wait([
      repo.record(FeedSignal(id: const TitleId.movie(1), type: FeedSignalType.watchedClip, at: now)),
      repo.record(FeedSignal(id: const TitleId.movie(1), type: FeedSignalType.unmuted, at: now)),
      repo.record(FeedSignal(id: const TitleId.tv(2), type: FeedSignalType.notInterested, at: now)),
    ]);
    final signals = await repo.since(now.subtract(const Duration(days: 1)));
    expect(signals.map((s) => s.type), [
      FeedSignalType.watchedClip,
      FeedSignalType.unmuted,
      FeedSignalType.notInterested,
    ]);
  });

  test('old signals are dropped', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalFeedSignalRepository(now: () => now);
    await repo.record(
      FeedSignal(id: const TitleId.movie(1), type: FeedSignalType.skippedFast, at: now.subtract(signalLifetime * 2)),
    );
    await repo.record(FeedSignal(id: const TitleId.movie(2), type: FeedSignalType.unmuted, at: now));
    final signals = await repo.since(DateTime(2000));
    expect(signals.single.id, const TitleId.movie(2));
  });
}
