#!/usr/bin/env python3
"""Generate Wobble and the bakery cart for Day 3.

Wobble is a wobbly molar who has made a nest on the stolen dental chair. The
bakery cart is the hub landmark that leads the player to him.

Run from the project root:

    python3 tools/generate_wobble.py

Requires Pillow. Nearest-neighbour upscales keep the pixels crisp.
"""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

IVORY = (247, 242, 222, 255)
IVORY_LIGHT = (255, 253, 240, 255)
IVORY_SHADOW = (214, 204, 178, 255)
OUTLINE = (92, 74, 60, 255)
PINK = (232, 158, 160, 255)
PINK_DARK = (196, 116, 122, 255)
MINT = (150, 214, 184, 255)
MINT_DARK = (104, 174, 146, 255)
BROWN = (150, 102, 62, 255)
BROWN_DARK = (104, 68, 42, 255)
WOOD = (208, 158, 102, 255)
WOOD_DARK = (162, 114, 70, 255)
CREAM = (250, 236, 205, 255)


def upscale(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("wrote", rel, img.size)


# ---------------------------------------------------------------------------
# World sprite: 32x32, upscaled to 64x64
# ---------------------------------------------------------------------------

def wobble_body(d: ImageDraw.ImageDraw) -> None:
    # roots
    d.polygon([(10, 22), (15, 22), (14, 30), (11, 30)], fill=IVORY_SHADOW)
    d.polygon([(18, 22), (23, 22), (22, 30), (19, 30)], fill=IVORY_SHADOW)
    d.line([(10, 22), (11, 30)], fill=OUTLINE)
    d.line([(15, 22), (14, 30)], fill=OUTLINE)
    d.line([(18, 22), (19, 30)], fill=OUTLINE)
    d.line([(23, 22), (22, 30)], fill=OUTLINE)
    d.line([(11, 30), (14, 30)], fill=OUTLINE)
    d.line([(19, 30), (22, 30)], fill=OUTLINE)

    # crown
    d.ellipse([5, 5, 27, 25], fill=IVORY, outline=OUTLINE)
    d.ellipse([7, 7, 25, 22], fill=IVORY_LIGHT)
    d.arc([8, 8, 24, 22], 200, 340, fill=IVORY_SHADOW)

    # faint plaque spots
    d.ellipse([8, 18, 11, 21], fill=MINT)
    d.ellipse([22, 12, 24, 14], fill=MINT_DARK)

    # chef hat
    d.ellipse([7, 0, 14, 6], fill=CREAM, outline=OUTLINE)
    d.ellipse([12, 0, 19, 6], fill=CREAM, outline=OUTLINE)
    d.ellipse([17, 1, 24, 7], fill=CREAM, outline=OUTLINE)
    d.rectangle([8, 4, 23, 8], fill=CREAM, outline=OUTLINE)
    d.rectangle([8, 6, 23, 8], fill=PINK)
    d.line([8, 8, 23, 8], fill=OUTLINE)

    # face
    d.ellipse([9, 10, 13, 15], fill=(255, 255, 255, 255))
    d.ellipse([18, 10, 22, 15], fill=(255, 255, 255, 255))
    d.ellipse([10, 12, 12, 14], fill=OUTLINE)
    d.ellipse([19, 12, 21, 14], fill=OUTLINE)
    d.arc([12, 16, 20, 21], 20, 160, fill=OUTLINE, width=1)
    d.ellipse([7, 15, 9, 17], fill=PINK)
    d.ellipse([23, 15, 25, 17], fill=PINK)

    # little baker hands
    d.ellipse([2, 13, 6, 17], fill=IVORY, outline=OUTLINE)
    d.ellipse([26, 13, 30, 17], fill=IVORY, outline=OUTLINE)
    d.line([(3, 15), (5, 15)], fill=OUTLINE)
    d.line([(27, 15), (29, 15)], fill=OUTLINE)


def wobble_sprite() -> Image.Image:
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    wobble_body(ImageDraw.Draw(img))
    return upscale(img, 2)


# ---------------------------------------------------------------------------
# Portrait: 4 frames of 100x148
# ---------------------------------------------------------------------------

def portrait_frame(expr: int) -> Image.Image:
    """expr: 0 neutral, 1 blink, 2 open mouth, 3 blink + open mouth."""
    bg = (246, 222, 197, 255)
    f = Image.new("RGBA", (50, 74), bg)
    d = ImageDraw.Draw(f)

    for cx, cy, r, col in [
        (8, 9, 5, (255, 255, 255, 42)),
        (42, 15, 7, (255, 255, 255, 30)),
        (13, 62, 6, (255, 255, 255, 26)),
    ]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)

    # little bakery counter
    d.rectangle([0, 64, 49, 73], fill=WOOD)
    d.rectangle([0, 64, 49, 66], fill=WOOD_DARK)

    # roots behind the body
    d.polygon([(16, 48), (23, 48), (21, 68), (17, 68)], fill=IVORY_SHADOW)
    d.polygon([(27, 48), (34, 48), (33, 68), (29, 68)], fill=IVORY_SHADOW)
    for x1, x2 in [(16, 21), (23, 17), (27, 33), (34, 29)]:
        d.line([(x1, 48), (x2, 68)], fill=OUTLINE)

    # body / crown
    d.ellipse([8, 18, 42, 58], fill=IVORY, outline=OUTLINE, width=2)
    d.ellipse([11, 20, 39, 53], fill=IVORY_LIGHT)
    d.arc([12, 24, 38, 54], 200, 340, fill=IVORY_SHADOW, width=2)

    # mint plaque freckles
    d.ellipse([12, 42, 17, 47], fill=MINT)
    d.ellipse([35, 35, 38, 38], fill=MINT_DARK)
    d.ellipse([18, 49, 20, 51], fill=MINT)

    # chef hat
    d.ellipse([13, 2, 24, 15], fill=CREAM, outline=OUTLINE, width=1)
    d.ellipse([21, 1, 32, 14], fill=CREAM, outline=OUTLINE, width=1)
    d.ellipse([28, 3, 38, 15], fill=CREAM, outline=OUTLINE, width=1)
    d.rectangle([14, 11, 37, 20], fill=CREAM, outline=OUTLINE, width=1)
    d.rectangle([14, 17, 37, 20], fill=PINK)
    d.line([14, 20, 37, 20], fill=OUTLINE)

    # eyes
    if expr in (1, 3):
        d.line([16, 31, 23, 31], fill=OUTLINE, width=2)
        d.line([28, 31, 35, 31], fill=OUTLINE, width=2)
    else:
        d.ellipse([15, 26, 24, 36], fill=(255, 255, 255, 255), outline=OUTLINE)
        d.ellipse([27, 26, 36, 36], fill=(255, 255, 255, 255), outline=OUTLINE)
        d.ellipse([18, 29, 22, 33], fill=OUTLINE)
        d.ellipse([30, 29, 34, 33], fill=OUTLINE)

    # brows
    d.line([15, 23, 24, 24], fill=OUTLINE, width=1)
    d.line([27, 24, 36, 23], fill=OUTLINE, width=1)

    # cheeks
    d.ellipse([11, 37, 16, 42], fill=PINK)
    d.ellipse([34, 37, 39, 42], fill=PINK)

    # mouth
    if expr in (2, 3):
        d.ellipse([21, 40, 30, 50], fill=(122, 62, 66, 255), outline=OUTLINE)
        d.rectangle([23, 41, 28, 43], fill=(255, 255, 255, 255))
    else:
        d.arc([20, 38, 31, 48], 20, 160, fill=OUTLINE, width=2)

    return upscale(f, 2)


def portrait_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (400, 148), (0, 0, 0, 0))
    for i in range(4):
        sheet.paste(portrait_frame(i), (i * 100, 0))
    return sheet


# ---------------------------------------------------------------------------
# Bakery cart: 64x48 world prop
# ---------------------------------------------------------------------------

def bakery_cart() -> Image.Image:
    img = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # awning posts
    d.rectangle([7, 12, 9, 38], fill=WOOD_DARK)
    d.rectangle([55, 12, 57, 38], fill=WOOD_DARK)

    # striped awning
    d.rectangle([3, 4, 61, 14], fill=PINK, outline=OUTLINE)
    for x in range(3, 61, 8):
        d.rectangle([x, 4, min(x + 4, 60), 13], fill=CREAM)
    d.rectangle([3, 12, 61, 15], fill=PINK_DARK, outline=OUTLINE)

    # counter and body
    d.rectangle([5, 22, 59, 38], fill=WOOD, outline=OUTLINE)
    d.rectangle([7, 24, 57, 36], fill=(224, 178, 118, 255))
    d.line([5, 30, 59, 30], fill=WOOD_DARK)
    d.rectangle([7, 32, 24, 35], fill=WOOD_DARK)
    d.rectangle([40, 32, 57, 35], fill=WOOD_DARK)

    # loaves and buns on the counter
    for cx, cy in [(14, 20), (26, 19), (38, 20), (50, 19)]:
        d.ellipse([cx - 5, cy - 3, cx + 5, cy + 3], fill=(214, 160, 92, 255),
                  outline=BROWN_DARK)
        d.line([cx - 2, cy - 2, cx + 2, cy + 1], fill=(244, 202, 142, 255))
    d.ellipse([20, 15, 32, 24], fill=(248, 220, 176, 255), outline=BROWN_DARK)
    d.ellipse([23, 16, 29, 20], fill=(255, 245, 225, 255))

    # wheels
    for cx in (15, 49):
        d.ellipse([cx - 7, 37, cx + 7, 47], fill=BROWN_DARK, outline=OUTLINE)
        d.ellipse([cx - 4, 40, cx + 4, 46], fill=WOOD)
        d.ellipse([cx - 2, 42, cx + 2, 45], fill=BROWN_DARK)

    return img


def main() -> None:
    save(wobble_sprite(), "Assets_Imported/villains/wobble.png")
    save(portrait_sheet(), "Assets_Imported/villains/wobble_portrait.png")
    save(bakery_cart(), "Assets_Imported/town/bakery_cart.png")


if __name__ == "__main__":
    main()
