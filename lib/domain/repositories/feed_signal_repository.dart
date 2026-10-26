import 'package:reel/domain/entities/feed_signal.dart';

abstract class FeedSignalRepository {
  Future<void> record(FeedSignal signal);

  /// Signals since [since], oldest first.
  Future<List<FeedSignal>> since(DateTime since);

  Future<void> clear();
}
