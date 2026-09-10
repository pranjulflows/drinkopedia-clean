import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/category_label.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';

/// A horizontal row of category chips that narrows the catalogue.
///
/// Scrolls sideways rather than wrapping: ten categories wrap to three or four
/// lines on a phone, which would push the grid half a screen down before
/// anyone has touched it.
///
/// Each chip carries its category's count, so "Liqueur 15" and "Gin 1" say how
/// much is behind them before the tap rather than after.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    required this.counts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Categories with at least one spirit, in display order, and how many.
  final Map<SpiritCategory, int> counts;

  /// The active category, or null when showing everything.
  final SpiritCategory? selected;

  /// Called with the tapped category, or null for "All".
  final ValueChanged<SpiritCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int total = counts.values.fold(0, (int a, int b) => a + b);

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // The chips carry an offset shadow, which is painted outside their box;
        // without the clip turned off the rightmost one's shadow is sliced
        // flat against the edge of the list.
        clipBehavior: Clip.none,
        children: <Widget>[
          _FilterChip(
            label: l10n.filterAll,
            count: total,
            selected: selected == null,
            // Neutral rather than an accent: "All" is the absence of a filter,
            // and giving it a category's colour would make it read as one.
            accent: Theme.of(context).colorScheme.primary,
            onAccent: Theme.of(context).colorScheme.onPrimary,
            onTap: () => onSelected(null),
          ),
          for (final MapEntry<SpiritCategory, int> entry in counts.entries)
            _FilterChip(
              label: categoryLabel(l10n, entry.key),
              count: entry.value,
              selected: selected == entry.key,
              accent: AppColors.accentForCategory(entry.key),
              // The accents are identical in both themes, so their label has to
              // stay dark even in dark mode.
              onAccent: AppColors.ink,
              onTap: () => onSelected(entry.key),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onAccent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final Color onAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = selected ? onAccent : theme.colorScheme.onSurface;

    return Padding(
      // Clears the offset shadow of the chip before it.
      padding: const EdgeInsets.only(right: 10, bottom: 4),
      child: Semantics(
        selected: selected,
        child: HardEdgePanel(
          color: selected ? accent : theme.colorScheme.surfaceContainer,
          // Only the active chip is lifted, so the selection reads from across
          // the row rather than by comparing fills.
          shadowOffset: selected ? AppEdges.shadowCompact : Offset.zero,
          borderWidth: AppEdges.borderHairline,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
