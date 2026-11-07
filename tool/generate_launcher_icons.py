"""Draws the app's launcher icons for Android and iOS from the bottle mark.

Replaces Flutter's default logo. The mark comes from `brand_mark.py`, the same
one on the Play Store icon, because Play expects the store listing's icon and
the installed app's icon to match.

What it writes:

  Android, android/app/src/main/res/
    mipmap-*/ic_launcher.png             48dp  legacy square, API 24-25
    mipmap-*/ic_launcher_foreground.png  108dp adaptive foreground, API 26+
    mipmap-*/ic_launcher_monochrome.png  108dp themed icons, API 33+
    mipmap-anydpi-v26/ic_launcher.xml    ties the three together
    values/ic_launcher_background.xml    the acid ground, as a colour

  iOS, ios/Runner/Assets.xcassets/AppIcon.appiconset/
    every size listed in that catalogue's own Contents.json

Run from anywhere (macOS, needs Google Chrome):

    python3 tool/generate_launcher_icons.py
"""

from __future__ import annotations

import json
import math
import pathlib

from brand_mark import (
    ACID,
    CANVAS,
    FONT_CSS,
    MARK_BBOX,
    ROOT,
    mark_silhouette_svg,
    mark_svg,
    render,
)

ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_ICONS = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

#: Android's density buckets, as multiples of mdpi.
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

LEGACY_DP = 48
ADAPTIVE_DP = 108

#: The only part of the 108dp adaptive canvas every launcher must show.
#:
#: Of the foreground, the outer 18dp a side is reserved for masking, leaving
#: 72dp — and a round mask then cuts the corners off that, so only the inner
#: 66dp circle is guaranteed. The mark is a tall, narrow bottle whose own
#: corners fall outside that circle when it is fitted to the 72dp square, so
#: it is fitted by its bounding *circle* instead. Nothing is ever clipped,
#: at the cost of a slightly smaller bottle than the full-bleed store icon.
SAFE_CIRCLE_DP = 66


def page(body: str, width: int, height: int, *, ground: str | None) -> str:
    """A bare page holding one SVG, sized so the screenshot is the artwork."""
    background = f"background:{ground};" if ground else ""
    return f"""<!doctype html><meta charset="utf-8"><style>{FONT_CSS}
*{{box-sizing:border-box;margin:0;padding:0}}
html,body{{overflow:hidden}}
body{{width:{width}px;height:{height}px;{background}}}</style>
<body>{body}</body>"""


def fitted_mark_svg(size: int, *, silhouette: bool = False) -> str:
    """The mark centred on the adaptive canvas, inside the guaranteed circle."""
    left, top, right, bottom = MARK_BBOX
    # Adaptive-canvas units per 512-space unit, set so the circle that
    # encloses the mark is exactly SAFE_CIRCLE_DP across.
    scale = SAFE_CIRCLE_DP / math.hypot(right - left, bottom - top)
    centre = ADAPTIVE_DP / 2
    dx = centre - (left + right) / 2 * scale
    dy = centre - (top + bottom) / 2 * scale

    inner = mark_silhouette_svg(CANVAS) if silhouette else mark_svg(CANVAS, ground=None)
    # Keep only the drawing, then re-place it in the adaptive canvas.
    inner = inner[inner.index(">", inner.index("<svg")) + 1 : inner.rindex("</svg>")]
    return f"""
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {ADAPTIVE_DP} {ADAPTIVE_DP}"
     width="{size}" height="{size}">
  <g transform="translate({dx:.4f} {dy:.4f}) scale({scale:.6f})">{inner}</g>
</svg>"""


def write_android() -> list[pathlib.Path]:
    written: list[pathlib.Path] = []
    for bucket, factor in DENSITIES.items():
        folder = ANDROID_RES / f"mipmap-{bucket}"

        legacy = round(LEGACY_DP * factor)
        target = folder / "ic_launcher.png"
        render(target, page(mark_svg(legacy, ground=ACID), legacy, legacy, ground=ACID), legacy, legacy)
        written.append(target)

        adaptive = round(ADAPTIVE_DP * factor)
        for name, silhouette in (
            ("ic_launcher_foreground.png", False),
            ("ic_launcher_monochrome.png", True),
        ):
            target = folder / name
            render(
                target,
                page(fitted_mark_svg(adaptive, silhouette=silhouette), adaptive, adaptive, ground=None),
                adaptive,
                adaptive,
                transparent=True,
            )
            written.append(target)

    anydpi = ANDROID_RES / "mipmap-anydpi-v26" / "ic_launcher.xml"
    anydpi.parent.mkdir(parents=True, exist_ok=True)
    anydpi.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        "</adaptive-icon>\n"
    )
    written.append(anydpi)

    colour = ANDROID_RES / "values" / "ic_launcher_background.xml"
    colour.parent.mkdir(parents=True, exist_ok=True)
    colour.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{ACID}</color>\n'
        "</resources>\n"
    )
    written.append(colour)
    return written


def write_ios() -> list[pathlib.Path]:
    """Every size the catalogue asks for, read from the catalogue itself.

    Opaque on purpose: iOS rejects an app icon with an alpha channel, and
    Chrome writes a screenshot without one unless asked otherwise.
    """
    manifest = json.loads((IOS_ICONS / "Contents.json").read_text())
    sizes: dict[str, int] = {}
    for image in manifest["images"]:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        sizes[image["filename"]] = round(points * scale)

    written: list[pathlib.Path] = []
    for filename, size in sorted(sizes.items()):
        target = IOS_ICONS / filename
        render(target, page(mark_svg(size, ground=ACID), size, size, ground=ACID), size, size)
        written.append(target)
    return written


def main() -> None:
    for path in write_android() + write_ios():
        print(path.relative_to(ROOT))


if __name__ == "__main__":
    main()
