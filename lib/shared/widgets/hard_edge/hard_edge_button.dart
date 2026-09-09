import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';

/// The primary action: a solid ink block with an acid label.
///
/// Its shadow is thrown in [AppColors.hotPink] rather than ink — the one place
/// in the direction where the shadow is not the foreground colour, which is
/// what marks it out as the primary action on a screen.
class HardEdgeButton extends StatelessWidget {
  const HardEdgeButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return HardEdgePanel(
      color: theme.colorScheme.primary,
      shadowColor: AppColors.hotPink,
      onTap: onPressed,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// A square icon action — refresh on the catalogue, back on the detail screen.
///
/// Sized above [AppEdges.minTapTarget] and matched to the search field's height
/// so the two line up when they share a row.
class HardEdgeIconButton extends StatelessWidget {
  const HardEdgeIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.background,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final Color ground = background ?? AppColors.acid;
    // Derived from the actual ground rather than from the theme. The accent
    // grounds are identical in light and dark, so a glyph keyed to the theme
    // disappears on them — and a caller may pass a surface colour that flips
    // with the theme, which is how the back button turned into an empty box in
    // dark mode.
    final Color glyph =
        ThemeData.estimateBrightnessForColor(ground) == Brightness.dark
        ? AppColors.paper
        : AppColors.ink;

    return Tooltip(
      message: tooltip,
      child: HardEdgePanel(
        color: ground,
        shadowOffset: AppEdges.shadowCompact,
        onTap: onPressed,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 20, color: glyph),
        ),
      ),
    );
  }
}
