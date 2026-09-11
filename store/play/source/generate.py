"""Renders Drinkopedia's Play Console graphics from HTML with headless Chrome.

Every asset is drawn at exactly the size Play Console asks for, so nothing is
resampled on upload:

  icon            512 x 512    32-bit PNG (alpha), full-bleed square
  feature graphic 1024 x 500   24-bit PNG, no alpha
  phone shots     1080 x 1920  24-bit PNG, no alpha, 9:16

Raw screens are simulator captures (1206 x 2622). The top 160 px carry the
iOS status bar and Dynamic Island, and are cropped off: the app draws the same
UI on Android, and a Play listing must not show another platform's chrome.

Run from anywhere (macOS, needs Google Chrome):

    python3 store/play/source/generate.py
"""

from __future__ import annotations

import base64
import pathlib
import struct
import subprocess
import tempfile
import zlib

HERE = pathlib.Path(__file__).resolve().parent
RAW = HERE / "raw"
OUT = HERE.parent
SHOTS_DIR = OUT / "phone-screenshots"
FONTS = HERE.parents[2] / "assets" / "fonts"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

INK, PAPER, ACID, PINK, BLUE = "#0A0A0A", "#F5F1E8", "#CCFF00", "#FF4FD8", "#2B6BFF"

RAW_W = 1206
STATUS_BAR_PX = 160


def font_face(family: str, file: str) -> str:
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

BASE_CSS = f"""
{FONT_CSS}
*{{box-sizing:border-box;margin:0;padding:0}}
html,body{{overflow:hidden}}
.display{{font-family:'Rota ExtraBlack',sans-serif;text-transform:uppercase;
  line-height:.86;letter-spacing:-.045em}}
.body{{font-family:'Rota Medium',sans-serif}}
.label{{font-family:'Rota SemiBold',sans-serif;text-transform:uppercase;
  letter-spacing:.08em}}
"""


# --- the bottle mark, shared by the icon and the feature graphic -------------

def bottle_svg(size: int, *, ground: str | None, label: str = PINK,
               body: str = PAPER, shadow: str = INK, stroke: str = INK) -> str:
    """A chunky bottle in the app's card language: paper fill, heavy ink
    border, hard offset shadow, a sticker label carrying the D."""
    ground_rect = f'<rect width="512" height="512" fill="{ground}"/>' if ground else ""
    bottle = (
        "M222 58 h68 a10 10 0 0 1 10 10 v44 h-88 v-44 a10 10 0 0 1 10 -10 z"
        " M214 112 h84 v58 c0 18 60 34 60 88 v168 a28 28 0 0 1 -28 28"
        " h-148 a28 28 0 0 1 -28 -28 v-168 c0 -54 60 -70 60 -88 z"
    )
    return f"""
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="{size}" height="{size}">
  {ground_rect}
  <g transform="translate(-4 -6)">
    <path d="{bottle}" transform="translate(22 22)" fill="{shadow}"/>
    <path d="{bottle}" fill="{body}" stroke="{stroke}" stroke-width="14" stroke-linejoin="round"/>
    <rect x="178" y="262" width="156" height="148" fill="{label}" stroke="{stroke}" stroke-width="12"/>
    <text x="257" y="383" text-anchor="middle" fill="{INK}" stroke="{INK}"
      stroke-width="6" stroke-linejoin="round"
      style="font-family:'Rota ExtraBlack';font-size:136px">D</text>
    <rect x="222" y="112" width="68" height="14" fill="{stroke}"/>
  </g>
</svg>"""


def icon_html() -> str:
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body{{width:512px;height:512px;background:{ACID}}}</style>
<body>{bottle_svg(512, ground=ACID)}</body>"""


# --- feature graphic ----------------------------------------------------------

def chip(text: str, bg: str, fg: str = INK, *, rot: float = 0, x: int, y: int,
         size: int = 22) -> str:
    return (
        f'<div class="label chip" style="left:{x}px;top:{y}px;background:{bg};'
        f'color:{fg};transform:rotate({rot}deg);font-size:{size}px">{text}</div>'
    )


def feature_html() -> str:
    chips = "".join((
        chip("Whiskey", PAPER, rot=-6, x=596, y=58),
        chip("Gin", BLUE, PAPER, rot=5, x=906, y=64),
        chip("Liqueur", PAPER, rot=-4, x=872, y=388),
        chip("Tequila &amp; mezcal", PINK, rot=3, x=560, y=404),
    ))
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body{{width:1024px;height:500px;background:{ACID};position:relative}}
.copy{{position:absolute;left:64px;top:0;bottom:0;display:flex;
  flex-direction:column;justify-content:center}}
.eyebrow{{font-size:20px;color:{INK}}}
.word{{margin-top:18px;font-size:96px;color:{INK}}}
.tag{{margin-top:22px;font-size:34px;line-height:1.25;color:{INK}}}
.bottle{{position:absolute;left:626px;top:30px;transform:rotate(7deg)}}
.chip{{position:absolute;padding:11px 18px;border:5px solid {INK};
  box-shadow:6px 6px 0 {INK};white-space:nowrap}}
</style><body>
<div class="copy">
  <div class="label eyebrow">A pocket guide to spirits</div>
  <div class="display word">Drinkopedia</div>
  <div class="body tag">The stories behind 145&nbsp;spirits.</div>
</div>
<div class="bottle">{bottle_svg(440, ground=None)}</div>
{chips}
</body>"""


# --- phone screenshots ----------------------------------------------------------

SHOTS = (
    # file, raw capture, ground, text colour, shadow, headline, subline, tilt
    ("01-catalogue", "catalogue", ACID, INK, INK,
     "145 spirits<br>on one shelf", "Whiskey to mezcal, all in one place.", -1.5),
    ("02-origin-story", "detail", PINK, INK, INK,
     "Read the<br>origin story", "Where it came from and how it's made.", 1.5),
    ("03-filter", "filter", BLUE, PAPER, INK,
     "Filter by<br>what you drink", "One tap narrows the whole shelf.", -1.5),
    ("04-taste", "taste", PAPER, INK, INK,
     "Pick your<br>vibe", "Your favourites float to the top.", 1.5),
    ("05-search", "search", ACID, INK, INK,
     "Find any<br>spirit, fast", "Search by name or by type.", -1.5),
    ("06-dark-mode", "dark_detail", INK, ACID, ACID,
     "Looks good<br>in the dark", "Full dark mode, obviously.", 1.5),
)

SCREEN_W = 820
SCALE = SCREEN_W / RAW_W


# Shots whose screen ends well above the canvas edge: a complete card reads
# better than one bleeding off through a half-visible button.
CARD_HEIGHT = {"taste": 1040}

# A sticker under the card, where a short card leaves room for one. Only the
# app's own claims: taste picks are stored on the device, as the intro says.
STICKER = {"taste": ("Nothing leaves your phone", PINK)}


def shot_html(raw: str, ground: str, fg: str, shadow: str, headline: str,
              subline: str, tilt: float) -> str:
    height = CARD_HEIGHT.get(raw)
    height_css = f"height:{height}px;" if height else ""
    sticker = STICKER.get(raw)
    sticker_html = (
        f'<div class="label sticker" style="background:{sticker[1]}">{sticker[0]}</div>'
        if sticker else ""
    )
    border = PAPER if ground == INK else INK
    sub_colour = PAPER if ground == INK else fg
    crop = round(STATUS_BAR_PX * SCALE)
    return f"""<!doctype html><meta charset="utf-8"><style>{BASE_CSS}
body{{width:1080px;height:1920px;background:{ground};display:flex;
  flex-direction:column;align-items:center}}
.copy{{width:936px;padding-top:118px}}
h1{{font-size:112px;color:{fg}}}
p{{margin-top:30px;font-size:40px;line-height:1.2;color:{sub_colour};opacity:.9}}
.screen{{margin-top:78px;width:{SCREEN_W + 16}px;border:8px solid {border};
  box-shadow:22px 22px 0 {shadow};transform:rotate({tilt}deg);overflow:hidden;
  {height_css}
  background:{border}}}
.screen img{{display:block;width:{SCREEN_W}px;margin-top:-{crop}px}}
.sticker{{margin-top:92px;padding:20px 30px;font-size:34px;color:{INK};
  border:6px solid {INK};box-shadow:9px 9px 0 {INK};transform:rotate(-3deg)}}
</style><body>
<div class="copy"><h1 class="display">{headline}</h1><p class="body">{subline}</p></div>
<div class="screen"><img src="{(RAW / (raw + '.png')).as_uri()}"></div>
{sticker_html}
</body>"""


def render(target: pathlib.Path, html: str, width: int, height: int) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    # The page embeds the fonts as base64, so it is built in a scratch
    # directory and never lands next to the output.
    with tempfile.TemporaryDirectory() as scratch:
        page = pathlib.Path(scratch) / "page.html"
        page.write_text(html)
        subprocess.run(
            [
                CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", f"--window-size={width},{height}",
                "--virtual-time-budget=3000", "--allow-file-access-from-files",
                f"--screenshot={target}", page.as_uri(),
            ],
            check=True,
            capture_output=True,
        )


def add_alpha_channel(png: pathlib.Path) -> None:
    """Re-encodes an 8-bit RGB PNG as RGBA, fully opaque.

    Play Console asks for the hi-res icon as a 32-bit PNG, and Chrome writes an
    opaque capture as 24-bit. Done by hand so the generator needs nothing
    beyond the standard library.
    """
    data = png.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"{png} is not a PNG"
    pos, idat, header = 8, b"", None
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = body
        elif kind == b"IDAT":
            idat += body
        pos += 12 + length
    width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", header)
    if colour == 6:
        return  # already RGBA
    assert (depth, colour, interlace) == (8, 2, 0), "expected 8-bit, RGB, non-interlaced"

    raw, stride, bpp = zlib.decompress(idat), width * 3, 3
    rows, previous = [], bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        kind, line = raw[start], bytearray(raw[start + 1:start + 1 + stride])
        for x in range(stride):
            left = line[x - bpp] if x >= bpp else 0
            up = previous[x]
            upper_left = previous[x - bpp] if x >= bpp else 0
            if kind == 1:
                line[x] = (line[x] + left) & 0xFF
            elif kind == 2:
                line[x] = (line[x] + up) & 0xFF
            elif kind == 3:
                line[x] = (line[x] + (left + up) // 2) & 0xFF
            elif kind == 4:
                p = left + up - upper_left
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - upper_left)
                predictor = left if pa <= pb and pa <= pc else up if pb <= pc else upper_left
                line[x] = (line[x] + predictor) & 0xFF
        rows.append(line)
        previous = line

    rgba = bytearray()
    for line in rows:
        rgba.append(0)  # filter: none
        for x in range(0, stride, 3):
            rgba += line[x:x + 3] + b"\xff"

    def chunk(kind: bytes, body: bytes) -> bytes:
        return (struct.pack(">I", len(body)) + kind + body
                + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

    png.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(rgba), 9))
        + chunk(b"IEND", b"")
    )


def main() -> None:
    render(OUT / "icon-512.png", icon_html(), 512, 512)
    add_alpha_channel(OUT / "icon-512.png")
    render(OUT / "feature-graphic-1024x500.png", feature_html(), 1024, 500)
    for name, raw, ground, fg, shadow, headline, subline, tilt in SHOTS:
        render(
            SHOTS_DIR / f"{name}.png",
            shot_html(raw, ground, fg, shadow, headline, subline, tilt),
            1080, 1920,
        )
    for png in sorted(OUT.rglob("*.png")):
        if RAW not in png.parents:
            print(png.relative_to(OUT))


if __name__ == "__main__":
    main()
