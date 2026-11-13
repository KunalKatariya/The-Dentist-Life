#!/usr/bin/env python3
"""Generate Day 4 art: Gloam, Rattle, the tea lamp and the X-ray board.

Gloam is a dusk-blue light thief who nests by the tea cart. Rattle is a small
skeleton who is very proud of his bones. Both use the same 64x64 world sprite
and four-frame 400x148 portrait conventions as Blorb and Wobble.

Run from the project root:

    python3 tools/generate_day4.py

Requires Pillow. Nearest-neighbour upscales keep the pixels crisp.
"""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# Gloam palette
DUSK = (88, 84, 142, 255)
DUSK_LIGHT = (116, 112, 176, 255)
DUSK_DARK = (58, 54, 98, 255)
DUSK_OUTLINE = (34, 30, 58, 255)
AMBER = (255, 198, 96, 255)
AMBER_LIGHT = (255, 238, 170, 255)
AMBER_DARK = (214, 142, 58, 255)
PLUM_BG = (60, 54, 90, 255)
PLUM_GLOW = (112, 102, 158, 54)

# Rattle palette
BONE = (244, 240, 222, 255)
BONE_LIGHT = (255, 253, 242, 255)
BONE_SHADOW = (206, 200, 176, 255)
BONE_OUTLINE = (66, 76, 70, 255)
TEAL = (122, 226, 208, 255)
TEAL_DARK = (54, 116, 108, 255)
TEAL_BG = (186, 226, 214, 255)
TEAL_GLOW = (255, 255, 255, 70)
FILM = (32, 58, 56, 255)

# Props
WOOD = (176, 126, 76, 255)
WOOD_DARK = (122, 82, 48, 255)
IRON = (74, 78, 86, 255)
IRON_LIGHT = (116, 122, 132, 255)
CREAM = (250, 238, 210, 255)
PINK = (226, 152, 150, 255)


def upscale(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("wrote", rel, img.size)


# ---------------------------------------------------------------------------
# Gloam world sprite: 32x32, upscaled to 64x64
# ---------------------------------------------------------------------------

def gloam_body(d: ImageDraw.ImageDraw) -> None:
    # soft floor shadow
    d.ellipse([5, 26, 27, 31], fill=(30, 24, 48, 90))

    # wispy tail
    d.polygon([(13, 24), (18, 24), (16, 31), (14, 31)], fill=DUSK_DARK)
    d.line([(13, 24), (14, 31)], fill=DUSK_OUTLINE)
    d.line([(18, 24), (16, 31)], fill=DUSK_OUTLINE)

    # round smoky body
    d.ellipse([5, 7, 27, 27], fill=DUSK, outline=DUSK_OUTLINE)
    d.ellipse([7, 9, 24, 24], fill=DUSK_LIGHT)
    d.arc([7, 10, 25, 26], 200, 340, fill=DUSK_DARK)

    # flame tuft
    d.polygon([(14, 0), (18, 8), (16, 12), (12, 12), (10, 7)], fill=AMBER_DARK)
    d.polygon([(15, 2), (18, 9), (16, 11), (13, 11), (12, 7)], fill=AMBER)
    d.ellipse([14, 5, 17, 10], fill=AMBER_LIGHT)

    # tired amber eyes
    d.ellipse([9, 13, 14, 18], fill=AMBER_LIGHT)
    d.ellipse([18, 13, 23, 18], fill=AMBER_LIGHT)
    d.ellipse([11, 15, 13, 17], fill=DUSK_OUTLINE)
    d.ellipse([20, 15, 22, 17], fill=DUSK_OUTLINE)

    # small worried mouth
    d.line([(14, 21), (16, 22), (18, 21)], fill=DUSK_OUTLINE)

    # little hands clutching a curing light
    d.ellipse([2, 17, 6, 21], fill=DUSK, outline=DUSK_OUTLINE)
    d.ellipse([26, 17, 30, 21], fill=DUSK, outline=DUSK_OUTLINE)
    d.rectangle([13, 22, 19, 26], fill=IRON)
    d.rectangle([11, 20, 21, 23], fill=AMBER, outline=AMBER_DARK)
    d.rectangle([13, 21, 19, 22], fill=AMBER_LIGHT)


def gloam_sprite() -> Image.Image:
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    gloam_body(ImageDraw.Draw(img))
    return upscale(img, 2)


# ---------------------------------------------------------------------------
# Gloam portrait: four 100x148 frames
# ---------------------------------------------------------------------------

def gloam_frame(expr: int) -> Image.Image:
    """expr: 0 neutral, 1 blink, 2 open mouth, 3 blink + open mouth."""
    f = Image.new("RGBA", (50, 74), PLUM_BG)
    d = ImageDraw.Draw(f)

    # warm glows in the dusk
    for cx, cy, r in [(10, 12, 7), (41, 18, 9), (12, 60, 8), (40, 62, 6)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PLUM_GLOW)

    # tea cup on the counter
    d.rectangle([0, 66, 49, 73], fill=WOOD)
    d.rectangle([0, 66, 49, 68], fill=WOOD_DARK)
    d.rectangle([34, 57, 44, 65], fill=CREAM, outline=DUSK_OUTLINE)
    d.arc([43, 59, 48, 64], 270, 90, fill=DUSK_OUTLINE, width=1)
    d.line([37, 53, 36, 57], fill=CREAM)
    d.line([41, 52, 40, 57], fill=CREAM)

    # smoky tail
    d.polygon([(18, 50), (25, 50), (23, 68), (20, 68)], fill=DUSK_DARK)
    d.polygon([(27, 50), (34, 50), (33, 68), (29, 68)], fill=DUSK_DARK)
    for x1, x2 in [(18, 23), (25, 20), (27, 33), (34, 29)]:
        d.line([(x1, 50), (x2, 68)], fill=DUSK_OUTLINE)

    # body
    d.ellipse([7, 19, 43, 61], fill=DUSK, outline=DUSK_OUTLINE, width=2)
    d.ellipse([10, 21, 40, 56], fill=DUSK_LIGHT)
    d.arc([12, 25, 39, 58], 200, 340, fill=DUSK_DARK, width=2)

    # flame tuft
    d.polygon([(25, 0), (33, 13), (29, 22), (21, 22), (17, 13)],
              fill=AMBER_DARK, outline=DUSK_OUTLINE)
    d.polygon([(25, 3), (31, 14), (28, 20), (22, 20), (20, 13)], fill=AMBER)
    d.ellipse([23, 8, 28, 17], fill=AMBER_LIGHT)

    # eyes
    if expr in (1, 3):
        d.line([16, 31, 24, 31], fill=DUSK_OUTLINE, width=2)
        d.line([28, 31, 36, 31], fill=DUSK_OUTLINE, width=2)
    else:
        d.ellipse([14, 26, 25, 37], fill=AMBER_LIGHT, outline=DUSK_OUTLINE)
        d.ellipse([27, 26, 38, 37], fill=AMBER_LIGHT, outline=DUSK_OUTLINE)
        d.ellipse([18, 30, 22, 34], fill=DUSK_OUTLINE)
        d.ellipse([31, 30, 35, 34], fill=DUSK_OUTLINE)
        d.ellipse([16, 27, 18, 29], fill=(255, 255, 255, 210))
        d.ellipse([29, 27, 31, 29], fill=(255, 255, 255, 210))

    # worried brows
    d.line([14, 23, 23, 25], fill=DUSK_OUTLINE)
    d.line([29, 25, 38, 23], fill=DUSK_OUTLINE)

    # cheeks
    d.ellipse([11, 39, 15, 43], fill=(140, 110, 170, 255))
    d.ellipse([37, 39, 41, 43], fill=(140, 110, 170, 255))

    # mouth
    if expr in (2, 3):
        d.ellipse([21, 42, 31, 51], fill=(30, 26, 50, 255), outline=DUSK_OUTLINE)
        d.ellipse([23, 45, 29, 49], fill=AMBER_DARK)
    else:
        d.line([20, 45, 24, 47, 28, 45, 32, 47], fill=DUSK_OUTLINE, width=1)

    # hands holding the little curing light
    d.ellipse([5, 46, 12, 53], fill=DUSK, outline=DUSK_OUTLINE)
    d.ellipse([39, 46, 46, 53], fill=DUSK, outline=DUSK_OUTLINE)
    d.rectangle([20, 55, 30, 61], fill=IRON, outline=DUSK_OUTLINE)
    d.rectangle([17, 51, 33, 56], fill=AMBER, outline=AMBER_DARK)
    d.rectangle([20, 52, 30, 54], fill=AMBER_LIGHT)

    return upscale(f, 2)


def gloam_portrait() -> Image.Image:
    sheet = Image.new("RGBA", (400, 148), (0, 0, 0, 0))
    for i in range(4):
        sheet.paste(gloam_frame(i), (i * 100, 0))
    return sheet


# ---------------------------------------------------------------------------
# Rattle world sprite: 32x32, upscaled to 64x64
# ---------------------------------------------------------------------------

def rattle_body(d: ImageDraw.ImageDraw) -> None:
    # shadow
    d.ellipse([6, 27, 26, 31], fill=(30, 40, 36, 80))

    # legs
    d.line([(12, 23), (10, 30)], fill=BONE_OUTLINE, width=2)
    d.line([(20, 23), (22, 30)], fill=BONE_OUTLINE, width=2)
    d.line([(14, 23), (13, 29)], fill=BONE, width=1)
    d.line([(18, 23), (19, 29)], fill=BONE, width=1)
    d.line([(8, 30), (12, 30)], fill=BONE_OUTLINE, width=2)
    d.line([(20, 30), (24, 30)], fill=BONE_OUTLINE, width=2)

    # spine and ribs
    d.line([(16, 16), (16, 25)], fill=BONE_OUTLINE, width=2)
    for y in (17, 20, 23):
        d.line([(12, y), (20, y)], fill=BONE, width=2)
        d.line([(12, y), (20, y)], fill=BONE_OUTLINE, width=1)
    d.line([(12, 17), (12, 23)], fill=BONE_OUTLINE)
    d.line([(20, 17), (20, 23)], fill=BONE_OUTLINE)

    # skull
    d.ellipse([8, 3, 24, 18], fill=BONE, outline=BONE_OUTLINE)
    d.ellipse([10, 4, 22, 15], fill=BONE_LIGHT)
    d.arc([10, 6, 22, 18], 200, 340, fill=BONE_SHADOW)

    # eye sockets
    d.ellipse([11, 8, 15, 12], fill=TEAL_DARK)
    d.ellipse([17, 8, 21, 12], fill=TEAL_DARK)
    d.ellipse([12, 9, 14, 11], fill=TEAL)
    d.ellipse([18, 9, 20, 11], fill=TEAL)

    # nose and grin
    d.polygon([(15, 12), (17, 12), (16, 14)], fill=TEAL_DARK)
    d.line([(12, 15), (20, 15)], fill=BONE_OUTLINE, width=1)
    d.line([(13, 15), (13, 16)], fill=BONE_OUTLINE)
    d.line([(16, 15), (16, 16)], fill=BONE_OUTLINE)
    d.line([(19, 15), (19, 16)], fill=BONE_OUTLINE)

    # arms and an X-ray film
    d.line([(9, 19), (5, 22)], fill=BONE_OUTLINE, width=2)
    d.line([(23, 19), (27, 22)], fill=BONE_OUTLINE, width=2)
    d.rectangle([20, 21, 28, 27], fill=FILM, outline=TEAL)
    d.ellipse([22, 23, 26, 26], fill=TEAL)
    d.ellipse([23, 23, 25, 25], fill=FILM)


def rattle_sprite() -> Image.Image:
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    rattle_body(ImageDraw.Draw(img))
    return upscale(img, 2)


# ---------------------------------------------------------------------------
# Rattle portrait: four 100x148 frames
# ---------------------------------------------------------------------------

def rattle_frame(expr: int) -> Image.Image:
    """expr: 0 neutral, 1 blink, 2 open mouth, 3 blink + open mouth."""
    f = Image.new("RGBA", (50, 74), TEAL_BG)
    d = ImageDraw.Draw(f)

    for cx, cy, r in [(9, 10, 8), (42, 16, 9), (10, 62, 7), (42, 64, 8)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=TEAL_GLOW)

    # film frame behind the skull
    d.rectangle([4, 4, 46, 70], fill=FILM, outline=TEAL_DARK)
    d.rectangle([6, 6, 44, 68], outline=TEAL)
    for x, y in [(8, 8), (42, 8), (8, 66), (42, 66)]:
        d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=TEAL)

    # spine and ribs
    d.rectangle([23, 54, 27, 69], fill=BONE_SHADOW, outline=BONE_OUTLINE)
    for y in (57, 61, 65):
        d.arc([14, y - 4, 36, y + 4], 200, 340, fill=BONE, width=3)
        d.arc([14, y - 4, 36, y + 4], 200, 340, fill=BONE_OUTLINE, width=1)

    # skull
    d.ellipse([9, 10, 41, 48], fill=BONE, outline=BONE_OUTLINE, width=2)
    d.ellipse([12, 12, 38, 44], fill=BONE_LIGHT)
    d.arc([12, 16, 38, 48], 200, 340, fill=BONE_SHADOW, width=2)
    d.line([15, 20, 22, 18], fill=BONE_SHADOW)
    d.line([28, 18, 35, 20], fill=BONE_SHADOW)

    # eye sockets
    if expr in (1, 3):
        d.line([14, 27, 22, 27], fill=TEAL_DARK, width=2)
        d.line([28, 27, 36, 27], fill=TEAL_DARK, width=2)
    else:
        d.ellipse([13, 22, 23, 32], fill=TEAL_DARK, outline=BONE_OUTLINE)
        d.ellipse([27, 22, 37, 32], fill=TEAL_DARK, outline=BONE_OUTLINE)
        d.ellipse([17, 26, 20, 29], fill=TEAL)
        d.ellipse([31, 26, 34, 29], fill=TEAL)
        d.ellipse([18, 26, 19, 27], fill=(255, 255, 255, 230))
        d.ellipse([32, 26, 33, 27], fill=(255, 255, 255, 230))

    # nose
    d.polygon([(23, 34), (27, 34), (25, 38)], fill=TEAL_DARK, outline=BONE_OUTLINE)

    # grin
    if expr in (2, 3):
        d.ellipse([18, 39, 32, 49], fill=(32, 48, 46, 255), outline=BONE_OUTLINE)
        d.rectangle([20, 40, 30, 42], fill=BONE)
        for x in (22, 25, 28):
            d.line([(x, 42), (x, 47)], fill=BONE_OUTLINE)
    else:
        d.line([17, 41, 33, 41], fill=BONE_OUTLINE, width=2)
        for x in (20, 25, 30):
            d.line([(x, 41), (x, 46)], fill=BONE_OUTLINE)

    # collar
    d.polygon([(12, 57), (18, 49), (25, 50), (20, 58)], fill=CREAM, outline=BONE_OUTLINE)
    d.polygon([(38, 57), (32, 49), (25, 50), (30, 58)], fill=CREAM, outline=BONE_OUTLINE)
    d.rectangle([24, 50, 26, 58], fill=PINK)

    # hand holding a little film
    d.ellipse([36, 54, 45, 63], fill=BONE, outline=BONE_OUTLINE)
    d.rectangle([37, 48, 48, 58], fill=FILM, outline=TEAL)
    d.ellipse([40, 50, 45, 55], fill=TEAL)
    d.ellipse([41, 51, 44, 54], fill=FILM)

    return upscale(f, 2)


def rattle_portrait() -> Image.Image:
    sheet = Image.new("RGBA", (400, 148), (0, 0, 0, 0))
    for i in range(4):
        sheet.paste(rattle_frame(i), (i * 100, 0))
    return sheet


# ---------------------------------------------------------------------------
# Tea lamp prop: 32x64
# ---------------------------------------------------------------------------

def tea_lamp() -> Image.Image:
    img = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # warm halo
    for r, a in [(14, 24), (10, 40), (7, 70)]:
        d.ellipse([16 - r, 18 - r, 16 + r, 18 + r], fill=(255, 206, 120, a))

    # post and base
    d.rectangle([14, 20, 17, 60], fill=WOOD, outline=WOOD_DARK)
    d.rectangle([9, 58, 22, 63], fill=IRON, outline=WOOD_DARK)
    d.rectangle([11, 60, 20, 62], fill=IRON_LIGHT)

    # arm
    d.rectangle([15, 18, 26, 21], fill=WOOD_DARK)
    d.line([(25, 20), (25, 24)], fill=IRON)

    # lantern
    d.rectangle([20, 23, 30, 36], fill=(42, 34, 30, 255), outline=IRON)
    d.rectangle([22, 25, 28, 34], fill=AMBER)
    d.rectangle([23, 26, 27, 33], fill=AMBER_LIGHT)
    d.rectangle([21, 22, 29, 24], fill=IRON_LIGHT)
    d.rectangle([21, 35, 29, 37], fill=IRON_LIGHT)
    d.line([(25, 20), (25, 23)], fill=IRON)

    # little tea cup on the base
    d.rectangle([4, 54, 10, 59], fill=CREAM, outline=WOOD_DARK)
    d.arc([10, 55, 13, 59], 270, 90, fill=WOOD_DARK, width=1)
    d.line([6, 51, 6, 54], fill=CREAM)
    d.line([8, 50, 8, 54], fill=CREAM)

    return img


# ---------------------------------------------------------------------------
# X-ray board prop: 48x56
# ---------------------------------------------------------------------------

def xray_board() -> Image.Image:
    img = Image.new("RGBA", (48, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # legs
    d.line([(14, 40), (8, 54)], fill=IRON, width=3)
    d.line([(34, 40), (40, 54)], fill=IRON, width=3)
    d.line([(8, 54), (16, 54)], fill=IRON_LIGHT, width=2)
    d.line([(32, 54), (40, 54)], fill=IRON_LIGHT, width=2)

    # frame
    d.rectangle([4, 2, 44, 42], fill=FILM, outline=IRON)
    d.rectangle([6, 4, 42, 40], outline=TEAL_DARK)
    d.rectangle([8, 6, 40, 38], outline=TEAL)

    # glowing tooth film
    d.ellipse([17, 8, 31, 22], fill=(20, 44, 42, 255))
    d.polygon([(20, 12), (28, 12), (27, 22), (25, 22), (24, 27),
               (22, 27), (21, 22), (19, 22)], fill=TEAL)
    d.ellipse([21, 13, 27, 19], fill=(210, 255, 248, 255))
    d.line([(10, 24), (38, 24)], fill=TEAL_DARK)

    # ribs and labels
    for y in (28, 32, 36):
        d.arc([10, y - 3, 38, y + 3], 200, 340, fill=TEAL, width=1)
    d.rectangle([8, 38, 18, 40], fill=TEAL_DARK)
    d.rectangle([30, 38, 40, 40], fill=TEAL_DARK)
    for x, y in [(8, 6), (40, 6), (8, 38), (40, 38)]:
        d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=IRON_LIGHT)

    return img


def main() -> None:
    save(gloam_sprite(), "Assets_Imported/villains/gloam.png")
    save(gloam_portrait(), "Assets_Imported/villains/gloam_portrait.png")
    save(rattle_sprite(), "Assets_Imported/villains/rattle.png")
    save(rattle_portrait(), "Assets_Imported/villains/rattle_portrait.png")
    save(tea_lamp(), "Assets_Imported/town/tea_lamp.png")
    save(xray_board(), "Assets_Imported/town/xray_board.png")


if __name__ == "__main__":
    main()
