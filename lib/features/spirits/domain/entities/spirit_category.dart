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
