"""The Drinkopedia bottle mark, and the headless-Chrome renderer that draws it.

One definition, used by both the launcher icons (`generate_launcher_icons.py`)
and the Play Console graphics (`store/play/source/generate.py`). Play expects
the store icon and the installed app's icon to be the same mark, so they must
not be able to drift apart.

macOS, and needs Google Chrome. Nothing outside the standard library.
"""

from __future__ import annotations

import base64
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
FONTS = ROOT / "assets" / "fonts"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# The direction's palette, matching lib/app/theme/app_colors.dart.
INK, PAPER, ACID, PINK, BLUE = "#0A0A0A", "#F5F1E8", "#CCFF00", "#FF4FD8", "#2B6BFF"

#: The mark is drawn in a 512-unit square.
CANVAS = 512

#: Ink extent of the mark inside [CANVAS]: (left, top, right, bottom).
#:
#: Measured from the paths below including the 14-unit stroke and the offset
#: shadow, so callers can centre and scale the mark without guessing. Android's
#: adaptive foreground relies on this to keep the whole bottle inside the safe
#: zone its launcher may crop to.
MARK_BBOX = (143, 45, 383, 477)

_BOTTLE = (
    "M222 58 h68 a10 10 0 0 1 10 10 v44 h-88 v-44 a10 10 0 0 1 10 -10 z"
    " M214 112 h84 v58 c0 18 60 34 60 88 v168 a28 28 0 0 1 -28 28"
    " h-148 a28 28 0 0 1 -28 -28 v-168 c0 -54 60 -70 60 -88 z"
)


def font_face(family: str, file: str) -> str:
    """An `@font-face` rule with the font embedded, since the page is a file."""
    data = base64.b64encode((FONTS / file).read_bytes()).decode()
    return (
        f"@font-face{{font-family:'{family}';"
        f"src:url(data:font/otf;base64,{data}) format('opentype');}}"
    )


FONT_CSS = "".join(
    font_face(family, file)
    for family, file in (
        ("Rota ExtraBlack", "Rota-ExtraBlack.otf"),
        ("Rota SemiBold", "Rota-SemiBold.otf"),
        ("Rota Medium", "Rota-Medium.otf"),
    )
)


def mark_group(
    *,
    label: str = PINK,
    body: str = PAPER,
    shadow: str = INK,
    stroke: str = INK,
) -> str:
    """The mark itself, in 512-unit space, ready to drop inside an `<svg>`.

    A chunky bottle in the app's card language: paper fill, heavy ink border,
    hard offset shadow, a sticker label carrying the D.
    """
    return f"""<g transform="translate(-4 -6)">
    <path d="{_BOTTLE}" transform="translate(22 22)" fill="{shadow}"/>
    <path d="{_BOTTLE}" fill="{body}" stroke="{stroke}" stroke-width="14" stroke-linejoin="round"/>
    <rect x="178" y="262" width="156" height="148" fill="{label}" stroke="{stroke}" stroke-width="12"/>
    <text x="257" y="383" text-anchor="middle" fill="{INK}" stroke="{INK}"
      stroke-width="6" stroke-linejoin="round"
      style="font-family:'Rota ExtraBlack';font-size:136px">D</text>
    <rect x="222" y="112" width="68" height="14" fill="{stroke}"/>
  </g>"""


def mark_svg(size: int, *, ground: str | None, **colours: str) -> str:
    """The mark as a standalone square SVG, optionally on a solid [ground]."""
    ground_rect = (
        f'<rect width="{CANVAS}" height="{CANVAS}" fill="{ground}"/>' if ground else ""
    )
    return f"""
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CANVAS} {CANVAS}" width="{size}" height="{size}">
  {ground_rect}
  {mark_group(**colours)}
</svg>"""


def mark_silhouette_svg(size: int, *, fill: str = INK) -> str:
    """The mark as one flat shape on transparency, for Android's themed icons.

    A monochrome drawable carries no colour of its own — the launcher tints it —
    so the label cannot be a pink rectangle. It is punched out of the bottle
    instead, which keeps the D readable as a hole rather than as a fill.
    """
    return f"""
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CANVAS} {CANVAS}" width="{size}" height="{size}">
  <mask id="mark" maskUnits="userSpaceOnUse" x="0" y="0" width="{CANVAS}" height="{CANVAS}">
    <rect width="{CANVAS}" height="{CANVAS}" fill="black"/>
    <g transform="translate(-4 -6)">
      <path d="{_BOTTLE}" fill="white" stroke="white" stroke-width="14" stroke-linejoin="round"/>
      <rect x="178" y="262" width="156" height="148" fill="black"/>
      <text x="257" y="383" text-anchor="middle" fill="white" stroke="white"
        stroke-width="6" stroke-linejoin="round"
        style="font-family:'Rota ExtraBlack';font-size:136px">D</text>
      <rect x="222" y="112" width="68" height="14" fill="white"/>
    </g>
  </mask>
  <rect width="{CANVAS}" height="{CANVAS}" fill="{fill}" mask="url(#mark)"/>
</svg>"""


def render(
    target: pathlib.Path,
    html: str,
    width: int,
    height: int,
    *,
    transparent: bool = False,
) -> None:
    """Screenshots [html] at exactly [width] x [height] into [target].

    The page embeds its fonts as base64, so it is written to a scratch
    directory and never lands beside the output it produces.
    """
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as scratch:
        page = pathlib.Path(scratch) / "page.html"
        page.write_text(html)
        args = [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            f"--window-size={width},{height}",
            "--virtual-time-budget=3000",
            "--allow-file-access-from-files",
            f"--screenshot={target}",
        ]
        if transparent:
            args.append("--default-background-color=00000000")
        subprocess.run([*args, page.as_uri()], check=True, capture_output=True)
