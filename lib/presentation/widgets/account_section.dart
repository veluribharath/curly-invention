import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:reel/data/services/auth_service.dart';
import 'package:reel/domain/usecases/export_library.dart';
import 'package:reel/presentation/providers/account_providers.dart';
import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// Account, data and app tiles for the You tab.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  Future<void> _run(BuildContext context, Future<String?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final done = await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(accountError(e))));
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _export(BuildContext context, WidgetRef ref, {required bool csv}) async {
    final entries = (ref.read(libraryProvider).value ?? const {}).values;
    final now = ref.read(clockProvider)();
    final text = csv ? libraryToCsv(entries) : libraryToJson(entries, exportedAt: now);
    final name = 'reel-library-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(text)),
            mimeType: csv ? 'text/csv' : 'application/json',
            name: '$name.${csv ? 'csv' : 'json'}',
          ),
        ],
        fileNameOverrides: ['$name.${csv ? 'csv' : 'json'}'],
        subject: 'Reel library',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountStateProvider);
    final actions = ref.read(accountActionsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appleAvailable = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

    Widget header(String text) =>
        Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: SectionHeader(text));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header('Account'),
        if (!account.cloudEnabled)
          const ListTile(
            leading: Icon(Icons.phone_iphone),
            title: Text('Saved on this device'),
            subtitle: Text('Cloud backup is off in this build.'),
          )
        else if (account.anonymous) ...[
          const ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Not backed up to an account yet'),
            subtitle: Text('Sign in to keep your library if you change phones.'),
          ),
          if (appleAvailable)
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('Sign in with Apple'),
              onTap: () => _run(context, () async {
                final result = await actions.link(SignInMethod.apple);
                return result.switchedAccounts ? 'Signed in. Your library was added to that account.' : 'Backed up';
              }),
            ),
          ListTile(
            leading: const Icon(Icons.g_mobiledata),
            title: const Text('Sign in with Google'),
            onTap: () => _run(context, () async {
              final result = await actions.link(SignInMethod.google);
              return result.switchedAccounts ? 'Signed in. Your library was added to that account.' : 'Backed up';
            }),
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: Text(account.email ?? 'Signed in'),
            subtitle: Text(
              'Backed up with ${account.linked.map((m) => m == SignInMethod.apple ? 'Apple' : 'Google').join(' and ')}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              final ok = await _confirm(
                context,
                title: 'Sign out?',
                body: 'Your library stays in your account. This phone starts fresh until you sign in again.',
                action: 'Sign out',
              );
              if (ok && context.mounted) {
                await _run(context, () async {
                  await actions.signOut();
                  return 'Signed out';
                });
              }
            },
          ),
        ],
        header('Your data'),
        ListTile(
          leading: const Icon(Icons.table_view),
          title: const Text('Export library as CSV'),
          onTap: () => _export(context, ref, csv: true),
        ),
        ListTile(
          leading: const Icon(Icons.data_object),
          title: const Text('Export library as JSON'),
          onTap: () => _export(context, ref, csv: false),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
          title: Text(account.cloudEnabled ? 'Delete account and data' : 'Erase my data'),
          onTap: () async {
            final ok = await _confirm(
              context,
              title: 'Delete everything?',
              body: 'Your library, ratings, services and Discover history are erased. This can\'t be undone.',
              action: 'Delete',
            );
            if (ok && context.mounted) {
              await _run(context, () async {
                await actions.deleteEverything();
                return 'Everything was deleted';
              });
            }
          },
        ),
        header('App'),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Theme'),
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            underline: const SizedBox.shrink(),
            onChanged: (mode) {
              if (mode != null) ref.read(themeModeProvider.notifier).set(mode);
            },
            items: const [
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About and credits'),
          onTap: () => context.push('/you/about'),
        ),
      ],
    );
  }
}
