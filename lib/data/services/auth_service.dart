import 'package:firebase_auth/firebase_auth.dart';

enum SignInMethod { apple, google }

/// What linking an account did.
class LinkResult {
  /// The account now signed in.
  final String uid;

  /// Set when the Apple or Google account already had its own Reel account:
  /// we switched to it, and the anonymous account [previousUid] holds data
  /// that should be copied over.
  final String? previousUid;

  const LinkResult(this.uid, {this.previousUid});

  bool get switchedAccounts => previousUid != null;
}

/// Firebase sign-in. Everyone starts with an anonymous account, so nothing
/// stands between installing and using the app; linking Apple or Google
/// later keeps the same account and its data.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// The signed-in user's id, signing in anonymously when nobody is.
  Stream<String?> uidChanges() async* {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    yield* _auth.authStateChanges().asyncMap((user) async {
      // Signing out leaves nobody; start a fresh anonymous account.
      if (user == null) return (await _auth.signInAnonymously()).user?.uid;
      return user.uid;
    });
  }

  User? get currentUser => _auth.currentUser;

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// "Apple", "Google" or null for the linked providers.
  List<SignInMethod> get linkedMethods => [
    for (final info in _auth.currentUser?.providerData ?? const <UserInfo>[])
      if (info.providerId == 'apple.com')
        SignInMethod.apple
      else if (info.providerId == 'google.com')
        SignInMethod.google,
  ];

  String? get email => _auth.currentUser?.email;

  AuthProvider _provider(SignInMethod method) => switch (method) {
    SignInMethod.apple => AppleAuthProvider()..addScope('email'),
    SignInMethod.google => GoogleAuthProvider()..addScope('email'),
  };

  /// Links Apple or Google to the current account. When that Apple or
  /// Google account is already linked to another Reel account, signs in to
  /// that one instead and reports the anonymous account left behind.
  Future<LinkResult> link(SignInMethod method) async {
    final user = _auth.currentUser;
    if (user == null) {
      final credential = await _auth.signInWithProvider(_provider(method));
      return LinkResult(credential.user!.uid);
    }
    try {
      final credential = await user.linkWithProvider(_provider(method));
      return LinkResult(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use' && e.code != 'email-already-in-use') rethrow;
      final previous = user.uid;
      final existing = e.credential;
      final signedIn = existing != null
          ? await _auth.signInWithCredential(existing)
          : await _auth.signInWithProvider(_provider(method));
      return LinkResult(signedIn.user!.uid, previousUid: previous);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Deletes the Firebase account. Firebase may ask for a recent sign-in
  /// first (`requires-recent-login`); callers show that to the user.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
