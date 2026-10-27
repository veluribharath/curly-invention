import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reel/presentation/providers/providers.dart';
import 'package:reel/presentation/widgets/design_kit.dart';

/// Credits the data sources as their terms require, and licenses.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _tmdbNotice = 'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final availability = ref.watch(availabilityRepositoryProvider).attribution;
    Future<void> open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Reel', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('A personal movie and series tracker. Free, no ads, no social features.'),
          const SizedBox(height: 24),
          const SectionHeader('Movie and series data'),
          const SizedBox(height: 8),
          Row(
            children: [
              // TMDB's brand guidelines ask for their logo or name; the
              // logo asset can replace this label once it's added.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF0D253F), borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  'TMDB',
                  style: TextStyle(color: Color(0xFF01B4E4), fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text(_tmdbNotice)),
            ],
          ),
          TextButton(onPressed: () => open('https://www.themoviedb.org'), child: const Text('themoviedb.org')),
          const SizedBox(height: 16),
          const SectionHeader('Where to watch'),
          const SizedBox(height: 8),
          Text('$availability. Availability changes often and may be out of date.'),
          TextButton(onPressed: () => open('https://www.justwatch.com'), child: const Text('justwatch.com')),
          const SizedBox(height: 16),
          const SectionHeader('Trailers'),
          const SizedBox(height: 8),
          const Text('Trailers play through YouTube and are subject to YouTube\'s terms.'),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => showLicensePage(context: context, applicationName: 'Reel'),
            child: const Text('Open-source licenses'),
          ),
        ],
      ),
    );
  }
}
