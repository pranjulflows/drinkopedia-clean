# Design directions

Status as of 2026-09-09.

Four Gen-Z visual directions were mocked for Drinkopedia. **Direction A — Neo-brutalist
pop is the one to build.** B, C and D are kept here in enough detail to revive without
redoing the exploration.

Canvas with all four, four screens each:
**https://claude.ai/code/artifact/9fd43fa3-588b-4a53-bff3-b617cc4ad7bb**

Columns are the directions, rows are style tile → onboarding → catalogue → story. Every
column uses the same spirits and the same real API prose, so the comparison isolates
style. Set in real Rota, subset from `assets/fonts/`. Static mockups — nothing is
clickable.

---

## Constraints that bind every direction

These come from the data, not from taste. They are why none of the four looks like a
typical photo-led drinks app. Full survey in
`memory/drinkopedia-catalogue-data-shape.md`.

- **Imagery is transparent-background bottle cutouts** from
  `CocktailDbEndpoints.ingredientImage()` — 35–105 KB PNGs, no photography. The cutout is
  an object placed on a designed ground; there is nothing to bleed full width.
- **Only 20 of 44 spirits have an ABV.** Bourbon, Absinthe, Sake, Kahlua, Scotch, Cognac,
  Vermouth and 17 others return null. Render the chip only when non-null — never a
  placeholder or a dash.
- **`type` is unnormalised upstream text**: `Whiskey` and `Whisky`, `Fortified wine` and
  `Fortified Wine`, plus `Liquor`, `Beverage`, `Rice wine`, and a catch-all `Spirit`.
  Anything that groups or filters by category needs a normalisation map first.
- **`story` is raw prose** — up to ~7,000 chars, `\r\n\r\n` breaks, Wikipedia footnote
  markers left in (visible on Absinthe). Pull-quotes or chaptering mean parsing it.
- Available fields are exactly `id`, `name`, `type?`, `abv?`, `story?`, `imageUrl?`,
  `isAlcoholic`, plus the currently-unused `Spirit.storyExcerpt` getter
  (`lib/features/spirits/domain/entities/spirit.dart`).

---

## Direction A — Neo-brutalist pop  ·  BUILD THIS

Hard black borders, offset shadows, flat acid colour. Rota ExtraBlack set large and
uppercase. Loud enough to survive a feed, and the missing-ABV gaps stop reading as holes
because the layout is blocky rather than tabular.

Known tradeoff: hard borders and flat blocks make 7,000 characters of story a slog. The
story screen deliberately drops the borders and widens the measure to compensate — keep
that when building.

### Colour

| Role | Hex | Use |
|---|---|---|
| Ink | `#0A0A0A` | All text, all borders, all shadows |
| Paper | `#F5F1E8` | Screen background |
| Card | `#FFFFFF` | Card and field fill |
| Acid | `#CCFF00` | Accent 1 — image wells, CTA label |
| Hot pink | `#FF4FD8` | Accent 2 — image wells, CTA shadow |
| Electric blue | `#2B6BFF` | Accent 3 — image wells |
| Skeleton | `#E4DFD2` | Loading blocks |
| Muted ink | `#5A564D` | Secondary/caption text on paper |

Accents rotate across the grid by index — `index % 3` → acid, pink, blue — so no two
adjacent image wells match.

**Do not use `ColorScheme.fromSeed` for this.** Tonal derivation flattens `#CCFF00` into a
muddy olive. Author the `ColorScheme` explicitly. `outline` is `#0A0A0A` at full strength,
not a tint — every border in this direction is ink.

### Type

All display and card names use the **`Rota ExtraBlack` family**, not a weight. Sizes are
logical px, which map 1:1 to the mock because `DrinkopediaApp.designSize` is
`Size(375, 812)`.

| Token | Family | Size | Height | Tracking | Case |
|---|---|---|---|---|---|
| Screen title | Rota ExtraBlack | 42 | 0.86 | −0.04em | UPPER |
| Hero name | Rota ExtraBlack | 46 | 0.86 | −0.045em | UPPER |
| Section head | Rota ExtraBlack | 20 | 1.0 | −0.02em | UPPER |
| Card name | Rota ExtraBlack | 16 | 1.0 | −0.025em | UPPER |
| Body | Rota 400 | 15 | 1.62 | 0 | sentence |
| Meta label | Rota 600 | 11 | 1.0 | 0.14em | UPPER |
| Chip label | Rota 600 | 9–10 | 1.0 | 0.08–0.12em | UPPER |

### Components

- **Card** — fill `#FFFFFF`, radius **0**, border 3px ink, hard shadow `offset(5, 5)`
  with `blurRadius: 0`. Image well 128 high on a rotating accent, separated by a 3px ink
  bottom border. Text block padded `9, 10, 11`.
- **Chip** — radius 0, border 2px ink, padding `2` vertical / `5` horizontal. The ABV chip
  inverts: fill ink, label acid. Type chip stays outline-only.
- **Search field** — height 48, border 3px, shadow `offset(4, 4)`, fill white, hint
  `#6A655B`.
- **Primary button** — height 56, border 3px, fill ink, label acid, shadow `offset(5, 5)`
  in **hot pink** (the one place the shadow is not ink).
- **Icon button** — 46×46, border 3px, accent fill, shadow `offset(3, 3)`. Meets the 44px
  minimum target.
- **Skeleton** — identical footprint to the card, `#E4DFD2` blocks. Reuse the existing
  1100 ms controller in `spirit_card_skeleton.dart` unchanged; only the colours move.

### Motion

Hard cuts, not fades. Cards translate in on the existing 45 ms stagger with the **fade
removed** — the borders make an opacity ramp look like a rendering bug. Hero image jumps
scale on tap rather than easing. Everything still collapses under
`MediaQuery.disableAnimations`; keep `AppMotion.reduced(context)` on every path.

### Screen notes

- **Catalogue** — `Drinkopedia` set over two lines at 42/0.86 rather than a
  `SliverAppBar.large` title. Refresh becomes an accent icon button top-right. A meta row
  under the search field carries `44 SPIRITS` and the sort state.
- **Story** — 300-high hero, cutout centred on flat acid with a 4px ink bottom border, no
  scrim and no gradient. Name at 46 below the hero, not inside it, so it never collides
  with the image. Type chip only; when `abv` is null nothing is drawn in its place. `THE
  STORY` heading with a 4px ink rule running to the right edge. Body drops to a single
  measure with no card around it.
- **Onboarding** — new, see below.

---

## What this means in the code

Nothing here has been implemented yet. Files that will move:

- **`lib/app/theme/app_theme.dart`** — replace `ColorScheme.fromSeed(...)` with an
  explicit `ColorScheme`. Set `cardTheme` radius to 0 with a 3px `BorderSide`, and
  `chipTheme` radius 8 → 0.
- **`lib/app/theme/app_color_palette.dart`** — the current `primarySwatch` is
  `MaterialColor(800, {...})`: the shade *key* was passed where the primary ARGB int
  belongs, so the app is seeded from `0x00000320`, a near-black blue, not the brand navy
  `#2F3462`. Moving to an explicit `ColorScheme` sidesteps this, but the dead swatch and
  the equally dead `lightTextTheme` (zero references anywhere) should go at the same time
  rather than being left to confuse the next reader.
- **`lib/core/constants/app_constants.dart`** — add
  `static const String rotaExtraBlack = "Rota ExtraBlack";` next to `rota`. Flutter caps
  weights at 900 and Rota ExtraBlack is heavier, so `pubspec.yaml` registers it as its own
  family with no weight. Setting `fontWeight` on it does nothing — select it by family.
- **`spirit_card.dart` / `spirit_card_skeleton.dart`** — restyle in place; the skeleton
  already mirrors the card's shape, so keep them in step.
- **`spirits_screen.dart` / `spirit_detail_screen.dart`** — restyle. `_MessageSliver` and
  `_DetailError` are currently private to their screens; the empty, error and no-match
  states all need the new treatment, so extracting them is worthwhile now.
- **`lib/shared/animations/staggered_entrance.dart`** — add a translate-only mode for the
  fade-less entrance.
- **`lib/l10n/app_en.arb` + `app_fr.arb`** — new keys for the onboarding copy. Existing
  keys (`catalogueTitle`, `searchSpirits`, `theStory`, `abvValue`, `nothingHere`, `retry`)
  are reused as-is; the mocks use their real values.

Unrelated but adjacent: `lib/shared/widgets/**` is Looch-era template code with zero
references from any screen. It will conflict visually with anything built here. Worth
deleting in the same pass.

---

## Onboarding — the one new screen

A three-step taste intro; step 2 is the only one with substance and is the step drawn on
the canvas. It sets a local preference used to order the catalogue.

- **No account, no backend, no new API.** Persistence is local only.
- `shared_preferences` is not a dependency. Use **drift** — a single-row settings table
  alongside `spirits_table.dart` — rather than adding a package or misusing
  `flutter_secure_storage`, which is for secrets.
- The chips are the **raw `strType` values**. Presenting `Rice wine`, `Liquor` and a
  catch-all `Spirit` beside `Whiskey` is not shippable — this screen is blocked on the
  category normalisation noted above. Build the normalisation map first.
- Needs a `GoRoute` in `lib/routing/` and a first-run check before the catalogue redirect.

---

## Parked directions

Not chosen, kept for a change of mind. Each is fully drawn on the canvas.

### B — Neon nightlife

Dark-native. Ground `#0B0B0F`, text `#EDEBFF`, a `#7B5CFF → #FF3D9A` gradient for CTAs,
`#00E5D0` for accents and ABV. Glassmorphic cards: radius 24, fill white at 4.5%, 1px
white-10% border, plus a low-opacity grain overlay. A coloured radial glow sits behind
each cutout, hue derived per spirit, doing the work photography would.

Strongest case: long story text is genuinely comfortable on dark, and it reads premium
rather than juvenile. Main cost: it is dark-native, so it needs a light counterpart
designed or the theme pinned to dark.

### C — Editorial zine

Paper `#F2EDE3`, ink `#16150F`, riso spots `#FF5A3D` / `#2F5AE8` / `#0E7C5A`. No card
container at all — a flat colour block behind a duotone-tinted cutout, with the name set
beneath as a caption. Catalogue is asymmetric: one large feature entry using
`Spirit.storyExcerpt` over a two-column grid. Story screen uses a drop cap and a 1.72
measure.

Leans hardest into "the origin story is the product" and is the best of the four to read.
Main cost: the quietest in a screenshot — it wins on the second screen, not the first.

### D — Soft candy

Ground `#FFF6FB`, text `#3A2E44`, pastel wells `#FFB3D9` / `#B8E4FF` / `#D9C2FF`, accent
`#C0538F`. Rota SemiBold, lowercase throughout, radius 28–32, soft shadows, subtle radial
mesh. Cards pick their well tint from the spirit's name.

The least intimidating way into a subject people are often unsure about. Main cost: the
pastel ground fights the cutouts, which are mostly dark glass, and it reads younger than
the subject.

---

## Open decisions

1. **Dark mode.** `app.dart` passes both `AppTheme.light()` and `AppTheme.dark()` and
   never sets `themeMode`, so the app follows the OS with no in-app toggle. Direction A is
   light-native and has no dark counterpart designed yet. Either draw one, or pin
   `themeMode` — currently neither has been decided.
2. **Category normalisation.** Blocks onboarding, and any future filtering or grouping.
3. **Story typography at length.** The mock shows the first two paragraphs. Bourbon runs
   to ~7,000 characters; the direction has not been tested at full length.
