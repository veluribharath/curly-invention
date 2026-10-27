import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/presentation/widgets/design_kit.dart';

/// Loading spinner, error with retry, or [data].
class AsyncBody<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  const AsyncBody({super.key, required this.value, required this.data, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncValue(hasValue: true, :final value) => data(value as T),
      AsyncError(:final error) => ErrorMessage(message: friendlyError(error), onRetry: onRetry),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessage({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(icon: Icons.cloud_off, size: 40),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const EmptyMessage({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon: icon),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// A short message for an error, without stack traces or class names.
String friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException') || text.contains('timed out')) {
    return "Can't reach the server. Check your connection.";
  }
  return text.replaceFirst(RegExp(r'^(Exception|StateError|Bad state): ?'), '');
}
