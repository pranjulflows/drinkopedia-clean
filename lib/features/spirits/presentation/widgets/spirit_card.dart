import 'package:cached_network_image/cached_network_image.dart';
import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_chip.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

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

    return HardEdgePanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Hero(
              tag: heroTag(spirit.id),
              child: SpiritArtwork(spirit: spirit),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  spirit.name.toUpperCase(),
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    if (spirit.hasType)
                      Flexible(child: HardEdgeChip(label: spirit.type!)),
                    // ABV is absent for most entries upstream, so it is shown
                    // only when real rather than rendered as a blank slot.
                    if (spirit.hasAbv) ...<Widget>[
                      if (spirit.hasType) const SizedBox(width: 5),
                      HardEdgeChip.filled(
                        label: '${spirit.abv!.toStringAsFixed(0)}%',
                        background: theme.colorScheme.primary,
                        foreground: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A spirit's artwork on its flat colour ground.
///
/// Upstream art is a transparent-background bottle cutout, not photography, so
/// it is *contained* on a coloured block rather than cropped to fill one — a
/// `BoxFit.cover` here would slice the top and bottom off the bottle.
class SpiritArtwork extends StatelessWidget {
  const SpiritArtwork({
    required this.spirit,
    this.padding = const EdgeInsets.all(10),
    this.fallbackIconSize = 36,
    super.key,
  });

  final Spirit spirit;
  final EdgeInsetsGeometry padding;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final Color well = AppColors.wellForId(spirit.id);

    final Widget fallback = Center(
      child: Icon(
        Icons.local_bar_outlined,
        size: fallbackIconSize,
        color: AppColors.ink,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: well,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: AppEdges.border,
          ),
        ),
      ),
      padding: padding,
      child: spirit.imageUrl == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: spirit.imageUrl!,
              cacheManager: context.read<BaseCacheManager>(),
              fit: BoxFit.contain,
              fadeInDuration: AppMotion.quick,
              placeholder: (BuildContext context, String url) =>
                  const SizedBox.shrink(),
              errorWidget: (BuildContext context, String url, Object error) =>
                  fallback,
            ),
    );
  }
}
