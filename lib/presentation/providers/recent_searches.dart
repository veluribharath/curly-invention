import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last few searches, newest first, kept on the device.
class RecentSearches extends Notifier<List<String>> {
  static const _key = 'recentSearches.v1';
  static const maxCount = 8;

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final saved = (await SharedPreferences.getInstance()).getStringList(_key);
    if (saved != null && ref.mounted) state = saved;
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [trimmed, ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase())].take(maxCount).toList();
    await (await SharedPreferences.getInstance()).setStringList(_key, state);
  }

  Future<void> clear() async {
    state = const [];
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);
