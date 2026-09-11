# Play Console graphics

Store listing assets for Google Play, in the neo-brutalist pop direction the app
itself uses (see `docs/design-directions.md`). Each file is already at the exact
size Play Console asks for, so upload them as they are.

| File | Play Console slot | Spec |
|---|---|---|
| `icon-512.png` | App icon | 512 × 512, 32-bit PNG, full-bleed square — Play rounds the corners itself |
| `feature-graphic-1024x500.png` | Feature graphic | 1024 × 500, 24-bit PNG, no alpha |
| `phone-screenshots/01…06.png` | Phone screenshots | 1080 × 1920 (9:16), 24-bit PNG, no alpha |

Upload the screenshots in file order. The first two are the ones most people see
without scrolling, so they lead with the catalogue and an origin story.

1. `01-catalogue` — 145 spirits on one shelf
2. `02-origin-story` — read the origin story (Bourbon)
3. `03-filter` — filter by what you drink (Whiskey)
4. `04-taste` — pick your vibe (the taste intro)
5. `05-search` — find any spirit, fast
6. `06-dark-mode` — looks good in the dark (Amaretto)

1080 px on the short side keeps the screenshots eligible for Play's larger
promotional placements, which need at least that.

## Rebuilding

```bash
python3 store/play/source/generate.py
```

macOS with Google Chrome; nothing else to install. The script draws every asset
from HTML with headless Chrome, using the app's own Rota fonts from
`assets/fonts` and its colour tokens from `app_colors.dart`.

The screens in `source/raw/` are captures from the iOS simulator. The app draws
identical UI on Android — the back arrow and page transitions are set
explicitly, not left to the platform — and the top of each capture, which holds
the iOS status bar and Dynamic Island, is cropped off so no other platform's
chrome appears in a Play listing. To refresh a screen, capture it at
1206 × 2622 (iPhone 17 Pro) under the same name and rerun the script.

The copy makes only claims the app backs up. Revisit the "145 spirits" lines
whenever `assets/data/spirits_seed.json` changes size.
