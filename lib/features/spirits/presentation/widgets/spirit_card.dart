import 'package:cached_network_image/cached_network_image.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:flutter/material.dart';

/// Catalogue tile.
///
/// The image sits in a [Hero] keyed by spirit id so it flies into the detail
/// screen; the tag must match the one used there.
class SpiritCard extends StatelessWidget {
  const SpiritCard({required this.spirit, required this.onTap, super.key});

  final Spirit spirit;
  final VoidCallback onTap;

  static String heroTag(String id) => 'spirit-image-$id';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Hero(
                tag: heroTag(spirit.id),
                child: _SpiritImage(spirit: spirit),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    spirit.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      if (spirit.hasType)
                        Flexible(
                          child: Text(
                            spirit.type!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // ABV is absent for most entries upstream, so it is shown
                      // only when real rather than rendered as a blank slot.
                      if (spirit.hasAbv) ...<Widget>[
                        if (spirit.hasType)
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        Text(
                          '${spirit.abv!.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpiritImage extends StatelessWidget {
  const _SpiritImage({required this.spirit});

  final Spirit spirit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.local_bar_outlined,
          size: 36,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    if (spirit.imageUrl == null) return fallback;

    return CachedNetworkImage(
      imageUrl: spirit.imageUrl!,
      fit: BoxFit.cover,
      fadeInDuration: AppMotion.quick,
      placeholder: (BuildContext context, String url) =>
          ColoredBox(color: scheme.surfaceContainerHighest),
      errorWidget: (BuildContext context, String url, Object error) => fallback,
    );
  }
}
