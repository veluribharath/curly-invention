import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reel/core/theme/app_theme.dart';
import 'package:reel/presentation/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: ReelApp()));
}

class ReelApp extends StatefulWidget {
  const ReelApp({super.key});

  @override
  State<ReelApp> createState() => _ReelAppState();
}

class _ReelAppState extends State<ReelApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Reel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
