import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
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
///
/// When [onTap] is set, pressing slides the panel down onto its own shadow and
/// releases back. A ripple would belong to a softer language than this one; the
/// shadow collapsing under the press is the feedback the shape already implies.
class HardEdgePanel extends StatefulWidget {
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
  State<HardEdgePanel> createState() => _HardEdgePanelState();
}

class _HardEdgePanelState extends State<HardEdgePanel> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fill = widget.color ?? scheme.surfaceContainer;
    final Color shadow = widget.shadowColor ?? scheme.outline;
    final bool interactive = widget.onTap != null;

    // The panel travels exactly as far as its shadow, so at full press the two
    // are flush and the block looks pushed flat against the page.
    final Offset travel = _pressed && interactive
        ? widget.shadowOffset
        : Offset.zero;

    final Widget content = Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: widget.child,
    );

    final Widget panel = AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.instant),
      curve: AppMotion.enter,
      transform: Matrix4.translationValues(travel.dx, travel.dy, 0),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: scheme.outline, width: widget.borderWidth),
        boxShadow: _pressed && interactive
            ? const <BoxShadow>[]
            : AppEdges.hard(shadow, widget.shadowOffset),
      ),
      child: content,
    );

    if (!interactive) return panel;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (TapDownDetails _) => _setPressed(true),
        onTapUp: (TapUpDetails _) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: panel,
      ),
    );
  }
}
