/// Base URLs and keys for the three upstream sources.
///
/// Keys arrive via `--dart-define` so nothing secret or environment-specific is
/// committed. The defaults are the public free tiers, so a plain
/// `flutter run` works with no extra setup.
class ApiSources {
  ApiSources._();

  // --- TheCocktailDB -------------------------------------------------------

  /// Test key `1` caps every *bulk* endpoint at 100 rows. Per-name lookup is
  /// uncapped, which is why the catalogue is hydrated name-by-name from a seed
  /// list. Swap in a premium key to lift the cap without touching code:
  /// `--dart-define=COCKTAILDB_KEY=<key>`.
  static const String cocktailDbKey = String.fromEnvironment(
    'COCKTAILDB_KEY',
    defaultValue: '1',
  );

  static const String cocktailDbBaseUrl =
      'https://www.thecocktaildb.com/api/json/v1/$cocktailDbKey/';

  /// True when running against the capped free tier, so the UI can explain why
  /// a listing looks short instead of silently showing partial data.
  static bool get isCocktailDbFreeTier => cocktailDbKey == '1';

  static const String breweryDbBaseUrl = 'https://api.openbrewerydb.org/v1/';

  /// OpenFoodFacts' terms require a descriptive User-Agent on every request.
  static const String openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v2/';
  static const String openFoodFactsUserAgent =
      'Drinkopedia/1.0 (Flutter; https://github.com/pranjulflows/drinkopedia-clean)';
}

/// Paths on [ApiSources.cocktailDbBaseUrl].
class CocktailDbEndpoints {
  CocktailDbEndpoints._();

  /// Ingredient lookup by name — the source of the origin/production story.
  /// Not subject to the free-tier 100-row cap.
  static const String searchIngredient = 'search.php';

  /// Cocktail lookup by name.
  static const String searchDrink = 'search.php';

  /// Full cocktail record by id.
  static const String lookupDrink = 'lookup.php';

  /// Ingredient record by id.
  static const String lookupIngredient = 'lookup.php';

  /// Cocktails filtered by ingredient/category/glass. **Capped at 100 on the
  /// free tier** — never drive a browse screen from this directly.
  static const String filter = 'filter.php';

  /// Taxonomy lists. Also capped on the free tier.
  static const String list = 'list.php';

  static String ingredientImage(String name, {String size = 'Medium'}) =>
      'https://www.thecocktaildb.com/images/ingredients/'
      '${Uri.encodeComponent(name)}-$size.png';
}
