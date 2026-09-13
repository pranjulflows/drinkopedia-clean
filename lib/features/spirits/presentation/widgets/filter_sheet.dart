import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_filter.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/category_label.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/shared/animations/staggered_entrance.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_button.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_select_chip.dart';
import 'package:flutter/material.dart';

/// Slides the filter sheet up over the catalogue.
///
/// Nothing changes until its Show button is tapped: the sheet edits a draft,
/// and dismissing it — by dragging it down or tapping outside — drops the
/// draft and leaves the shelf as it was.
Future<void> showFilterSheet(BuildContext context, SpiritsProvider provider) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.resolve(context, AppMotion.standard),
      reverseDuration: AppMotion.resolve(context, AppMotion.quick),
      curve: AppMotion.emphasized,
      reverseCurve: AppMotion.exit,
    ),
    builder: (BuildContext context) => FilterSheet(provider: provider),
  );
}

/// Category, strength, story and sort, over the spirits shelf.
///
/// Public for tests; open it with [showFilterSheet].
class FilterSheet extends StatefulWidget {
  const FilterSheet({required this.provider, super.key});

  final SpiritsProvider provider;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late SpiritFilter _draft = widget.provider.filter;

  void _edit(SpiritFilter next) => setState(() => _draft = next);

  void _apply() {
    widget.provider.applyFilter(_draft);
    Navigator.of(context).pop();
  }

  static Set<T> _toggled<T>(Set<T> set, T value) => set.contains(value)
      ? (Set<T>.of(set)..remove(value))
      : <T>{...set, value};

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final List<Widget> sections = <Widget>[
      _Section(
        title: l10n.filterCategoryHeading,
        child: _ChipWrap(
          children: <Widget>[
            for (final SpiritCategory category in SpiritCategory.values)
              HardEdgeSelectChip(
                label: categoryLabel(l10n, category),
                accent: AppColors.accentForCategory(category),
                selected: _draft.categories.contains(category),
                onTap: () => _edit(
                  _draft.copyWith(
                    categories: _toggled(_draft.categories, category),
                  ),
                ),
              ),
          ],
        ),
      ),
      _Section(
        title: l10n.filterStrengthHeading,
        note: l10n.strengthNote,
        child: _ChipWrap(
          children: <Widget>[
            for (final (Strength strength, String label, Color accent)
                in <(Strength, String, Color)>[
                  (Strength.light, l10n.strengthLight, AppColors.acid),
                  (Strength.medium, l10n.strengthMedium, AppColors.hotPink),
                  (
                    Strength.strong,
                    l10n.strengthStrong,
                    AppColors.electricBlue,
                  ),
                ])
              HardEdgeSelectChip(
                label: label,
                accent: accent,
                selected: _draft.strengths.contains(strength),
                onTap: () => _edit(
                  _draft.copyWith(
                    strengths: _toggled(_draft.strengths, strength),
                  ),
                ),
              ),
          ],
        ),
      ),
      _Section(
        title: l10n.filterStoryHeading,
        child: _ChipWrap(
          children: <Widget>[
            HardEdgeSelectChip(
              label: l10n.filterStoriesOnly,
              accent: AppColors.acid,
              selected: _draft.storiesOnly,
              onTap: () =>
                  _edit(_draft.copyWith(storiesOnly: !_draft.storiesOnly)),
            ),
          ],
        ),
      ),
      _Section(
        title: l10n.sortHeading,
        child: _ChipWrap(
          children: <Widget>[
            for (final (SpiritSort sort, String label)
                in <(SpiritSort, String)>[
                  (SpiritSort.catalogue, l10n.sortCatalogue),
                  (SpiritSort.aToZ, l10n.sortAToZ),
                  (SpiritSort.strongest, l10n.sortStrongest),
                ])
              // Single choice: the chip stays selected when tapped again,
              // since some sort always applies.
              HardEdgeSelectChip(
                label: label,
                accent: AppColors.acid,
                selected: _draft.sort == sort,
                onTap: () => _edit(_draft.copyWith(sort: sort)),
              ),
          ],
        ),
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: AppEdges.borderHeavy,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // A heavy bar rather than Material's pill: the only shape this
              // direction has is the rectangle.
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 6,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.filters.toUpperCase(),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _draft.isDefault
                          ? null
                          : () => _edit(const SpiritFilter()),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        textStyle: theme.textTheme.labelLarge,
                      ),
                      child: Text(l10n.resetFilters.toUpperCase()),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = 0; i < sections.length; i++)
                        StaggeredEntrance(
                          index: i,
                          // Hard edges do not fade in; see StaggeredEntrance.
                          fade: false,
                          child: sections[i],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                // The count follows pages as they load while the sheet is open.
                child: ListenableBuilder(
                  listenable: widget.provider,
                  builder: (BuildContext context, _) {
                    final int count = widget.provider.countMatching(_draft);
                    return HardEdgeButton(
                      label: widget.provider.hasMore
                          ? l10n.showSpiritsSoFar(count)
                          : l10n.showSpirits(count),
                      onPressed: _apply,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});

  final String title;
  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          child,
          if (note != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chips that wrap onto new lines, spaced to clear each chip's offset shadow.
class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 9, runSpacing: 12, children: children);
  }
}
