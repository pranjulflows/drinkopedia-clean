# Drinkopedia

A reference database for alcohol: what a spirit is, how it is made, and where it came
from. The **origin story is the product**, not a detail field — treat it as the primary
content when designing screens.

Flutter 3.44+ / Dart 3.12+. State via **provider**, routing via **go_router**, networking
via **retrofit** (over Dio), local cache via **drift**. There is deliberately **no GetX** —
do not reintroduce `package:get`.

## Commands

```bash
flutter pub get
dart run build_runner build      # drift + go_router codegen. NO --delete-conflicting-outputs (removed in build_runner 2.15)
dart run build_runner watch      # while iterating on generated code
flutter analyze                  # must be clean — zero issues, not "only infos"
flutter test
dart format lib test
flutter build apk --debug        # run after touching pubspec or anything native
```

Generated files (`*.g.dart` — retrofit clients, drift tables, json_serializable DTOs,
typed routes — plus `lib/l10n/app_localizations*.dart`) are gitignored and recreated by the
commands above. Never hand-edit them.

`build_runner` is pinned to `^2.15.1`: 2.16+ requires `analyzer >=13.3.0`, which wants
`meta ^1.18.3`, and the Flutter SDK pins `meta 1.18.0`. The same ceiling holds
`retrofit_generator` at 10.2.9.

## Architecture

Clean architecture, three layers per feature. **Dependencies point inward only:**

```
presentation ──> domain <── data
```

- `domain/` — entities + **abstract** repository interfaces + use cases. Pure Dart: no
  Flutter, no Dio, no drift, no JSON. If you `import 'package:flutter/...'` here, it is wrong.
- `data/` — DTOs (own the JSON), retrofit API clients, datasources, drift tables/DAOs, and
  the repository *implementations* of the domain interfaces.
- `presentation/` — `ChangeNotifier` providers exposing a sealed view-state, plus screens
  and widgets. Widgets never call a datasource or a use case directly.

```
lib/
  app/          # root widget, DI composition, theme
  core/         # error, network, database, usecase base, utils — feature-agnostic
  shared/       # common UI widgets, animations, dimensions, formatters
  routing/      # typed routes + NavigationService
  features/<name>/{data,domain,presentation}/
  l10n/         # *.arb sources; the .dart files are generated
```

**Adding a feature:** create the three layers under `features/<name>/`, register the
repository and providers in `app/di/injector.dart`, add typed routes in `routing/`.
Nothing else should need editing.

**SOLID in practice:** a new data source is a *new* implementation behind an existing
interface, never an edit to the old one. Features depend on narrow repository interfaces —
never on `Dio` or `AppDatabase` directly.

## Networking — retrofit

HTTP goes through **retrofit** (`@RestApi` + generated client), never hand-rolled Dio calls.
Paths, query names and response types are declared once on the abstract class, so a typo is
a build error rather than a 404 at runtime.

```dart
@RestApi()
abstract class CocktailDbApi {
  factory CocktailDbApi(Dio dio, {String? baseUrl}) = _CocktailDbApi;

  @GET(CocktailDbEndpoints.searchIngredient)
  Future<IngredientResponse> searchIngredient(@Query('i') String name);
}
```

Rules:

- **One `@RestApi` class per upstream source**, in that feature's `data/datasources/`.
  Add an endpoint by adding a method, then re-running codegen.
- **One `Dio` per source**, built by `DioFactory.create` — sources differ in base URL and
  required headers, and a shared instance would leak one source's headers into another.
- Retrofit classes only know the wire protocol. Application policy (the seed-list
  hydration, request batching, cache decisions) belongs in the data source or repository
  above it — see `CocktailDbApi` vs `CocktailDbSpiritDataSource`.
- **Responses are typed**, never `Map<String, dynamic>` at the call site. Model the
  envelope explicitly (`IngredientResponse`) so a null collection is an empty result.
- Upstream sloppiness is absorbed by converters in `core/network/json_converters.dart` —
  `LooseString` (JSON null vs `"null"` vs `""`) and `LooseDouble` (`"strABV": "40"`). Use
  them rather than re-checking in every consumer.
- `DioException` is translated to a `Failure` in `core/error/error_mapper.dart`, the only
  place allowed to know about Dio. Nothing above the data layer sees a Dio type.

## Data sources

All three are free. Keys come from `--dart-define`, never hardcoded.

### TheCocktailDB — `https://www.thecocktaildb.com/api/json/v1/{key}/`

The backbone, and the only free source with the origin/production prose this app exists to
show (`strDescription` on ingredients — Bourbon is ~7,000 characters).

**The free key `1` caps every *bulk* endpoint at 100 items.** `list.php?i=list` stops
alphabetically at "Kiwi"; `filter.php?i=Gin` returns a single drink. **Per-name lookup is
NOT capped** — `search.php?i=Bourbon` works fine.

So: browse reads from the **drift cache**, hydrated from a curated seed list via
`search.php?i={name}`. Never build a browse screen on a bulk endpoint. Premium is $10
one-time and is also the only tier licensed for public store release.

**Fields are unreliable.** `strABV` is null more often than not, `strDescription` is empty
for some entries (Mezcal), and some names return nothing at all (Grappa, Soju). Every
field is nullable; the UI degrades instead of rendering blanks.

Response shape is a bare `{"drinks": [...]}` — and **`{"drinks": null}` means "no results",
not an error.** Map it to an empty list.

### Open Brewery DB — `https://api.openbrewerydb.org/v1/`

No key. ~11,800 breweries/distilleries with type, country, website and coordinates.

### OpenFoodFacts — `https://world.openfoodfacts.org/api/v2/`

No key, ODbL licensed. ~39,500 products tagged `alcoholic-beverages` with brand, ABV and
barcode. **Requires a descriptive `User-Agent` header** — their terms mandate it.

## UI

Material 3, seeded from `lightColorPalette.primarySwatch`, light **and** dark. The Rota
font family is registered across nine weights.

This app is about drinks and their stories, so motion matters: hero transitions on imagery,
collapsing app bars over long-form story text, staggered list entry, shimmer skeletons
rather than spinners. Motion tokens live in `app/theme/app_motion.dart` — use them instead
of literal durations.

**Always honour `MediaQuery.disableAnimations`.** Animation is decoration; it must never be
required to understand or operate a screen.

## Conventions

- `flutter analyze` clean is the bar for "done". Not "only infos left".
- Package imports (`package:drinkopedia/...`), not relative ones.
- User-facing copy goes in `lib/l10n/*.arb` and is read via `AppLocalizations.of(context)`.
  `StringsResources` is **only** for API wire values (`SUCCESS`/`FAIL`) that must never be
  translated.
- Entities are immutable and `Equatable`.
- Widget tests that touch drift must drive the mount inside `WidgetTester.runAsync`. Drift
  performs real asynchronous I/O, which never advances under the tester's fake clock, and
  `pumpAndSettle` cannot be used at all while a shimmer skeleton is repeating. See
  `test/app_test.dart`.
- `$extra` on a route is an optimisation only. Every route must resolve from its path
  alone — `$extra` does not survive a deep link or process death.
