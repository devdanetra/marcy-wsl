#!/usr/bin/env python3
"""Check assets/marcy.ico is valid and still matches the frog in motd.sh.

Usage: python tests/test_icon.py   (requires Pillow)
"""
import importlib.util
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("make_icon", ROOT / "scripts" / "make-icon.py")
make_icon = importlib.util.module_from_spec(spec)
spec.loader.exec_module(make_icon)


def test_ico_has_all_sizes():
    with Image.open(make_icon.OUT) as ico:
        assert ico.format == "ICO"
        sizes = {s[0] for s in ico.info["sizes"]}
    assert sizes == set(make_icon.SIZES), f"ico sizes {sorted(sizes)}"


def test_ico_has_transparency():
    with Image.open(make_icon.OUT) as ico:
        ico.size = (256, 256)
        img = ico.convert("RGBA")
    assert img.getpixel((0, 0))[3] == 0, "corner should be transparent"


def test_icon_matches_motd_frog():
    frog = make_icon.render()
    assert frog.size[0] > 10 and frog.size[1] > 10, f"frog too small: {frog.size}"
    with Image.open(make_icon.PNG) as png:
        committed = png.convert("RGBA")
    assert make_icon.icon_image().tobytes() == committed.tobytes(), \
        "assets are stale: run python scripts/make-icon.py"


if __name__ == "__main__":
    failed = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            try:
                fn()
                print(f"  ok   {name}")
            except AssertionError as e:
                failed += 1
                print(f"  FAIL {name}: {e}")
    sys.exit(1 if failed else 0)
