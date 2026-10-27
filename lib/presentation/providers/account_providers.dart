import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reel/core/config/app_config.dart';
import 'package:reel/core/theme/app_design.dart';
import 'package:reel/data/repositories/firestore_library_repository.dart';
import 'package:reel/data/services/auth_service.dart';
import 'package:reel/presentation/providers/discover_providers.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/providers/recent_searches.dart';

/// Light, dark or follow the system; dark until you pick.
class ThemeModeSetting extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null && ref.mounted) state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await (await SharedPreferences.getInstance()).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(ThemeModeSetting.new);

/// Which design direction the app wears, kept on the device. Starts on the
/// `REEL_DESIGN` dart-define, or Classic.
class AppDesignSetting extends Notifier<AppDesign> {
  static const _key = 'appDesign';

  /// Overrides the starting design and skips the saved one, for tests.
  final AppDesign? initial;

  AppDesignSetting({this.initial});

  @override
  AppDesign build() {
    if (initial != null) return initial!;
    _load();
    return AppDesign.tryParse(AppConfig.design) ?? AppDesign.classic;
  }

  Future<void> _load() async {
    final saved = AppDesign.tryParse((await SharedPreferences.getInstance()).getString(_key));
    if (saved != null && ref.mounted) state = saved;
  }

  Future<void> set(AppDesign design) async {
    state = design;
    await (await SharedPreferences.getInstance()).setString(_key, design.name);
  }
}

final appDesignProvider = NotifierProvider<AppDesignSetting, AppDesign>(AppDesignSetting.new);

/// What the account section shows.
class AccountState {
  final bool cloudEnabled;
  final bool anonymous;
  final List<SignInMethod> linked;
  final String? email;

  const AccountState({required this.cloudEnabled, this.anonymous = true, this.linked = const [], this.email});
}

final accountStateProvider = Provider<AccountState>((ref) {
  final enabled = ref.watch(firebaseEnabledProvider);
  if (!enabled) return const AccountState(cloudEnabled: false);
  ref.watch(authUidProvider);
  final auth = ref.watch(authServiceProvider);
  return AccountState(cloudEnabled: true, anonymous: auth.isAnonymous, linked: auth.linkedMethods, email: auth.email);
});

final accountActionsProvider = Provider<AccountActions>((ref) => AccountActions(ref));

class AccountActions {
  final Ref _ref;

  AccountActions(this._ref);

  /// Links Apple or Google. When that login already has a Reel account,
  /// switches to it and copies over what this device's account held.
  Future<LinkResult> link(SignInMethod method) async {
    // Read before linking: once we switch accounts, the old one's data is
    // out of reach.
    final entries = (_ref.read(libraryProvider).value ?? const {}).values.toList();
    final result = await _ref.read(authServiceProvider).link(method);
    if (result.switchedAccounts && entries.isNotEmpty) {
      await FirestoreLibraryRepository(uid: result.uid).importEntries(entries);
    }
    _ref.invalidate(authUidProvider);
    return result;
  }

  Future<void> signOut() async {
    await _ref.read(authServiceProvider).signOut();
    _ref.invalidate(authUidProvider);
  }

  /// Erases the library, signals and settings, then the account itself.
  /// Throws [FirebaseAuthException] `requires-recent-login` when Firebase
  /// wants a fresh sign-in first; the data is gone either way.
  Future<void> deleteEverything() async {
    await _ref.read(libraryRepositoryProvider)?.clear();
    await _ref.read(feedSignalRepositoryProvider)?.clear();
    await _ref.read(settingsRepositoryProvider)?.clear();
    await _ref.read(recentSearchesProvider.notifier).clear();
    if (_ref.read(firebaseEnabledProvider)) {
      await _ref.read(authServiceProvider).deleteAccount();
      _ref.invalidate(authUidProvider);
    }
    _ref.invalidate(feedSignalsProvider);
    _ref.invalidate(settingsProvider);
    _ref.invalidate(libraryProvider);
  }
}

/// A message for an account error.
String accountError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'requires-recent-login' => 'Sign in again, then try once more.',
      'web-context-canceled' || 'canceled' => 'Sign-in was canceled.',
      'network-request-failed' => "Can't reach the server. Check your connection.",
      'operation-not-allowed' => 'This sign-in method is not turned on for this app yet.',
      _ => error.message ?? error.code,
    };
  }
  return '$error';
}
