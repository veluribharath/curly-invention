import 'package:flutter/material.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/presentation/widgets/library_actions.dart';
import 'package:reel/presentation/widgets/poster_image.dart';
import 'package:reel/presentation/widgets/title_meta.dart';

/// A compact row for a title: poster, name, what it is, and actions.
class TitleTile extends StatelessWidget {
  final MediaTitle title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TitleTile({super.key, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap ?? () => openTitle(context, title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            PosterImage(title: title, width: 56, compact: true, size: 'w185'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.name, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(titleMetaLine(title), style: textTheme.bodySmall),
                  if (title.genres.isNotEmpty)
                    Text(
                      title.genres.take(3).join(', '),
                      style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
                ],
              ),
            ),
            trailing ?? QuickLibraryButtons(title: title),
          ],
        ),
      ),
    );
  }
}
