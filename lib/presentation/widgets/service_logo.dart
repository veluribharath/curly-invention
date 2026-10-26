import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:reel/core/tmdb_images.dart';
import 'package:reel/domain/entities/streaming.dart';

/// A service's official logo from TMDB, always at the same size; its
/// initials when there's no logo.
class ServiceLogo extends StatelessWidget {
  final StreamingService service;
  final double size;

  const ServiceLogo({super.key, required this.service, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final url = TmdbImages.logo(service.logoPath, size: size > 48 ? 'w154' : 'w92');
    final fallback = _Initials(name: service.name, size: size);
    return Tooltip(
      message: service.name,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: SizedBox.square(
          dimension: size,
          child: url == null
              ? fallback
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final double size;

  const _Initials({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    final hue = (name.hashCode % 360).abs().toDouble();
    return ColoredBox(
      color: HSLColor.fromAHSL(1, hue, 0.45, 0.35).toColor(),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.38),
        ),
      ),
    );
  }
}

/// A row of logos for the services a title streams on.
class ServiceLogoRow extends StatelessWidget {
  final List<Offer> offers;
  final double size;
  final int max;

  const ServiceLogoRow({super.key, required this.offers, this.size = 22, this.max = 4});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      children: [for (final offer in offers.take(max)) ServiceLogo(service: offer.service, size: size)],
    );
  }
}
