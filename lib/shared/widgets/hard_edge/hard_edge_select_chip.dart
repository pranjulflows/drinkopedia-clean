import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';

/// A selectable chip: one of several picks, on or off.
///
/// Selection is carried by fill and lift, never by colour alone — a selected
/// chip takes its [accent] and a hard shadow; an unselected one sits flat.
/// Shared by the taste intro and the filter sheet so a pick looks the same
/// wherever it is made.
class HardEdgeSelectChip extends StatelessWidget {
  const HardEdgeSelectChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;

  /// The fill when selected. Each category passes its own, so a row of picks
  /// is not one flat block of colour and each stays recognisable.
  final Color accent;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: HardEdgePanel(
        color: selected ? accent : theme.colorScheme.surfaceContainer,
        shadowOffset: selected ? AppEdges.shadowCompact : Offset.zero,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            // The accents are identical in both themes, so a selected chip's
            // label has to stay dark even in dark mode.
            color: selected ? AppColors.ink : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
