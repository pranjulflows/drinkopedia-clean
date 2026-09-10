/// A tidy category over TheCocktailDB's untidy `strType`.
///
/// Upstream `strType` is free text and inconsistent: it carries both `Whiskey`
/// and `Whisky`, both `Liqueur` and `Liquor`, both `Fortified wine` and
/// `Fortified Wine`, plus one-off values like `Rice wine`, `Beverage` and a
/// catch-all `Spirit`. Showing those raw is what blocked the taste picker, so
/// this collapses them to a fixed set the UI can actually offer as choices.
///
/// Deliberately conservative: it merges spellings and casing that clearly mean
/// the same thing and does nothing clever. `Spirit` and `Beverage` are genuine
/// catch-alls upstream, so they land in [other] rather than being guessed at.
enum SpiritCategory {
  whiskey,
  rum,
  gin,
  vodka,
  brandy,
  liqueur,
  wine,
  beerAndCider,
  aperitif,
  other;

  /// The category for an upstream `strType`, matched case- and
  /// whitespace-insensitively. Unknown and missing types are [other], never an
  /// error — new values appear upstream without warning.
  static SpiritCategory fromType(String? type) {
    if (type == null) return SpiritCategory.other;
    return _byRawType[type.trim().toLowerCase()] ?? SpiritCategory.other;
  }

  /// The category for a whole spirit, preferring its name over its type.
  ///
  /// A spirit whose own name *is* a category belongs to that category,
  /// whatever upstream typed it. This is not a guess: upstream types "Brandy"
  /// itself as the catch-all `Spirit`, so by type alone a Brandy filter shows
  /// Cognac and Pisco but not Brandy — which reads as a broken filter.
  ///
  /// Only exact category names are honoured, so this cannot drift into
  /// inference: "Sloe Gin" is still a liqueur, as upstream says.
  static SpiritCategory fromSpirit({required String name, String? type}) {
    final SpiritCategory? byName = _byRawType[name.trim().toLowerCase()];
    if (byName != null && byName != SpiritCategory.other) return byName;
    return fromType(type);
  }
}

/// Every raw value observed across the 44-name seed catalogue, lowercased.
const Map<String, SpiritCategory> _byRawType = <String, SpiritCategory>{
  'whiskey': SpiritCategory.whiskey,
  'whisky': SpiritCategory.whiskey,
  'rum': SpiritCategory.rum,
  'gin': SpiritCategory.gin,
  'vodka': SpiritCategory.vodka,
  'brandy': SpiritCategory.brandy,
  'liqueur': SpiritCategory.liqueur,
  'liquor': SpiritCategory.liqueur,
  'wine': SpiritCategory.wine,
  'fortified wine': SpiritCategory.wine,
  'rice wine': SpiritCategory.wine,
  'beer': SpiritCategory.beerAndCider,
  'cider': SpiritCategory.beerAndCider,
  'aperitif': SpiritCategory.aperitif,
  'spirit': SpiritCategory.other,
  'beverage': SpiritCategory.other,
};
