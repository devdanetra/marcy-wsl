#!/usr/bin/env python3
"""Render the motd frog (configs/motd.sh) into assets/marcy.ico.

Each terminal cell is decoded as a 2x2 grid of quadrant subpixels. Cells are
twice as tall as wide, so every subpixel becomes 1x2 pixels, giving a square
source image that is padded and nearest-neighbour scaled to icon sizes.

Usage: python scripts/make-icon.py   (requires Pillow)
"""
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MOTD = ROOT / "configs" / "motd.sh"
OUT = ROOT / "assets" / "marcy.ico"
PNG = ROOT / "assets" / "marcy.png"
SIZES = [16, 24, 32, 48, 64, 128, 256]

# quadrant bits: top-left, top-right, bottom-left, bottom-right
QUAD = {
    " ": (0, 0, 0, 0), "▘": (1, 0, 0, 0), "▝": (0, 1, 0, 0), "▖": (0, 0, 1, 0),
    "▗": (0, 0, 0, 1), "▀": (1, 1, 0, 0), "▄": (0, 0, 1, 1), "▌": (1, 0, 1, 0),
    "▐": (0, 1, 0, 1), "▚": (1, 0, 0, 1), "▞": (0, 1, 1, 0), "▙": (1, 0, 1, 1),
    "▛": (1, 1, 1, 0), "▜": (1, 1, 0, 1), "▟": (0, 1, 1, 1), "█": (1, 1, 1, 1),
}
TOKEN = re.compile(r"\\e\[([0-9;]*)m|(.)")


def frog_lines():
    text = MOTD.read_text(encoding="utf-8")
    block = re.search(r"<<'FROG_EOF'\n(.*?)\nFROG_EOF", text, re.S).group(1)
    return block.split("\n")


def parse_sgr(params, state):
    p = [int(x) for x in params.split(";") if x] or [0]
    i = 0
    while i < len(p):
        if p[i] == 0:
            state["fg"] = state["bg"] = None
        elif p[i] in (38, 48) and p[i + 1] == 2:
            state["fg" if p[i] == 38 else "bg"] = tuple(p[i + 2:i + 5]) + (255,)
            i += 4
        i += 1


def render():
    rows = frog_lines()
    cells = []
    for line in rows:
        state, row = {"fg": None, "bg": None}, []
        for sgr, ch in TOKEN.findall(line):
            if ch:
                row.append((ch, state["fg"], state["bg"]))
            else:
                parse_sgr(sgr, state)
        cells.append(row)

    width = max(len(r) for r in cells) * 2
    height = len(cells) * 4
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for y, row in enumerate(cells):
        for x, (ch, fg, bg) in enumerate(row):
            for q, on in enumerate(QUAD.get(ch, (0, 0, 0, 0))):
                color = fg if on else bg
                if not color:
                    continue
                px, py = x * 2 + q % 2, y * 4 + (q // 2) * 2
                img.putpixel((px, py), color)
                img.putpixel((px, py + 1), color)
    return img.crop(img.getbbox())


def icon_image():
    frog = render()
    side = max(frog.size) + 2
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(frog, ((side - frog.width) // 2, (side - frog.height) // 2))
    return square.resize((256, 256), Image.NEAREST)


def main():
    big = icon_image()
    OUT.parent.mkdir(exist_ok=True)
    big.save(PNG)
    big.save(OUT, sizes=[(s, s) for s in SIZES])
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
