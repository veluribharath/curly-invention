import 'package:flutter/material.dart';

/// A tab that isn't built yet.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? action;

  const PlaceholderScreen({super.key, required this.title, required this.icon, this.action});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
