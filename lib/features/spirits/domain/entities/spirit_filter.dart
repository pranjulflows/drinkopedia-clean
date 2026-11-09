import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:equatable/equatable.dart';

/// How strong a spirit is, in the three bands the filter offers.
///
/// Only a spirit with a known ABV has one. TheCocktailDB gives an ABV for well
/// under half the catalogue, so this is never inferred from the category: an
/// unknown ABV stays unknown rather than being guessed into a band.
enum Strength {
  /// Under 20% — wine, beer, cider and cream liqueurs.
  light,

  /// 20% up to just under 37.5% — most liqueurs and fortified wines.
  medium,

  /// 37.5% and over — the EU minimum for a spirit to be sold as one.
  strong;

  /// Lower bound of [medium], inclusive.
  static const double mediumFrom = 20;

  /// Lower bound of [strong], inclusive.
  static const double strongFrom = 37.5;

  /// The band [abv] falls in, or null when it is unknown.
  static Strength? of(double? abv) {
    if (abv == null) return null;
    if (abv >= strongFrom) return strong;
    if (abv >= mediumFrom) return medium;
    return light;
  }
}

/// The orders the shelf can be read in.
enum SpiritSort {
  /// The catalogue's own order: spirits with a story first, each group A–Z.
  catalogue,

  /// Alphabetical by name.
  aToZ,

  /// Highest ABV first; spirits with no known ABV go last.
  strongest,
}

/// What the shelf is narrowed to and how it is ordered.
///
/// Every part composes with the others — two categories, a strength band and
/// "stories only" together mean spirits that pass *all* of them — and the
/// default filter lets everything through in catalogue order.
class SpiritFilter extends Equatable {
  const SpiritFilter({
    this.categories = const <SpiritCategory>{},
    this.strengths = const <Strength>{},
    this.storiesOnly = false,
    this.sort = SpiritSort.catalogue,
  });

  /// Categories to keep. Empty keeps every category.
  final Set<SpiritCategory> categories;

  /// Strength bands to keep. Empty keeps everything, including spirits whose
  /// ABV is unknown; any band at all drops those, since they cannot be placed.
  final Set<Strength> strengths;

  /// Keep only spirits that have an origin story.
  final bool storiesOnly;

  final SpiritSort sort;

  /// Whether this filter hides or reorders anything.
  bool get isDefault => activeCount == 0;

  /// Whether this filter hides anything, as opposed to only reordering.
  bool get narrows =>
      categories.isNotEmpty || strengths.isNotEmpty || storiesOnly;

  /// How many filter choices are active, for the badge on the Filters button.
  ///
  /// Each category and each band counts once, as does "stories only" and a
  /// non-default sort — the number a person would get by counting what they
  /// ticked in the sheet.
  int get activeCount =>
      categories.length +
      strengths.length +
      (storiesOnly ? 1 : 0) +
      (sort == SpiritSort.catalogue ? 0 : 1);

  /// Whether [spirit] passes every part of the filter. Ignores [sort].
  bool matches(Spirit spirit) {
    if (categories.isNotEmpty && !categories.contains(spirit.category)) {
      return false;
    }
    if (strengths.isNotEmpty && !strengths.contains(Strength.of(spirit.abv))) {
      return false;
    }
    if (storiesOnly && !spirit.hasStory) return false;
    return true;
  }

  /// [spirits] narrowed by [matches] and put in [sort] order.
  ///
  /// The input order is taken to be the catalogue order, and ties in any other
  /// sort fall back to it, so the result is the same on every call.
  List<Spirit> apply(List<Spirit> spirits) {
    final List<Spirit> kept = spirits.where(matches).toList();
    if (sort == SpiritSort.catalogue) return kept;

    // Dart's sort is not stable, so ties are broken on the original position.
    final Map<String, int> position = <String, int>{
      for (int i = 0; i < kept.length; i++) kept[i].id: i,
    };
    int byPosition(Spirit a, Spirit b) =>
        position[a.id]!.compareTo(position[b.id]!);

    kept.sort(switch (sort) {
      SpiritSort.catalogue => byPosition,
      SpiritSort.aToZ => (Spirit a, Spirit b) {
        final int byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : byPosition(a, b);
      },
      SpiritSort.strongest => (Spirit a, Spirit b) {
        final double? x = a.abv;
        final double? y = b.abv;
        if (x == null && y == null) return byPosition(a, b);
        if (x == null) return 1;
        if (y == null) return -1;
        final int byAbv = y.compareTo(x);
        return byAbv != 0 ? byAbv : byPosition(a, b);
      },
    });
    return kept;
  }

  /// This filter narrowed to exactly one category — what a tap on the chip row
  /// does. Tapping the only selected category again clears it.
  SpiritFilter withOnlyCategory(SpiritCategory? category) {
    final bool clearing =
        category == null ||
        (categories.length == 1 && categories.contains(category));
    return copyWith(
      categories: clearing
          ? const <SpiritCategory>{}
          : <SpiritCategory>{category},
    );
  }

  SpiritFilter copyWith({
    Set<SpiritCategory>? categories,
    Set<Strength>? strengths,
    bool? storiesOnly,
    SpiritSort? sort,
  }) => SpiritFilter(
    categories: categories ?? this.categories,
    strengths: strengths ?? this.strengths,
    storiesOnly: storiesOnly ?? this.storiesOnly,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => <Object?>[
    categories,
    strengths,
    storiesOnly,
    sort,
  ];
}
