import 'package:firebase_core/firebase_core.dart';

/// Runtime configuration, set with `--dart-define` or
/// `--dart-define-from-file=.env`. Nothing secret lives in source.
class AppConfig {
  const AppConfig._();

  /// TMDB v3 API key (32 hex characters) or v4 read access token (a JWT
  /// starting with "ey"). Empty runs the app on built-in mock data.
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  static bool get hasTmdbKey => tmdbApiKey.trim().isNotEmpty;

  /// Turns on Firebase anonymous auth and Firestore sync. Off, the library
  /// is kept on the device only.
  static const bool useFirebase = bool.fromEnvironment('USE_FIREBASE');

  /// The design the app starts with until one is picked on the You tab:
  /// classic, marquee, aura or pop. Empty means classic.
  static const String design = String.fromEnvironment('REEL_DESIGN');

  static const String _firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _firebaseIosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  /// Options for `Firebase.initializeApp`, or null when a required value is
  /// missing, in which case the platform config files are used.
  static FirebaseOptions? get firebaseOptions {
    if (_firebaseApiKey.isEmpty ||
        _firebaseAppId.isEmpty ||
        _firebaseMessagingSenderId.isEmpty ||
        _firebaseProjectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: _firebaseApiKey,
      appId: _firebaseAppId,
      messagingSenderId: _firebaseMessagingSenderId,
      projectId: _firebaseProjectId,
      storageBucket: _firebaseStorageBucket.isEmpty ? null : _firebaseStorageBucket,
      iosBundleId: _firebaseIosBundleId.isEmpty ? null : _firebaseIosBundleId,
    );
  }
}
