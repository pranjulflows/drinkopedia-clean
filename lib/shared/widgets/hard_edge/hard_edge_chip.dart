import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:flutter/material.dart';

/// A square-cornered label with an ink border.
///
/// Two variants. The outline form carries a spirit's type; the filled form
/// carries its ABV, which is present for fewer than half the catalogue and so
/// is worth the extra emphasis when it does appear.
class HardEdgeChip extends StatelessWidget {
  const HardEdgeChip({required this.label, super.key})
    : background = null,
      foreground = null;

  const HardEdgeChip.filled({
    required this.label,
    required Color this.background,
    required Color this.foreground,
    super.key,
  });

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: theme.colorScheme.outline,
          width: AppEdges.borderHairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
