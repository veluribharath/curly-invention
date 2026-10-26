import 'package:firebase_auth/firebase_auth.dart';

/// Firebase sign-in. Everyone starts with an anonymous account, so nothing
/// stands between installing and using the app.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// The signed-in user's id, signing in anonymously when nobody is.
  Stream<String?> uidChanges() async* {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    yield* _auth.authStateChanges().map((user) => user?.uid);
  }

  User? get currentUser => _auth.currentUser;
}
