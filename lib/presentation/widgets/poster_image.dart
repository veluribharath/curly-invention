import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:reel/core/tmdb_images.dart';
import 'package:reel/domain/entities/media_title.dart';

/// A title's poster at 2:3, or its name on a tinted card when there's none.
class PosterImage extends StatelessWidget {
  final MediaTitle title;
  final double? width;
  final double radius;
  final String size;

  const PosterImage({super.key, required this.title, this.width, this.radius = 8, this.size = 'w342'});

  @override
  Widget build(BuildContext context) {
    final url = TmdbImages.poster(title.posterPath, size: size);
    final fallback = _NamedPlaceholder(name: title.name);
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: url == null
              ? fallback
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _NamedPlaceholder extends StatelessWidget {
  final String name;

  const _NamedPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A stable tint per title so the grid isn't one flat color.
    final hue = (name.hashCode % 360).abs().toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HSLColor.fromAHSL(1, hue, 0.35, 0.30).toColor(), scheme.surfaceContainerHighest],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// A full-width backdrop image, or nothing when the title has none.
class BackdropImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;

  const BackdropImage({super.key, required this.path, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final url = TmdbImages.backdrop(path);
    if (url == null) return const SizedBox.shrink();
    return CachedNetworkImage(imageUrl: url, fit: fit, errorWidget: (_, _, _) => const SizedBox.shrink());
  }
}
