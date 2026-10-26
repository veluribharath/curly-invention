import 'package:reel/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  /// The saved settings, or [fallback] before anything was saved; again after
  /// each change.
  Stream<UserSettings> watchSettings({required UserSettings fallback});

  Future<void> save(UserSettings settings);

  Future<void> clear();
}
