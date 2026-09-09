import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:flutter/material.dart';

/// A bordered block with a hard offset shadow — the direction's base surface.
///
/// The shadow is drawn with zero blur, so it is a solid second rectangle rather
/// than a glow. That is why this is not a [Card]: Material's `elevation` always
/// blurs, and the whole look rests on the shadow staying sharp.
///
/// The shadow is painted *outside* the panel's own box, so leave room for
/// [shadowOffset] in whatever lays this out — a grid needs its spacing to
/// exceed the offset or neighbours will sit on top of it.
class HardEdgePanel extends StatelessWidget {
  const HardEdgePanel({
    required this.child,
    this.color,
    this.borderWidth = AppEdges.border,
    this.shadowOffset = AppEdges.shadow,
    this.shadowColor,
    this.onTap,
    this.padding,
    super.key,
  });

  final Widget child;

  /// Defaults to the scheme's card fill.
  final Color? color;

  final double borderWidth;
  final Offset shadowOffset;

  /// Defaults to the outline ink. The primary button overrides it to throw a
  /// coloured shadow instead.
  final Color? shadowColor;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fill = color ?? scheme.surfaceContainer;

    final Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: scheme.outline, width: borderWidth),
        boxShadow: AppEdges.hard(shadowColor ?? scheme.outline, shadowOffset),
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                // A flat press tint, not a ripple: the edges are hard, so the
                // feedback is too.
                highlightColor: scheme.onSurface.withValues(alpha: 0.10),
                hoverColor: scheme.onSurface.withValues(alpha: 0.04),
                splashFactory: NoSplash.splashFactory,
                child: content,
              ),
            ),
    );
  }
}
