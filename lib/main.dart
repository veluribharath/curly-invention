import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/core/config/app_config.dart';
import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = AppConfig.useFirebase && await _initFirebase();
  runApp(ProviderScope(overrides: [firebaseEnabledProvider.overrideWithValue(firebase)], child: const ReelApp()));
}

/// Starts Firebase with offline persistence. On failure the app keeps the
/// library on the device instead of not starting.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase failed to start, keeping data on the device: $e');
    return false;
  }
}

class ReelApp extends ConsumerWidget {
  const ReelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Reel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
