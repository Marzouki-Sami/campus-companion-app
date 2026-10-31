"""Generates the launcher icon sources in assets/icon/.

Usage: python tool/generate_icon.py   (requires Pillow)
Then:  dart run flutter_launcher_icons
"""
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SCALE = 2  # supersampling for smooth edges
OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"

TOP, BOTTOM = (79, 70, 229), (14, 116, 232)  # indigo -> blue
WHITE = (255, 255, 255, 255)
ACCENT = (52, 211, 153, 255)  # emerald check badge


def gradient() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        row = tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM))
        for x in range(SIZE):
            px[x, y] = row
    return img.convert("RGBA")


def foreground() -> Image.Image:
    """Graduation cap + check badge on a transparent canvas (safe-zone sized)."""
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def p(x, y):
        return (x * s / 100, y * s / 100)

    # cap base (below the board)
    d.polygon([p(30, 47), p(30, 62), p(50, 71), p(70, 62), p(70, 47), p(50, 56)], fill=WHITE)
    # mortar board
    d.polygon([p(50, 26), p(86, 41), p(50, 56), p(14, 41)], fill=WHITE)
    # tassel
    d.line([p(78, 45), p(78, 60)], fill=WHITE, width=round(2.4 * s / 100))
    d.ellipse([*p(75, 58), *p(81, 65)], fill=WHITE)
    # check badge
    cx, cy, r = 70, 72, 13
    d.ellipse([*p(cx - r - 2, cy - r - 2), *p(cx + r + 2, cy + r + 2)], fill=(30, 64, 175, 255))
    d.ellipse([*p(cx - r, cy - r), *p(cx + r, cy + r)], fill=ACCENT)
    d.line([p(cx - 6, cy + 0.5), p(cx - 1.5, cy + 5), p(cx + 7, cy - 5)],
           fill=WHITE, width=round(2.6 * s / 100), joint="curve")
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fg = foreground()
    fg.save(OUT / "icon_foreground.png")

    full = gradient()
    full.alpha_composite(fg)
    # rounded square for legacy / non-adaptive launchers
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=SIZE // 5, fill=255)
    rounded = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rounded.paste(full, mask=mask)
    rounded.save(OUT / "icon.png")


if __name__ == "__main__":
    main()
