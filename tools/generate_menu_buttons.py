#!/usr/bin/env python3
"""Generate the Continue button art in the same pixel style as the existing
Start/Exit buttons. Run from the project root:

    python3 tools/generate_menu_buttons.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SPRITES = ROOT / "Scenes" / "MainMenu" / "Sprites"

# Compact 3x5 glyphs, matching the chunky white pixel type of Start/Exit.
# "CONTINUE" is longer than "START", so it uses a slightly narrower font to
# keep the same 48x16 button footprint.
GLYPHS = {
    "C": ["###", "#  ", "#  ", "#  ", "###"],
    "O": ["###", "# #", "# #", "# #", "###"],
    "N": ["#  #", "## #", "# ##", "#  #", "#  #"],
    "T": ["###", " # ", " # ", " # ", " # "],
    "I": ["###", " # ", " # ", " # ", "###"],
    "U": ["# #", "# #", "# #", "# #", "###"],
    "E": ["###", "#  ", "###", "#  ", "###"],
}
TEXT = "CONTINUE"
LETTER_SPACING = 1
OUTLINE = 1


def _dominant_fill(image: Image.Image) -> tuple[int, int, int, int]:
    """Pick the most common opaque interior colour to erase baked-in text."""
    counts: dict[tuple[int, int, int, int], int] = {}
    for y in range(4, 13):
        for x in range(4, 44):
            pixel = image.getpixel((x, y))
            if pixel[3] == 0 or sum(pixel[:3]) < 30:
                continue
            if pixel[0] > 200 and pixel[1] > 200 and pixel[2] > 200:
                continue
            counts[pixel] = counts.get(pixel, 0) + 1
    return max(counts, key=counts.get)


def _draw_word(image: Image.Image, text: str) -> None:
    widths = [len(GLYPHS[letter][0]) for letter in text]
    width = sum(widths) + (len(text) - 1) * LETTER_SPACING
    x0 = (image.width - width) // 2
    y0 = 5
    pixels: list[tuple[int, int]] = []
    x = x0
    for letter in text:
        glyph = GLYPHS[letter]
        for gy, row in enumerate(glyph):
            for gx, cell in enumerate(row):
                if cell == "#":
                    pixels.append((x + gx, y0 + gy))
        x += len(glyph[0]) + LETTER_SPACING

    # Black outline first, then the white face on top.
    dark = (8, 8, 8, 255)
    for px, py in pixels:
        for oy in range(-OUTLINE, OUTLINE + 1):
            for ox in range(-OUTLINE, OUTLINE + 1):
                xx, yy = px + ox, py + oy
                if 0 <= xx < image.width and 0 <= yy < image.height:
                    image.putpixel((xx, yy), dark)
    for px, py in pixels:
        image.putpixel((px, py), (255, 255, 255, 255))


def build(source: str, target: str) -> None:
    base = Image.open(SPRITES / source).convert("RGBA")
    fill = _dominant_fill(base)
    # Erase the old icon and label, leaving the original border and shading.
    for y in range(4, 13):
        for x in range(4, 44):
            base.putpixel((x, y), fill)
    _draw_word(base, TEXT)
    base.save(SPRITES / target)
    print(f"wrote {target} ({base.width}x{base.height}, fill {fill})")


def main() -> None:
    build("Start_Idle_Button_new.png", "Continue_idle_Button.png")
    build("Start_hover_Button_new.png", "Continue_hover_Button.png")


if __name__ == "__main__":
    main()
