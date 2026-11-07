# Drinkopedia

A reference database for alcohol — what a spirit is, how it's made, and where it came from.

Most drinks apps are recipe lists. This one is built around the **story**: bourbon's
seven-thousand-word history, why absinthe was banned, what actually separates a mezcal from a
tequila. Recipes are the supporting act.

Flutter · Material 3 · offline-first

---

## Status

Early. The architecture and one feature — **browse the catalogue → read a spirit's story** —
are complete and tested end to end. Everything else is scaffolding waiting for a feature to
be built on it.

| | |
|---|---|
| **Working** | Catalogue browse, search, spirit detail with origin story, offline cache, deep links |
| **Scaffolded, not wired** | Open Brewery DB and OpenFoodFacts clients |
| **Not started** | Cocktail recipes, favourites, barcode scanning, producer map |

Verified on every change: `flutter analyze` clean · 39 tests passing · Android debug APK builds.
iOS is configured (deployment target 13.0) but **has never been compiled** — the development
machine has no Xcode or CocoaPods.

## Getting started

Requires Flutter **3.44+** / Dart **3.12+**.

```bash
flutter pub get
dart run build_runner build
flutter run
```

`build_runner` generates the retrofit clients, drift tables, JSON serialisation and typed
routes. Nothing compiles until it has run at least once, and generated files are gitignored
by design — so run it after every clone and after touching a `@RestApi`, `@DriftDatabase`,
`@JsonSerializable` or route class. Use `dart run build_runner watch` while iterating.

> **Note:** `--delete-conflicting-outputs` was removed in build_runner 2.15. Passing it now
> prints a warning and does nothing.

### Running the tests

```bash
flutter analyze && flutter test && dart format --set-exit-if-changed lib test
```

A clean `flutter analyze` — zero issues, not "only infos" — is the bar for done.

## Data

Three free sources. No key is required to run the app.

### TheCocktailDB — the backbone

The only free source carrying real long-form prose on how spirits are made and where they
came from. `search.php?i={name}` returns a `strDescription` running to thousands of words.

**The free key caps every _bulk_ endpoint at 100 rows.** `list.php?i=list` stops
alphabetically at "Kiwi"; `filter.php?i=Gin` returns a single drink. Per-name lookup is
**not** capped.

The app is designed around that: a curated seed list of verified spirit names
(`assets/data/spirits_seed.json`, storied entries first) is hydrated name by name, 20 at a
time as the catalogue scrolls, and cached in SQLite. Browse reads from the cache, never from
a capped endpoint — which also means it works offline and stays off a rate-limited key.

A premium key ($10 one-time, and the only tier licensed for public app-store release) lifts
the cap and unlocks the bulk endpoints. It swaps in with no code change:

```bash
flutter run --dart-define=COCKTAILDB_KEY=your_key
```

**The upstream data is incomplete, and the UI is built to admit it.** ABV is missing for over
half the catalogue, some entries have an empty description (Mezcal), and a few names return
nothing at all. Fields render only when real rather than showing blanks.

### Open Brewery DB · OpenFoodFacts

Configured but not yet wired to a feature. ~11,800 breweries and distilleries with
coordinates (no key), and ~39,500 real alcoholic products with brands, ABV and barcodes
(ODbL; requires a descriptive `User-Agent`).

## Architecture

Clean architecture, three layers per feature, **dependencies pointing inward only**:

```
presentation ──> domain <── data
```

`domain/` is pure Dart — entities, abstract repository interfaces, use cases. No Flutter, no
Dio, no drift, no JSON. `data/` implements those interfaces; `presentation/` renders them.

```
lib/
  app/        root widget, DI composition, theme + motion tokens
  core/       error, network, database, use-case base — feature-agnostic
  shared/     common widgets, animations, dimensions
  routing/    typed routes + NavigationService
  features/<name>/{data,domain,presentation}/
  l10n/       .arb sources (English, French)
```

Adding a feature means creating those three layers under `features/<name>/`, registering it
in `app/di/injector.dart`, and adding routes in `routing/`. Nothing else should need editing.

**Stack:** [provider] for state and DI · [go_router] with `go_router_builder` for typed,
compile-checked routes · [retrofit] over Dio for networking · [drift] for the local cache ·
[dartz] `Either<Failure, T>` at use-case boundaries.

There is deliberately **no GetX**.

### Notes worth knowing

**Networking is retrofit, never hand-rolled Dio.** One `@RestApi` class per upstream source;
paths and query names are declared once, so a typo is a build error rather than a runtime
404. `DioException` is translated into a domain `Failure` in exactly one place
(`core/error/error_mapper.dart`) — nothing above the data layer sees a Dio type.

**Caching is cache-first with a stale fallback.** A failed refresh serves the last good data
rather than an error screen; the error only surfaces when the cache is empty too.

**`{"drinks": null}` is an empty result, not an error.** TheCocktailDB signals a miss that way
instead of returning 404. It is modelled explicitly, and there is a test pinning the
behaviour.

**Deep links must work without `$extra`.** Tapping a card passes the loaded entity through
`$extra` so the hero transition paints instantly — but `$extra` never survives a link, a
restart, or a process death. Every route resolves from its path alone, and a test opens
`/spirits/:id` cold to prove it.

**Motion respects accessibility.** Durations and curves are tokens in
`app/theme/app_motion.dart`, and every animation honours `MediaQuery.disableAnimations`.
Animation is decoration here; it is never required to understand or operate a screen.

## Contributing

Read [CLAUDE.md](CLAUDE.md) first — it carries the conventions, the API caps, and the
non-obvious version pins in more detail than this file. `AGENTS.md` is a symlink to it.

[provider]: https://pub.dev/packages/provider
[go_router]: https://pub.dev/packages/go_router
[retrofit]: https://pub.dev/packages/retrofit
[drift]: https://pub.dev/packages/drift
[dartz]: https://pub.dev/packages/dartz
