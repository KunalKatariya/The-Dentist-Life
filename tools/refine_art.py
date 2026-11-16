#!/usr/bin/env python3
"""Redraw every art asset that was generated for the clinic-quest content.

This replaces the earlier placeholder / Day 3 / Day 4 drawings with native
resolution pixel art: no 2x pixel blocks, consistent 1px detail, darker
outlines and a light source from the top-left. Sizes and frame layouts are
unchanged so scenes and animations keep working.

Only generated assets are written. Hand-made gift art (Kunal, Dr. Gunika,
main-menu paintings, Start/Exit buttons, map tiles) is never touched.

Run from the project root:

    python3 tools/refine_art.py

Requires Pillow.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# Shared palette ------------------------------------------------------------
INK = (38, 30, 42, 255)
INK_SOFT = (66, 54, 68, 255)
WHITE = (255, 253, 246, 255)
CREAM = (250, 240, 218, 255)
PAPER = (236, 225, 202, 255)

SKIN = (226, 172, 137, 255)
SKIN_LIGHT = (242, 196, 158, 255)
SKIN_SHADOW = (190, 132, 102, 255)
BLUSH = (222, 132, 126, 255)

BROWN = (74, 48, 38, 255)
BROWN_LIGHT = (108, 72, 52, 255)
GREY = (176, 178, 178, 255)
GREY_LIGHT = (212, 214, 212, 255)

TEAL = (74, 166, 158, 255)
TEAL_LIGHT = (112, 204, 192, 255)
TEAL_DARK = (42, 110, 108, 255)

BLUE = (78, 132, 196, 255)
BLUE_LIGHT = (128, 176, 224, 255)
BLUE_DARK = (48, 84, 140, 255)

MINT = (142, 216, 184, 255)
MINT_LIGHT = (184, 238, 212, 255)
MINT_DARK = (92, 172, 144, 255)

IVORY = (248, 242, 220, 255)
IVORY_LIGHT = (255, 252, 240, 255)
IVORY_SHADOW = (218, 206, 178, 255)

PINK = (226, 154, 156, 255)
PINK_DARK = (190, 110, 116, 255)

DUSK = (98, 94, 152, 255)
DUSK_LIGHT = (132, 128, 190, 255)
DUSK_DARK = (66, 62, 108, 255)
AMBER = (255, 196, 92, 255)
AMBER_LIGHT = (255, 238, 172, 255)
AMBER_DARK = (206, 132, 52, 255)

BONE = (244, 238, 214, 255)
BONE_LIGHT = (255, 252, 236, 255)
BONE_SHADOW = (206, 196, 166, 255)
CYAN = (122, 232, 216, 255)
CYAN_DARK = (48, 118, 112, 255)

WOOD = (184, 126, 74, 255)
WOOD_LIGHT = (216, 158, 98, 255)
WOOD_DARK = (126, 82, 48, 255)
IRON = (74, 80, 90, 255)
IRON_LIGHT = (126, 134, 146, 255)

MOLD = (126, 158, 96, 255)
MOLD_LIGHT = (170, 200, 128, 255)
MOLD_DARK = (84, 110, 70, 255)
MOLD_SLIME = (156, 198, 112, 255)

RED_TAPE = (198, 74, 66, 255)
RED_TAPE_DARK = (150, 46, 44, 255)
RED_TAPE_LIGHT = (230, 120, 108, 255)


def new(width: int, height: int) -> Image.Image:
    return Image.new("RGBA", (width, height), (0, 0, 0, 0))


def save(image: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print("wrote", rel, image.size)


def sheet(frames: list[Image.Image]) -> Image.Image:
    out = new(sum(f.width for f in frames), max(f.height for f in frames))
    x = 0
    for frame in frames:
        out.alpha_composite(frame, (x, 0))
        x += frame.width
    return out


def soft(image: Image.Image, box, fill) -> None:
    """Alpha-composite a translucent ellipse onto the image.

    ImageDraw writes RGBA values straight into an RGBA canvas, so drawing a
    translucent shape over an opaque one would punch a hole instead of mixing.
    Compositing through a scratch layer keeps glows and blushes translucent.
    """
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=fill)
    image.alpha_composite(layer)


# ---------------------------------------------------------------------------
# Portraits: four 100x148 frames
# ---------------------------------------------------------------------------

def portrait_frame(base: Image.Image) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    frame = base.copy()
    return frame, ImageDraw.Draw(frame)


def portrait_border(image: Image.Image) -> None:
    d = ImageDraw.Draw(image)
    # Stepped pixel border keeps every portrait feeling like a card.
    d.rectangle([0, 0, 99, 147], outline=(26, 30, 52, 255), width=2)
    d.rectangle([2, 2, 97, 145], outline=(116, 182, 224, 255))
    for x, y in ((0, 0), (96, 0), (0, 144), (96, 144)):
        d.rectangle([x, y, x + 3, y + 3], outline=(26, 30, 52, 255))


def portrait_wall(top, bottom, accent, floor, panels=()):
    frame = new(100, 148)
    d = ImageDraw.Draw(frame)
    d.rectangle([0, 0, 99, 147], fill=bottom)
    d.rectangle([0, 0, 99, 96], fill=top)
    for x0, y0, x1, y1 in panels:
        d.rectangle([x0, y0, x1, y1], fill=accent)
    d.rectangle([0, 122, 99, 147], fill=floor)
    highlight = tuple(min(255, c + 26) for c in floor[:3]) + (255,)
    d.line([(0, 122), (99, 122)], fill=highlight)
    return frame


def eye(d, cx, cy, iris, blink=False, w=11, h=13, lash=True):
    if blink:
        d.rectangle([cx - w // 2, cy, cx + w // 2, cy + 1], fill=INK)
        return
    d.ellipse([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], fill=WHITE)
    d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=iris)
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=INK)
    d.rectangle([cx - 3, cy - 4, cx - 2, cy - 3], fill=WHITE)
    if lash:
        d.line([(cx - w // 2, cy - h // 2 + 1), (cx + w // 2, cy - h // 2 + 1)],
               fill=INK)


def mouth(d, cx, cy, open_mouth=False, smile=True):
    if open_mouth:
        d.ellipse([cx - 9, cy - 4, cx + 9, cy + 8], fill=(74, 38, 44, 255),
                  outline=INK)
        d.ellipse([cx - 5, cy + 2, cx + 5, cy + 7], fill=PINK_DARK)
        d.rectangle([cx - 7, cy - 3, cx + 7, cy - 1], fill=WHITE)
    elif smile:
        d.arc([cx - 9, cy - 5, cx + 9, cy + 5], 20, 160, fill=INK, width=2)
    else:
        d.line([(cx - 7, cy + 1), (cx + 7, cy + 1)], fill=INK, width=2)


def priya_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((232, 246, 238, 255), (210, 234, 228, 255),
                          (196, 224, 216, 255), (176, 200, 192, 255),
                          panels=((8, 10, 46, 34),))
    d = ImageDraw.Draw(frame)

    # wall details: framed certificate and a shelf jar
    d.rectangle([10, 12, 44, 34], fill=(214, 232, 226, 255), outline=INK_SOFT)
    d.rectangle([13, 15, 41, 31], fill=(246, 248, 238, 255))
    d.line([(16, 19), (38, 19)], fill=(170, 196, 188, 255))
    d.line([(16, 23), (34, 23)], fill=(170, 196, 188, 255))
    d.line([(16, 27), (30, 27)], fill=(170, 196, 188, 255))
    d.rectangle([74, 16, 88, 40], fill=(164, 214, 206, 255), outline=INK_SOFT)
    d.rectangle([77, 19, 85, 22], fill=TEAL_DARK)

    # shoulders / teal scrubs
    d.ellipse([10, 112, 90, 174], fill=TEAL_DARK)
    d.polygon([(16, 148), (24, 120), (76, 120), (84, 148)], fill=TEAL)
    d.polygon([(30, 120), (50, 134), (70, 120), (64, 116), (36, 116)], fill=CREAM)
    d.polygon([(38, 134), (50, 148), (62, 134), (50, 142)], fill=(58, 140, 134, 255))
    # ID badge
    d.rectangle([66, 130, 82, 142], fill=(226, 240, 238, 255), outline=INK_SOFT)
    d.rectangle([69, 133, 79, 135], fill=TEAL_DARK)
    d.rectangle([69, 138, 77, 139], fill=(150, 176, 172, 255))

    # neck and ears
    d.rectangle([42, 94, 58, 118], fill=SKIN_SHADOW)
    d.rectangle([44, 94, 56, 114], fill=SKIN)
    d.ellipse([23, 56, 31, 74], fill=SKIN)
    d.ellipse([69, 56, 77, 74], fill=SKIN)

    # hair back
    d.ellipse([20, 22, 80, 104], fill=BROWN)
    d.polygon([(20, 54), (28, 50), (29, 104), (20, 100)], fill=BROWN)
    d.polygon([(72, 50), (80, 54), (80, 100), (71, 104)], fill=BROWN)
    # low bun peeking out behind the jaw
    d.ellipse([70, 64, 84, 82], fill=BROWN, outline=BROWN_LIGHT)
    d.arc([73, 67, 81, 79], 210, 330, fill=BROWN_LIGHT)

    # face
    d.ellipse([28, 28, 72, 98], fill=SKIN)
    d.ellipse([31, 31, 69, 92], fill=SKIN_LIGHT)
    d.arc([30, 46, 70, 100], 20, 160, fill=SKIN_SHADOW, width=2)

    # side-swept fringe
    d.polygon([(27, 44), (29, 26), (41, 18), (59, 18), (71, 30), (71, 44),
               (62, 37), (47, 34), (36, 38)], fill=BROWN)
    d.polygon([(31, 41), (34, 28), (44, 22), (56, 23), (57, 30),
               (45, 29), (38, 34)], fill=BROWN_LIGHT)

    # eyebrows
    d.line([(34, 51), (46, 49)], fill=BROWN)
    d.line([(54, 49), (66, 51)], fill=BROWN)

    eye(d, 40, 61, (104, 68, 44, 255), blink)
    eye(d, 60, 61, (104, 68, 44, 255), blink)

    # thin round glasses
    d.ellipse([31, 51, 49, 71], outline=(54, 44, 46, 255))
    d.ellipse([51, 51, 69, 71], outline=(54, 44, 46, 255))
    d.line([(49, 60), (51, 60)], fill=(54, 44, 46, 255))

    # nose and mouth
    d.line([(50, 70), (48, 78), (52, 79)], fill=SKIN_SHADOW)
    soft(frame, [35, 76, 43, 82], (234, 154, 142, 120))
    soft(frame, [57, 76, 65, 82], (234, 154, 142, 120))
    mouth(d, 50, 87, open_mouth=talking)

    portrait_border(frame)
    return frame


def mehta_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((226, 238, 224, 255), (204, 222, 204, 255),
                          (190, 214, 194, 255), (170, 190, 174, 255),
                          panels=((62, 10, 94, 40),))
    d = ImageDraw.Draw(frame)

    # wall details: framed photo and a small plant
    d.rectangle([64, 12, 92, 38], fill=(196, 212, 194, 255), outline=INK_SOFT)
    d.rectangle([68, 16, 88, 34], fill=(240, 244, 226, 255))
    d.ellipse([74, 20, 84, 30], fill=(176, 206, 174, 255))
    d.rectangle([8, 92, 22, 122], fill=(142, 122, 84, 255))
    d.rectangle([10, 94, 20, 120], fill=(166, 144, 100, 255))
    for x, y in ((9, 84), (14, 78), (19, 86)):
        d.ellipse([x - 4, y - 5, x + 4, y + 5], fill=(118, 168, 116, 255))

    # cardigan / shirt
    d.ellipse([8, 112, 92, 176], fill=(154, 120, 42, 255))
    d.polygon([(14, 148), (26, 118), (74, 118), (86, 148)], fill=(196, 156, 66, 255))
    d.polygon([(34, 116), (50, 138), (66, 116), (58, 112), (42, 112)], fill=WHITE)
    d.polygon([(42, 134), (50, 148), (58, 134), (50, 140)], fill=(208, 172, 84, 255))
    d.line([(50, 138), (50, 148)], fill=(122, 94, 36, 255))
    for y in (128, 137):
        d.ellipse([48, y, 52, y + 4], fill=(128, 98, 38, 255))

    # neck and ears
    d.rectangle([42, 94, 58, 118], fill=SKIN_SHADOW)
    d.rectangle([44, 94, 56, 114], fill=SKIN)
    d.ellipse([22, 56, 31, 76], fill=SKIN)
    d.ellipse([69, 56, 78, 76], fill=SKIN)

    # grey hair
    d.ellipse([24, 22, 76, 96], fill=GREY)
    d.ellipse([28, 24, 72, 90], fill=GREY_LIGHT)
    d.polygon([(26, 44), (34, 28), (58, 22), (74, 32), (72, 44),
               (58, 36), (44, 40), (34, 36)], fill=GREY)
    d.line([(30, 46), (38, 30)], fill=(198, 200, 198, 255))

    # face with age lines
    d.ellipse([28, 28, 72, 98], fill=SKIN)
    d.ellipse([31, 31, 69, 92], fill=(232, 184, 148, 255))
    d.arc([30, 46, 70, 100], 20, 160, fill=SKIN_SHADOW, width=2)
    d.line([(36, 44), (44, 44)], fill=SKIN_SHADOW)
    d.line([(56, 44), (64, 44)], fill=SKIN_SHADOW)
    d.line([(36, 84), (42, 86)], fill=SKIN_SHADOW)
    d.line([(58, 86), (64, 84)], fill=SKIN_SHADOW)

    # bushy brows
    d.polygon([(33, 50), (47, 47), (47, 51), (35, 53)], fill=GREY)
    d.polygon([(53, 47), (67, 50), (65, 53), (53, 51)], fill=GREY)

    eye(d, 40, 61, (74, 62, 48, 255), blink)
    eye(d, 60, 61, (74, 62, 48, 255), blink)

    # rectangular glasses
    d.rectangle([30, 51, 49, 70], outline=(60, 54, 52, 255))
    d.rectangle([51, 51, 70, 70], outline=(60, 54, 52, 255))
    d.line([(49, 58), (51, 58)], fill=(60, 54, 52, 255))

    # nose and moustache-free mouth
    d.line([(50, 70), (47, 79), (52, 80)], fill=SKIN_SHADOW)
    mouth(d, 50, 87, open_mouth=talking, smile=False)
    d.line([(41, 84), (45, 86)], fill=SKIN_SHADOW)
    d.line([(55, 86), (59, 84)], fill=SKIN_SHADOW)

    portrait_border(frame)
    return frame


def blueshirt_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((176, 218, 246, 255), (206, 232, 248, 255),
                          (226, 242, 252, 255), (172, 196, 186, 255))
    d = ImageDraw.Draw(frame)

    # sky and clouds
    for x, y, r in ((18, 22, 8), (30, 24, 6), (74, 34, 9), (62, 30, 6),
                    (26, 60, 6), (84, 70, 7)):
        d.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=(250, 252, 250, 255))

    # shoulders / blue top
    d.ellipse([8, 112, 92, 176], fill=BLUE_DARK)
    d.polygon([(14, 148), (22, 120), (78, 120), (86, 148)], fill=BLUE)
    d.polygon([(34, 118), (50, 136), (66, 118), (58, 114), (42, 114)], fill=BLUE_LIGHT)
    d.polygon([(42, 136), (50, 148), (58, 136), (50, 142)], fill=(56, 104, 164, 255))

    # neck and ears
    d.rectangle([42, 94, 58, 118], fill=SKIN_SHADOW)
    d.rectangle([44, 94, 56, 114], fill=SKIN)
    d.ellipse([23, 56, 31, 74], fill=SKIN)
    d.ellipse([69, 56, 77, 74], fill=SKIN)

    # long brown hair
    d.ellipse([18, 18, 82, 100], fill=BROWN)
    d.polygon([(18, 48), (27, 44), (28, 118), (18, 114)], fill=BROWN)
    d.polygon([(73, 44), (82, 48), (82, 114), (72, 118)], fill=BROWN)
    d.polygon([(24, 50), (28, 30), (50, 20), (74, 30), (78, 50),
               (70, 40), (60, 44), (50, 36), (40, 44), (30, 40)], fill=BROWN)

    # face
    d.ellipse([28, 28, 72, 98], fill=SKIN)
    d.ellipse([31, 31, 69, 92], fill=SKIN_LIGHT)
    d.arc([30, 46, 70, 100], 20, 160, fill=SKIN_SHADOW, width=2)

    # side fringe
    d.polygon([(27, 42), (34, 24), (52, 19), (66, 26), (60, 34),
               (48, 36), (38, 34)], fill=BROWN)
    d.polygon([(31, 40), (38, 27), (50, 24), (58, 30), (50, 32),
               (42, 37)], fill=BROWN_LIGHT)

    # brows
    d.line([(34, 51), (46, 49)], fill=BROWN)
    d.line([(54, 49), (66, 51)], fill=BROWN)

    eye(d, 40, 61, (92, 60, 40, 255), blink)
    eye(d, 60, 61, (92, 60, 40, 255), blink)

    # nose and mouth
    d.line([(50, 70), (48, 78), (52, 79)], fill=SKIN_SHADOW)
    d.ellipse([35, 76, 43, 82], fill=(234, 154, 142, 255))
    d.ellipse([57, 76, 65, 82], fill=(234, 154, 142, 255))
    mouth(d, 50, 87, open_mouth=talking)

    portrait_border(frame)
    return frame


def blorb_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((226, 218, 244, 255), (208, 200, 230, 255),
                          (194, 186, 220, 255), (160, 154, 190, 255))

    d = ImageDraw.Draw(frame)
    # bathroom mirror behind the blob
    d.rectangle([10, 12, 90, 96], fill=(150, 146, 186, 255), outline=INK_SOFT)
    d.rectangle([14, 16, 86, 92], fill=(186, 206, 226, 255))
    d.polygon([(18, 88), (18, 20), (32, 20)], fill=(216, 230, 242, 255))
    d.polygon([(60, 88), (82, 88), (82, 26)], fill=(206, 222, 238, 255))
    d.rectangle([10, 96, 90, 100], fill=(122, 116, 160, 255))

    # sugar body
    d.ellipse([14, 28, 86, 148], fill=MINT_DARK)
    d.ellipse([18, 30, 82, 142], fill=MINT)
    d.ellipse([23, 34, 58, 86], fill=MINT_LIGHT)
    d.arc([20, 88, 82, 148], 20, 160, fill=(88, 158, 132, 255), width=2)
    # drips
    for x, y, w, h in ((20, 132, 12, 14), (40, 138, 10, 10), (64, 130, 12, 16)):
        d.ellipse([x, y, x + w, y + h], fill=MINT_DARK)
        d.ellipse([x + 1, y, x + w - 1, y + h - 1], fill=MINT)
    # sugar spots
    for x, y, r in ((30, 44, 4), (66, 56, 5), (28, 104, 5), (70, 100, 4)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=(104, 182, 154, 255))
        d.ellipse([x - r + 1, y - r + 1, x + r - 1, y + r - 1],
                  fill=(160, 224, 200, 255))

    # face
    eye(d, 37, 70, (44, 76, 66, 255), blink, w=15, h=17)
    eye(d, 63, 70, (44, 76, 66, 255), blink, w=15, h=17)
    d.polygon([(28, 57), (45, 54), (44, 58), (30, 61)], fill=(64, 116, 98, 255))
    d.polygon([(55, 54), (72, 57), (70, 61), (56, 58)], fill=(64, 116, 98, 255))
    soft(frame, [28, 88, 40, 96], (232, 144, 136, 120))
    soft(frame, [60, 88, 72, 96], (232, 144, 136, 120))
    mouth(d, 50, 100, open_mouth=talking)
    # little arms resting at the sides; the mirror stays in the background
    d.ellipse([6, 108, 20, 122], fill=MINT, outline=MINT_DARK)
    d.ellipse([80, 108, 94, 122], fill=MINT, outline=MINT_DARK)
    d.rectangle([10, 112, 14, 118], fill=MINT_LIGHT)
    d.rectangle([86, 112, 90, 118], fill=MINT_LIGHT)

    portrait_border(frame)
    return frame


def wobble_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((246, 228, 196, 255), (232, 208, 168, 255),
                          (240, 216, 178, 255), (196, 156, 108, 255))

    d = ImageDraw.Draw(frame)
    # bakery awning
    for i in range(0, 100, 16):
        d.rectangle([i, 8, i + 8, 22], fill=(206, 92, 78, 255))
        d.rectangle([i + 8, 8, i + 16, 22], fill=(248, 226, 196, 255))
    d.rectangle([0, 22, 99, 24], fill=(150, 98, 62, 255))
    # shelf loaves
    d.rectangle([6, 40, 94, 44], fill=WOOD_DARK)
    for x, w in ((12, 18), (36, 22), (64, 20)):
        d.ellipse([x, 31, x + w, 43], fill=(214, 156, 92, 255), outline=(150, 98, 58, 255))
        d.line([(x + 4, 34), (x + w - 6, 34)], fill=(244, 206, 150, 255))
    # flour dust
    for x, y in ((18, 60), (78, 62), (26, 84), (86, 88), (50, 48)):
        d.point((x, y), fill=(255, 250, 238, 255))

    # tooth body: rounded crown over two roots
    d.ellipse([20, 46, 80, 128], fill=IVORY_SHADOW)
    d.ellipse([23, 48, 77, 124], fill=IVORY)
    d.ellipse([29, 52, 56, 96], fill=IVORY_LIGHT)
    d.rectangle([32, 112, 44, 146], fill=IVORY_SHADOW)
    d.rectangle([34, 112, 42, 146], fill=IVORY)
    d.rectangle([56, 112, 68, 146], fill=IVORY_SHADOW)
    d.rectangle([58, 112, 66, 146], fill=IVORY)

    # apron sits below the mouth so the face stays clear
    d.polygon([(28, 100), (72, 100), (80, 146), (20, 146)], fill=PINK, outline=PINK_DARK)
    d.polygon([(38, 100), (44, 94), (56, 94), (62, 100)], fill=(238, 178, 178, 255))
    d.rectangle([44, 116, 56, 132], fill=(240, 186, 184, 255), outline=PINK_DARK)
    d.line([(46, 120), (54, 120)], fill=PINK_DARK)
    d.line([(46, 126), (54, 126)], fill=PINK_DARK)

    # chef hat: one puffy silhouette with a band across the brow
    d.polygon([(26, 44), (21, 30), (26, 18), (37, 12), (46, 11),
               (52, 10), (64, 12), (74, 19), (78, 30), (73, 44)],
              fill=WHITE, outline=INK)
    d.rectangle([26, 38, 74, 50], fill=WHITE, outline=INK)
    d.line([(30, 42), (70, 42)], fill=(226, 218, 202, 255))
    d.line([(30, 46), (70, 46)], fill=(242, 236, 222, 255))
    d.line([(34, 22), (36, 34)], fill=(232, 226, 212, 255))
    d.line([(60, 20), (62, 34)], fill=(232, 226, 212, 255))

    # face
    d.line([(31, 59), (42, 57)], fill=INK)
    d.line([(58, 57), (69, 59)], fill=INK)
    eye(d, 39, 68, (72, 60, 46, 255), blink)
    eye(d, 61, 68, (72, 60, 46, 255), blink)
    soft(frame, [28, 81, 38, 88], (236, 150, 146, 120))
    soft(frame, [62, 81, 72, 88], (236, 150, 146, 120))
    d.line([(50, 78), (47, 84), (51, 85)], fill=(198, 178, 146, 255))
    mouth(d, 50, 91, open_mouth=talking)

    # little chef arm with a wooden spoon
    d.ellipse([74, 104, 90, 118], fill=IVORY, outline=IVORY_SHADOW)
    d.line([(84, 108), (91, 122)], fill=WOOD_DARK, width=3)
    d.ellipse([86, 118, 96, 128], fill=WOOD, outline=WOOD_DARK)

    portrait_border(frame)
    return frame


def gloam_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((70, 62, 104, 255), (58, 52, 88, 255),
                          (82, 72, 118, 255), (44, 40, 72, 255))
    d = ImageDraw.Draw(frame)

    # tea stall backdrop: warm lantern glow on the wall
    soft(frame, [68, 18, 94, 44], (255, 196, 96, 18))
    soft(frame, [74, 24, 88, 38], (255, 214, 130, 26))
    d.rectangle([0, 112, 99, 118], fill=WOOD_DARK)
    d.rectangle([0, 118, 99, 147], fill=WOOD)
    d.line([(0, 120), (99, 120)], fill=WOOD_LIGHT)
    # smoke tail
    d.polygon([(34, 104), (66, 104), (62, 146), (38, 146)], fill=DUSK_DARK)
    d.line([(40, 108), (42, 144)], fill=INK)
    d.line([(60, 108), (58, 144)], fill=INK)
    d.arc([36, 126, 50, 144], 180, 360, fill=DUSK_LIGHT)
    d.arc([52, 124, 66, 142], 180, 360, fill=DUSK_LIGHT)

    # body
    d.ellipse([18, 34, 82, 122], fill=DUSK, outline=DUSK_DARK, width=2)
    d.ellipse([23, 38, 73, 112], fill=DUSK_LIGHT)
    d.arc([24, 66, 78, 124], 20, 160, fill=DUSK_DARK, width=2)
    # rim light
    d.arc([22, 38, 70, 112], 80, 160, fill=(174, 170, 222, 255))

    # tea cup on the counter to the right, clear of the body
    d.rectangle([80, 100, 92, 110], fill=CREAM, outline=INK_SOFT)
    d.arc([91, 101, 97, 109], 270, 90, fill=INK_SOFT)
    d.rectangle([82, 102, 90, 103], fill=(214, 206, 186, 255))
    d.line([(84, 96), (83, 100)], fill=(214, 206, 186, 255))
    d.line([(88, 94), (87, 100)], fill=(214, 206, 186, 255))

    # flame crown: a teardrop with a soft core
    d.polygon([(50, 0), (58, 14), (61, 24), (57, 33), (50, 36),
               (43, 33), (39, 24), (42, 14)],
              fill=AMBER_DARK, outline=INK)
    d.polygon([(50, 5), (55, 17), (58, 25), (54, 31), (50, 33),
               (46, 31), (42, 25), (45, 17)], fill=AMBER)
    d.polygon([(50, 13), (53, 22), (54, 27), (50, 30), (46, 27),
               (47, 22)], fill=AMBER_LIGHT)

    # tired amber eyes
    if blink:
        d.line([(33, 69), (43, 69)], fill=INK, width=2)
        d.line([(57, 69), (67, 69)], fill=INK, width=2)
    else:
        d.ellipse([32, 64, 44, 76], fill=AMBER, outline=INK)
        d.ellipse([56, 64, 68, 76], fill=AMBER, outline=INK)
        d.ellipse([36, 68, 40, 72], fill=INK)
        d.ellipse([60, 68, 64, 72], fill=INK)
        d.rectangle([34, 65, 36, 67], fill=AMBER_LIGHT)
        d.rectangle([58, 65, 60, 67], fill=AMBER_LIGHT)
    # worried brows: inner corners raised
    d.line([(31, 61), (44, 58)], fill=INK)
    d.line([(56, 58), (69, 61)], fill=INK)

    # cheeks and mouth
    soft(frame, [26, 81, 36, 88], (126, 108, 170, 120))
    soft(frame, [64, 81, 74, 88], (126, 108, 170, 120))
    mouth(d, 50, 92, open_mouth=talking, smile=False)

    # hands holding the curing light at the waist, face left clear
    d.ellipse([26, 106, 39, 119], fill=DUSK, outline=DUSK_DARK)
    d.ellipse([61, 106, 74, 119], fill=DUSK, outline=DUSK_DARK)
    soft(frame, [36, 98, 64, 122], (255, 214, 130, 26))
    d.rectangle([46, 116, 54, 138], fill=IRON, outline=INK)
    d.rectangle([38, 106, 62, 116], fill=AMBER, outline=AMBER_DARK)
    d.rectangle([42, 108, 58, 111], fill=AMBER_LIGHT)

    portrait_border(frame)
    return frame


def rattle_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((40, 92, 90, 255), (34, 78, 78, 255),
                          (48, 110, 104, 255), (28, 60, 62, 255))
    d = ImageDraw.Draw(frame)

    # X-ray film frame behind the skeleton
    d.rectangle([8, 10, 92, 132], fill=(24, 48, 48, 255), outline=IRON)
    d.rectangle([12, 14, 88, 128], outline=CYAN_DARK)
    d.rectangle([16, 18, 84, 124], outline=(62, 146, 138, 255))
    for x, y in ((9, 11), (87, 11), (9, 127), (87, 127)):
        d.rectangle([x, y, x + 3, y + 3], fill=IRON_LIGHT)
    # faint ribs on the film
    for y in (44, 54, 64):
        d.arc([24, y - 6, 76, y + 6], 200, 340, fill=(58, 138, 130, 255))

    # collarbones, spine and ribcage
    d.line([(34, 94), (48, 98)], fill=BONE_SHADOW, width=2)
    d.line([(66, 94), (52, 98)], fill=BONE_SHADOW, width=2)
    d.rectangle([46, 96, 54, 140], fill=BONE_SHADOW, outline=INK)
    for y, w in ((104, 28), (114, 32), (124, 28)):
        d.arc([50 - w, y - 8, 50 + w, y + 8], 200, 340, fill=BONE, width=4)
        d.arc([50 - w, y - 8, 50 + w, y + 8], 200, 340, fill=INK, width=1)
    d.polygon([(30, 134), (46, 128), (54, 128), (70, 134), (64, 144), (36, 144)],
              fill=BONE_SHADOW, outline=INK)

    # skull: wide cranium, narrow jaw, hollow cheeks
    d.ellipse([24, 16, 76, 70], fill=BONE, outline=INK, width=2)
    d.ellipse([28, 20, 72, 64], fill=BONE_LIGHT)
    d.arc([28, 40, 72, 72], 20, 160, fill=BONE_SHADOW, width=2)
    d.polygon([(34, 58), (38, 76), (45, 86), (50, 92),
               (57, 86), (64, 76), (68, 58)],
              fill=BONE, outline=INK)
    d.polygon([(38, 62), (41, 76), (47, 84), (53, 84), (61, 76), (64, 62)],
              fill=BONE_LIGHT)
    d.ellipse([31, 68, 42, 80], fill=(222, 214, 186, 255))
    d.ellipse([58, 68, 69, 80], fill=(222, 214, 186, 255))

    # eye sockets with teal glow
    if blink:
        d.rectangle([31, 49, 45, 51], fill=INK)
        d.rectangle([55, 49, 69, 51], fill=INK)
    else:
        d.ellipse([30, 42, 46, 60], fill=(22, 58, 56, 255), outline=INK)
        d.ellipse([54, 42, 70, 60], fill=(22, 58, 56, 255), outline=INK)
        d.ellipse([35, 48, 41, 54], fill=CYAN)
        d.ellipse([59, 48, 65, 54], fill=CYAN)
        d.rectangle([36, 49, 37, 50], fill=WHITE)
        d.rectangle([60, 49, 61, 50], fill=WHITE)

    # nose
    d.polygon([(45, 62), (55, 62), (50, 71)], fill=(20, 54, 52, 255), outline=INK)

    # teeth row
    d.rectangle([38, 74, 62, 84], fill=(234, 228, 206, 255), outline=INK)
    for x in (43, 48, 53, 58):
        d.line([(x, 74), (x, 84)], fill=INK)
    if talking:
        d.ellipse([38, 82, 62, 96], fill=(20, 48, 46, 255), outline=INK)
        d.ellipse([43, 88, 57, 94], fill=PINK_DARK)
    else:
        d.line([(39, 87), (61, 87)], fill=INK)

    # teal bow tie
    d.polygon([(32, 90), (46, 94), (32, 102)], fill=TEAL, outline=TEAL_DARK)
    d.polygon([(68, 90), (54, 94), (68, 102)], fill=TEAL, outline=TEAL_DARK)
    d.rectangle([46, 92, 54, 100], fill=TEAL_LIGHT, outline=TEAL_DARK)

    # hand holding a film
    d.ellipse([70, 108, 88, 124], fill=BONE, outline=INK)
    d.rectangle([68, 94, 94, 112], fill=(26, 58, 56, 255), outline=CYAN)
    d.ellipse([76, 98, 88, 110], fill=CYAN)
    d.ellipse([78, 100, 86, 108], fill=(26, 58, 56, 255))

    portrait_border(frame)
    return frame


def mildew_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((96, 120, 102, 255), (78, 100, 86, 255),
                          (114, 142, 116, 255), (72, 92, 78, 255))
    d = ImageDraw.Draw(frame)

    # damp stone wall: mortar lines and moss creeping between the blocks
    for y in (18, 40, 62, 84):
        d.line([(0, y), (99, y)], fill=(62, 82, 70, 255))
    for x, y in ((16, 26), (44, 48), (70, 30), (84, 70)):
        d.ellipse([x - 5, y - 4, x + 5, y + 4], fill=(88, 124, 82, 255))
    # dripping pipe and a rusty valve behind Mildew
    d.rectangle([78, 4, 84, 54], fill=IRON, outline=INK)
    d.rectangle([74, 12, 90, 18], fill=IRON_LIGHT, outline=INK)
    d.ellipse([76, 8, 88, 20], fill=IRON, outline=INK)
    d.arc([77, 9, 87, 19], 30, 300, fill=IRON_LIGHT)
    d.rectangle([80, 54, 82, 66], fill=(112, 176, 128, 255))
    for y in (60, 88):
        d.ellipse([74, y, 94, y + 8], fill=(74, 96, 82, 255))
    # a mug of something warm on a crate
    d.rectangle([6, 104, 28, 130], fill=WOOD_DARK, outline=INK)
    d.rectangle([8, 106, 26, 128], fill=WOOD)
    d.rectangle([10, 110, 18, 120], fill=CREAM, outline=WOOD_DARK)
    d.arc([18, 111, 24, 119], 270, 90, fill=WOOD_DARK)
    d.line([(12, 106), (11, 110)], fill=(220, 230, 210, 255))

    # mold body: soft lump with dripping edges
    d.ellipse([10, 60, 90, 170], fill=INK)
    d.ellipse([12, 62, 88, 166], fill=MOLD_DARK)
    d.ellipse([16, 66, 84, 158], fill=MOLD)
    d.ellipse([23, 72, 62, 124], fill=MOLD_LIGHT)
    d.arc([18, 112, 82, 160], 20, 160, fill=(70, 94, 62, 255), width=2)
    # drips along the bottom
    for x, y, w, h in ((18, 142, 14, 18), (42, 148, 12, 14), (66, 140, 14, 20)):
        d.ellipse([x, y, x + w, y + h], fill=MOLD_DARK)
        d.ellipse([x + 1, y, x + w - 1, y + h - 1], fill=MOLD_SLIME)
    # fuzzy spores on the shoulders
    for x, y in ((20, 78), (74, 74), (14, 104), (82, 108), (28, 128),
                 (70, 126), (26, 58), (66, 56)):
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=MOLD_LIGHT)
        d.rectangle([x, y - 4, x + 1, y - 2], fill=(206, 228, 170, 255))

    # folded towel hat: Mildew likes the warm damp
    d.polygon([(28, 58), (50, 48), (72, 58), (68, 66), (32, 66)], fill=INK)
    d.polygon([(30, 58), (50, 50), (70, 58), (67, 63), (33, 63)], fill=CREAM)
    d.line([(33, 60), (67, 60)], fill=(214, 198, 168, 255))
    d.rectangle([46, 50, 54, 56], fill=PINK, outline=PINK_DARK)

    # tired, kind eyes
    d.ellipse([26, 80, 44, 98], fill=WHITE, outline=INK)
    d.ellipse([56, 80, 74, 98], fill=WHITE, outline=INK)
    if blink:
        d.rectangle([29, 88, 41, 91], fill=INK)
        d.rectangle([59, 88, 71, 91], fill=INK)
    else:
        d.ellipse([31, 84, 39, 94], fill=(54, 86, 56, 255))
        d.ellipse([61, 84, 69, 94], fill=(54, 86, 56, 255))
        d.ellipse([33, 86, 36, 90], fill=INK)
        d.ellipse([63, 86, 66, 90], fill=INK)
        d.rectangle([32, 83, 35, 85], fill=WHITE)
        d.rectangle([62, 83, 65, 85], fill=WHITE)
    # heavy eyelids
    d.line([(26, 80), (44, 82)], fill=INK)
    d.line([(56, 82), (74, 80)], fill=INK)
    # eyebrows droop outward
    d.line([(25, 73), (43, 76)], fill=MOLD_DARK)
    d.line([(57, 76), (75, 73)], fill=MOLD_DARK)

    # nose and a wobbly mouth
    d.line([(50, 96), (47, 104), (52, 105)], fill=(64, 88, 56, 255))
    if talking:
        d.ellipse([39, 108, 61, 124], fill=(52, 72, 46, 255), outline=INK)
        d.ellipse([44, 116, 56, 122], fill=PINK_DARK)
    else:
        d.arc([40, 106, 60, 120], 20, 160, fill=INK, width=2)
    soft(frame, [28, 104, 38, 112], (210, 160, 150, 110))
    soft(frame, [62, 104, 72, 112], (210, 160, 150, 110))

    # little hands holding a scrub brush
    d.ellipse([12, 126, 30, 142], fill=MOLD, outline=MOLD_DARK)
    d.ellipse([70, 126, 88, 142], fill=MOLD, outline=MOLD_DARK)
    d.rectangle([70, 112, 94, 124], fill=WOOD, outline=WOOD_DARK)
    d.rectangle([72, 108, 92, 114], fill=CREAM, outline=WOOD_DARK)
    for x in range(74, 92, 5):
        d.line([(x, 108), (x, 102)], fill=(226, 220, 200, 255))

    # spores floating in the damp air
    for x, y in ((18, 34), (84, 42), (12, 50), (90, 90)):
        d.rectangle([x, y, x + 1, y + 1], fill=(196, 222, 160, 255))

    portrait_border(frame)
    return frame


def redtape_frame(expr: int) -> Image.Image:
    blink = expr in (1, 3)
    talking = expr in (2, 3)
    frame = portrait_wall((240, 226, 206, 255), (224, 208, 188, 255),
                          (250, 240, 220, 255), (196, 178, 156, 255))
    d = ImageDraw.Draw(frame)

    # filing shelves and folders behind Redtape
    d.rectangle([4, 12, 96, 60], fill=WOOD_DARK, outline=INK)
    for shelf_y in (28, 46):
        d.line([(6, shelf_y), (94, shelf_y)], fill=WOOD)
    for x, color in ((8, (204, 168, 96, 255)), (20, (186, 148, 86, 255)),
                     (32, (214, 180, 110, 255)), (64, (198, 162, 94, 255)),
                     (76, (178, 140, 80, 255))):
        d.rectangle([x, 14, x + 8, 27], fill=color, outline=INK_SOFT)
        d.rectangle([x + 2, 18, x + 6, 20], fill=CREAM)
    # a big red stamp on the wall
    d.rectangle([66, 64, 94, 92], outline=RED_TAPE_DARK)
    d.rectangle([69, 67, 91, 89], outline=RED_TAPE)
    d.line([(72, 74), (88, 74)], fill=RED_TAPE, width=2)
    d.line([(72, 80), (84, 80)], fill=RED_TAPE, width=2)
    d.line([(76, 84), (88, 84)], fill=RED_TAPE, width=2)
    # potted plant: the flower shop next door
    d.rectangle([6, 112, 22, 140], fill=(154, 110, 74, 255), outline=INK)
    for x, y in ((8, 102), (14, 96), (20, 104)):
        d.ellipse([x - 5, y - 6, x + 5, y + 4], fill=(118, 168, 116, 255))

    # stack of paper body with jagged edges
    d.polygon([(14, 66), (86, 66), (90, 152), (82, 146), (76, 154),
               (68, 148), (60, 156), (52, 148), (44, 156), (36, 148),
               (28, 154), (20, 146), (10, 152)], fill=INK)
    d.polygon([(16, 68), (84, 68), (88, 150), (80, 144), (74, 151),
               (66, 145), (58, 152), (50, 145), (42, 152), (34, 145),
               (26, 151), (18, 144), (12, 150)], fill=PAPER)
    d.polygon([(20, 70), (80, 70), (82, 104), (20, 104)], fill=IVORY_LIGHT)
    # ruled lines
    for y in (78, 86, 94):
        d.line([(24, y), (78, y)], fill=(210, 198, 178, 255))
    # red tape bands
    d.rectangle([12, 108, 90, 118], fill=RED_TAPE_DARK)
    d.rectangle([13, 109, 89, 116], fill=RED_TAPE)
    d.line([(16, 111), (86, 111)], fill=RED_TAPE_LIGHT)
    d.polygon([(12, 126), (90, 136), (90, 144), (12, 134)], fill=RED_TAPE_DARK)
    d.polygon([(13, 127), (89, 137), (89, 142), (13, 132)], fill=RED_TAPE)
    d.line([(16, 130), (84, 139)], fill=RED_TAPE_LIGHT)

    # eyes: round glasses, very serious
    d.ellipse([24, 84, 48, 108], fill=WHITE, outline=INK)
    d.ellipse([56, 84, 80, 108], fill=WHITE, outline=INK)
    if blink:
        d.rectangle([28, 95, 44, 98], fill=INK)
        d.rectangle([60, 95, 76, 98], fill=INK)
    else:
        d.ellipse([33, 91, 41, 101], fill=(74, 62, 48, 255))
        d.ellipse([65, 91, 73, 101], fill=(74, 62, 48, 255))
        d.ellipse([35, 93, 38, 97], fill=INK)
        d.ellipse([67, 93, 70, 97], fill=INK)
        d.rectangle([34, 90, 37, 92], fill=WHITE)
        d.rectangle([66, 90, 69, 92], fill=WHITE)
    d.ellipse([23, 83, 49, 109], outline=(58, 46, 42, 255))
    d.ellipse([55, 83, 81, 109], outline=(58, 46, 42, 255))
    d.line([(48, 94), (56, 94)], fill=(58, 46, 42, 255))
    # angry brows
    d.polygon([(22, 78), (48, 84), (46, 88), (22, 82)], fill=INK)
    d.polygon([(58, 84), (82, 78), (82, 82), (60, 88)], fill=INK)

    # mouth and a paper-clip ear
    if talking:
        d.ellipse([40, 118, 62, 134], fill=(80, 60, 52, 255), outline=INK)
        d.ellipse([45, 126, 57, 132], fill=PINK_DARK)
    else:
        d.line([(40, 124), (62, 124)], fill=INK, width=2)
    d.rectangle([82, 96, 92, 108], fill=(206, 214, 218, 255), outline=INK_SOFT)

    # hands: one holds a stamp, one holds a folder
    d.ellipse([6, 128, 26, 146], fill=PAPER, outline=WOOD_DARK)
    d.ellipse([74, 128, 94, 146], fill=PAPER, outline=WOOD_DARK)
    d.rectangle([6, 112, 24, 128], fill=WOOD, outline=INK)
    d.rectangle([8, 114, 22, 120], fill=RED_TAPE)
    d.rectangle([10, 104, 20, 114], fill=WOOD_LIGHT, outline=WOOD_DARK)
    d.rectangle([72, 110, 96, 128], fill=CREAM, outline=WOOD_DARK)
    d.line([(76, 114), (92, 114)], fill=(198, 178, 150, 255))
    d.line([(76, 120), (88, 120)], fill=(198, 178, 150, 255))

    portrait_border(frame)
    return frame


# ---------------------------------------------------------------------------
# NPC world sheets: eight 32x32 frames (idle 0-3, walk 4-7)
# ---------------------------------------------------------------------------

def npc_frame(priya: bool, frame: int) -> Image.Image:
    im = new(32, 32)
    d = ImageDraw.Draw(im)
    walking = frame >= 4
    step = (frame - 4) % 2 if walking else 0
    bob = 1 if frame in (1, 3, 5, 7) else 0

    skin = SKIN if priya else (220, 174, 142, 255)
    hair = BROWN if priya else GREY
    hair_light = BROWN_LIGHT if priya else GREY_LIGHT
    shirt = TEAL if priya else (198, 158, 68, 255)
    shirt_dark = TEAL_DARK if priya else (154, 120, 42, 255)
    trousers = (62, 78, 98, 255) if priya else (96, 84, 70, 255)
    shoes = (240, 240, 236, 255) if priya else (70, 60, 54, 255)

    # legs
    leg_y = 23 + bob
    if walking:
        d.rectangle([11, leg_y, 14, 29], fill=trousers)
        d.rectangle([17, leg_y - (1 if step else 0), 20, 29], fill=trousers)
        d.rectangle([10, 29, 14, 30], fill=shoes)
        d.rectangle([17, 29, 21, 30], fill=shoes)
    else:
        d.rectangle([11, leg_y, 14, 29], fill=trousers)
        d.rectangle([17, leg_y, 20, 29], fill=trousers)
        d.rectangle([10, 29, 14, 30], fill=shoes)
        d.rectangle([17, 29, 21, 30], fill=shoes)

    # body
    d.rectangle([10, 16 + bob, 21, 24 + bob], fill=shirt_dark)
    d.rectangle([11, 16 + bob, 20, 23 + bob], fill=shirt)
    d.rectangle([8, 18 + bob, 10, 22 + bob], fill=shirt)
    d.rectangle([21, 18 + bob, 23, 22 + bob], fill=shirt)
    if priya:
        d.polygon([(14, 16 + bob), (16, 21 + bob), (18, 16 + bob)], fill=CREAM)
        d.rectangle([19, 19 + bob, 21, 22 + bob], fill=(222, 238, 234, 255))
    else:
        d.polygon([(13, 16 + bob), (16, 21 + bob), (19, 16 + bob)], fill=WHITE)
        d.rectangle([11, 21 + bob, 20, 23 + bob], fill=shirt_dark)

    # neck and head
    d.rectangle([14, 13 + bob, 17, 16 + bob], fill=SKIN_SHADOW)
    d.ellipse([8, 4 + bob, 23, 17 + bob], fill=skin)
    d.ellipse([10, 5 + bob, 21, 15 + bob], fill=(240, 194, 158, 255) if priya else (232, 186, 154, 255))

    # hair
    if priya:
        d.ellipse([8, 3 + bob, 23, 13 + bob], fill=hair)
        d.rectangle([8, 6 + bob, 10, 13 + bob], fill=hair)
        d.rectangle([21, 6 + bob, 22, 13 + bob], fill=hair)
        d.ellipse([20, 4 + bob, 24, 8 + bob], fill=hair)
        d.rectangle([11, 12 + bob, 20, 13 + bob], fill=hair_light)
    else:
        d.ellipse([8, 3 + bob, 23, 11 + bob], fill=hair)
        d.rectangle([8, 6 + bob, 10, 10 + bob], fill=hair)
        d.rectangle([21, 6 + bob, 22, 10 + bob], fill=hair)
        d.rectangle([11, 4 + bob, 21, 5 + bob], fill=hair_light)

    # eyes (glasses for both)
    d.rectangle([12, 9 + bob, 13, 10 + bob], fill=INK)
    d.rectangle([18, 9 + bob, 19, 10 + bob], fill=INK)
    if priya:
        d.rectangle([11, 8 + bob, 14, 11 + bob], outline=(54, 44, 46, 255))
        d.rectangle([17, 8 + bob, 20, 11 + bob], outline=(54, 44, 46, 255))
    else:
        d.rectangle([11, 8 + bob, 14, 11 + bob], outline=(58, 52, 50, 255))
        d.rectangle([17, 8 + bob, 20, 11 + bob], outline=(58, 52, 50, 255))
    d.line([(14, 9 + bob), (17, 9 + bob)], fill=(58, 52, 50, 255))
    d.rectangle([15, 12 + bob, 16, 12 + bob], fill=(160, 96, 84, 255))

    return im


# ---------------------------------------------------------------------------
# Villain world sprites: 64x64
# ---------------------------------------------------------------------------

def blorb_sprite() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    # shadow is supplied by villain.tscn, so keep the body floating slightly
    d.ellipse([6, 10, 58, 60], fill=INK)
    d.ellipse([8, 12, 56, 58], fill=MINT_DARK)
    d.ellipse([10, 14, 54, 56], fill=MINT)
    d.ellipse([14, 18, 38, 38], fill=MINT_LIGHT)
    d.arc([12, 38, 52, 60], 20, 160, fill=(84, 154, 130, 255), width=2)
    # drips
    for x, y, w, h in ((10, 50, 10, 12), (28, 54, 8, 8), (46, 50, 10, 12)):
        d.ellipse([x, y, x + w, y + h], fill=MINT_DARK)
        d.ellipse([x + 1, y, x + w - 1, y + h - 1], fill=MINT)
    # sugar spots
    for x, y, r in ((20, 22, 3), (44, 26, 4), (16, 42, 4), (46, 40, 3)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=(102, 178, 150, 255))
        d.ellipse([x - r + 1, y - r + 1, x + r - 1, y + r - 1], fill=(180, 234, 210, 255))
    # eyes
    for cx in (23, 41):
        d.ellipse([cx - 8, 22, cx + 8, 38], fill=WHITE, outline=INK)
        d.ellipse([cx - 4, 27, cx + 4, 35], fill=(44, 80, 68, 255))
        d.ellipse([cx - 2, 29, cx + 1, 32], fill=INK)
        d.rectangle([cx - 4, 26, cx - 2, 28], fill=WHITE)
    d.line([(16, 18), (28, 16)], fill=INK)
    d.line([(36, 16), (48, 18)], fill=INK)
    # mouth
    d.ellipse([25, 43, 40, 52], fill=(58, 100, 84, 255), outline=INK)
    d.ellipse([29, 48, 36, 51], fill=PINK_DARK)
    soft(im, [20, 42, 26, 46], (232, 150, 140, 120))
    soft(im, [39, 42, 45, 46], (232, 150, 140, 120))
    # hands: the mirror is held out to the right so the face stays readable
    d.ellipse([2, 38, 12, 48], fill=MINT, outline=MINT_DARK)
    d.ellipse([50, 38, 62, 50], fill=MINT, outline=MINT_DARK)
    d.rectangle([53, 44, 57, 57], fill=IRON, outline=INK)
    d.ellipse([48, 34, 62, 48], fill=(226, 236, 240, 255), outline=INK)
    d.ellipse([50, 36, 60, 46], fill=(180, 222, 238, 255))
    d.arc([51, 37, 57, 43], 200, 330, fill=WHITE)
    d.rectangle([53, 38, 54, 39], fill=WHITE)
    # sparkles
    for x, y in ((8, 26), (56, 32), (12, 36), (54, 18)):
        d.rectangle([x, y, x + 1, y + 1], fill=WHITE)
    return im


def wobble_sprite() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    # tooth roots and crown
    d.rectangle([20, 40, 30, 60], fill=INK)
    d.rectangle([34, 40, 44, 60], fill=INK)
    d.rectangle([22, 40, 28, 58], fill=IVORY_SHADOW)
    d.rectangle([36, 40, 42, 58], fill=IVORY_SHADOW)
    d.ellipse([10, 12, 54, 48], fill=INK)
    d.ellipse([12, 14, 52, 46], fill=IVORY)
    d.ellipse([16, 18, 40, 38], fill=IVORY_LIGHT)
    d.arc([14, 30, 50, 48], 20, 160, fill=IVORY_SHADOW, width=2)
    # chef hat: puffy top with a clean band
    d.polygon([(17, 15), (14, 9), (18, 4), (26, 1), (32, 2),
               (38, 1), (46, 4), (50, 9), (47, 15)], fill=INK)
    d.polygon([(19, 14), (17, 9), (21, 5), (27, 4), (32, 4),
               (37, 4), (45, 5), (48, 9), (45, 14)], fill=WHITE)
    d.rectangle([18, 12, 46, 19], fill=WHITE, outline=INK)
    d.line([(21, 15), (43, 15)], fill=(226, 218, 202, 255))
    # apron
    d.polygon([(18, 38), (46, 38), (50, 58), (14, 58)], fill=PINK, outline=PINK_DARK)
    d.polygon([(24, 38), (28, 33), (36, 33), (40, 38)], fill=(238, 178, 178, 255))
    d.rectangle([28, 42, 36, 50], fill=(240, 186, 184, 255), outline=PINK_DARK)
    d.line([(30, 45), (34, 45)], fill=PINK_DARK)
    # eyes
    for cx in (23, 41):
        d.ellipse([cx - 5, 22, cx + 5, 30], fill=WHITE, outline=INK)
        d.ellipse([cx - 2, 24, cx + 2, 29], fill=(72, 60, 46, 255))
        d.rectangle([cx - 2, 24, cx - 1, 25], fill=WHITE)
    d.line([(18, 19), (26, 18)], fill=INK)
    d.line([(38, 18), (46, 19)], fill=INK)
    d.ellipse([14, 29, 20, 33], fill=(236, 168, 158, 255))
    d.ellipse([44, 29, 50, 33], fill=(236, 168, 158, 255))
    d.arc([24, 29, 40, 37], 20, 160, fill=INK, width=2)
    # little feet
    d.ellipse([16, 56, 26, 62], fill=IVORY, outline=IVORY_SHADOW)
    d.ellipse([38, 56, 48, 62], fill=IVORY, outline=IVORY_SHADOW)
    # sparkles
    for x, y in ((8, 18), (54, 24), (6, 38), (56, 42)):
        d.rectangle([x, y, x + 1, y + 1], fill=WHITE)
    return im


def gloam_sprite() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    # wispy tail
    d.polygon([(26, 44), (38, 44), (36, 62), (28, 62)], fill=DUSK_DARK, outline=INK)
    d.arc([24, 50, 34, 62], 180, 360, fill=DUSK_LIGHT)
    d.arc([34, 52, 44, 62], 180, 360, fill=DUSK_LIGHT)
    # body
    d.ellipse([10, 14, 54, 52], fill=INK)
    d.ellipse([12, 16, 52, 50], fill=DUSK)
    d.ellipse([16, 20, 44, 44], fill=DUSK_LIGHT)
    d.arc([14, 32, 50, 54], 20, 160, fill=DUSK_DARK, width=2)
    d.arc([16, 20, 42, 44], 80, 160, fill=(178, 174, 226, 255))
    # flame crown: teardrop
    d.polygon([(32, 0), (39, 9), (41, 16), (37, 22), (32, 24),
               (27, 22), (23, 16), (25, 9)], fill=AMBER_DARK, outline=INK)
    d.polygon([(32, 3), (37, 10), (39, 16), (35, 20), (32, 21),
               (29, 20), (25, 16), (27, 10)], fill=AMBER)
    d.polygon([(32, 8), (35, 13), (36, 17), (32, 19), (28, 17),
               (29, 13)], fill=AMBER_LIGHT)
    # tired eyes
    d.ellipse([18, 26, 28, 36], fill=AMBER, outline=INK)
    d.ellipse([36, 26, 46, 36], fill=AMBER, outline=INK)
    d.ellipse([21, 30, 24, 34], fill=INK)
    d.ellipse([39, 30, 42, 34], fill=INK)
    d.rectangle([19, 27, 21, 29], fill=AMBER_LIGHT)
    d.rectangle([37, 27, 39, 29], fill=AMBER_LIGHT)
    # worried brows: inner corners raised
    d.line([(17, 25), (27, 23)], fill=INK)
    d.line([(37, 23), (47, 25)], fill=INK)
    # cheeks / mouth
    soft(im, [14, 38, 21, 42], (130, 112, 174, 130))
    soft(im, [43, 38, 50, 42], (130, 112, 174, 130))
    d.line([(29, 42), (32, 44), (35, 42)], fill=INK)
    # hands holding the curing light to the side, leaving the face clear
    d.ellipse([6, 34, 16, 44], fill=DUSK, outline=DUSK_DARK)
    d.ellipse([50, 46, 62, 56], fill=DUSK, outline=DUSK_DARK)
    # soft light bloom
    for box, a in (([44, 42, 66, 64], 22), ([47, 45, 63, 61], 34)):
        soft(im, box, (255, 214, 130, a))
    d.rectangle([52, 52, 58, 62], fill=IRON, outline=INK)
    d.rectangle([46, 46, 62, 54], fill=AMBER, outline=AMBER_DARK)
    d.rectangle([49, 48, 59, 51], fill=AMBER_LIGHT)
    # sparks around the flame
    for x, y in ((14, 10), (50, 8), (12, 22)):
        d.rectangle([x, y, x + 1, y + 1], fill=(255, 230, 150, 255))
    return im


def rattle_sprite() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    # glow
    for box, a in (([12, 2, 52, 42], 22), ([18, 8, 46, 36], 30)):
        soft(im, box, (122, 232, 216, a))
    # legs
    d.line([(26, 44), (24, 60)], fill=INK, width=3)
    d.line([(38, 44), (40, 60)], fill=INK, width=3)
    d.line([(26, 45), (25, 58)], fill=BONE, width=1)
    d.line([(38, 45), (39, 58)], fill=BONE, width=1)
    d.line([(20, 60), (28, 60)], fill=INK, width=2)
    d.line([(36, 60), (44, 60)], fill=INK, width=2)
    # spine and ribs
    d.rectangle([30, 34, 34, 48], fill=BONE_SHADOW, outline=INK)
    for y, w in ((38, 14), (43, 16), (48, 13)):
        d.arc([32 - w, y - 5, 32 + w, y + 5], 200, 340, fill=BONE, width=3)
        d.arc([32 - w, y - 5, 32 + w, y + 5], 200, 340, fill=INK, width=1)
    # pelvis
    d.ellipse([24, 46, 40, 56], fill=BONE_SHADOW, outline=INK)
    # skull
    d.ellipse([20, 4, 44, 32], fill=INK)
    d.ellipse([21, 5, 43, 31], fill=BONE)
    d.ellipse([24, 7, 40, 27], fill=BONE_LIGHT)
    d.arc([24, 16, 40, 32], 20, 160, fill=BONE_SHADOW, width=2)
    # eyes
    for cx in (28, 36):
        d.ellipse([cx - 3, 13, cx + 3, 20], fill=(22, 58, 56, 255), outline=INK)
        d.ellipse([cx - 1, 15, cx + 1, 18], fill=CYAN)
    # nose and grin
    d.polygon([(31, 20), (33, 20), (32, 23)], fill=(20, 54, 52, 255))
    d.line([(26, 24), (38, 24)], fill=INK, width=2)
    for x in (28, 32, 36):
        d.line([(x, 24), (x, 29)], fill=INK)
    # bow tie
    d.polygon([(24, 33), (31, 35), (24, 39)], fill=TEAL, outline=TEAL_DARK)
    d.polygon([(40, 33), (33, 35), (40, 39)], fill=TEAL, outline=TEAL_DARK)
    d.rectangle([31, 34, 33, 38], fill=TEAL_LIGHT, outline=TEAL_DARK)
    # arms and film
    d.line([(22, 36), (12, 42)], fill=INK, width=3)
    d.line([(22, 36), (13, 41)], fill=BONE, width=1)
    d.line([(42, 36), (52, 42)], fill=INK, width=3)
    d.line([(42, 36), (51, 41)], fill=BONE, width=1)
    d.rectangle([44, 40, 58, 52], fill=(24, 56, 54, 255), outline=CYAN)
    d.ellipse([48, 43, 55, 50], fill=CYAN)
    d.ellipse([50, 45, 53, 48], fill=(24, 56, 54, 255))
    # sparkles
    for x, y in ((10, 20), (54, 26), (8, 32)):
        d.rectangle([x, y, x + 1, y + 1], fill=(210, 255, 248, 255))
    return im


def mildew_sprite() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    # fuzzy shadow-ish outline kept soft so the scene shadow stays visible
    d.ellipse([8, 18, 56, 60], fill=INK)
    d.ellipse([10, 20, 54, 58], fill=MOLD_DARK)
    d.ellipse([13, 23, 51, 55], fill=MOLD)
    d.ellipse([17, 26, 38, 42], fill=MOLD_LIGHT)
    d.arc([14, 38, 50, 58], 20, 160, fill=(70, 94, 62, 255), width=2)
    # drips
    for x, y, w, h in ((12, 50, 10, 12), (28, 54, 8, 8), (44, 50, 10, 12)):
        d.ellipse([x, y, x + w, y + h], fill=MOLD_DARK)
        d.ellipse([x + 1, y, x + w - 1, y + h - 1], fill=MOLD_SLIME)
    # spores
    for x, y, r in ((18, 28, 3), (42, 30, 4), (16, 42, 3), (46, 44, 3)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=(188, 216, 148, 255))
        d.ellipse([x - r + 1, y - r + 1, x + r - 1, y + r - 1], fill=(222, 238, 190, 255))
    # towel hat
    d.polygon([(20, 18), (32, 12), (44, 18), (42, 24), (22, 24)], fill=INK)
    d.polygon([(22, 18), (32, 14), (42, 18), (40, 22), (24, 22)], fill=CREAM)
    d.rectangle([29, 14, 35, 18], fill=PINK, outline=PINK_DARK)
    # droopy eyes
    for cx in (24, 40):
        d.ellipse([cx - 7, 26, cx + 7, 36], fill=WHITE, outline=INK)
        d.ellipse([cx - 3, 29, cx + 3, 35], fill=(54, 86, 56, 255))
        d.ellipse([cx - 1, 30, cx + 1, 33], fill=INK)
        d.rectangle([cx - 3, 27, cx - 2, 29], fill=WHITE)
    d.line([(16, 24), (24, 26)], fill=MOLD_DARK)
    d.line([(40, 26), (48, 24)], fill=MOLD_DARK)
    # mouth
    d.arc([24, 38, 40, 46], 20, 160, fill=INK, width=2)
    soft(im, [17, 38, 23, 42], (210, 160, 150, 110))
    soft(im, [41, 38, 47, 42], (210, 160, 150, 110))
    # little arms and a scrub brush
    d.ellipse([4, 38, 14, 48], fill=MOLD, outline=MOLD_DARK)
    d.ellipse([50, 40, 62, 50], fill=MOLD, outline=MOLD_DARK)
    d.rectangle([50, 34, 62, 40], fill=WOOD, outline=WOOD_DARK)
    d.rectangle([49, 30, 63, 35], fill=CREAM, outline=WOOD_DARK)
    for x in (51, 55, 59):
        d.line([(x, 30), (x, 26)], fill=(226, 220, 200, 255))
    # floating spores
    for x, y in ((8, 18), (54, 20), (6, 30)):
        d.rectangle([x, y, x + 1, y + 1], fill=(210, 232, 176, 255))
    return im


def redtape_sprite() -> Image.Image:
    im = new(64, 64)
    d = ImageDraw.Draw(im)
    # jagged paper body
    d.polygon([(10, 12), (54, 12), (58, 56), (52, 52), (46, 58),
               (40, 52), (34, 58), (28, 52), (22, 58), (16, 52), (8, 56)],
              fill=INK)
    d.polygon([(12, 14), (52, 14), (56, 54), (50, 50), (44, 56),
               (38, 50), (32, 56), (26, 50), (20, 56), (14, 50), (10, 54)],
              fill=PAPER)
    d.polygon([(15, 16), (49, 16), (51, 34), (13, 34)], fill=IVORY_LIGHT)
    for y in (20, 25, 30):
        d.line([(18, y), (47, y)], fill=(210, 198, 178, 255))
    # red tape bands
    d.rectangle([8, 36, 56, 44], fill=RED_TAPE_DARK)
    d.rectangle([9, 37, 55, 42], fill=RED_TAPE)
    d.line([(11, 39), (53, 39)], fill=RED_TAPE_LIGHT)
    d.polygon([(8, 46), (56, 50), (56, 56), (8, 52)], fill=RED_TAPE_DARK)
    d.polygon([(9, 47), (55, 51), (55, 54), (9, 50)], fill=RED_TAPE)
    # glasses and eyes
    d.ellipse([16, 16, 30, 30], fill=WHITE, outline=INK)
    d.ellipse([34, 16, 48, 30], fill=WHITE, outline=INK)
    d.ellipse([21, 20, 27, 27], fill=(74, 62, 48, 255))
    d.ellipse([39, 20, 45, 27], fill=(74, 62, 48, 255))
    d.ellipse([23, 22, 25, 24], fill=INK)
    d.ellipse([41, 22, 43, 24], fill=INK)
    d.rectangle([17, 18, 19, 20], fill=WHITE)
    d.rectangle([35, 18, 37, 20], fill=WHITE)
    d.ellipse([15, 15, 31, 31], outline=(58, 46, 42, 255))
    d.ellipse([33, 15, 49, 31], outline=(58, 46, 42, 255))
    d.line([(30, 22), (34, 22)], fill=(58, 46, 42, 255))
    # stern brows
    d.line([(14, 12), (30, 16)], fill=INK)
    d.line([(34, 16), (50, 12)], fill=INK)
    # mouth
    d.line([(24, 34), (40, 34)], fill=INK, width=2)
    # paper arms with a stamp and folder
    d.line([(10, 44), (2, 34)], fill=INK, width=3)
    d.line([(10, 44), (3, 35)], fill=PAPER, width=1)
    d.line([(54, 44), (62, 34)], fill=INK, width=3)
    d.line([(54, 44), (61, 35)], fill=PAPER, width=1)
    d.rectangle([0, 26, 10, 34], fill=WOOD, outline=INK)
    d.rectangle([1, 22, 9, 27], fill=RED_TAPE)
    d.rectangle([56, 26, 64, 40], fill=CREAM, outline=WOOD_DARK)
    d.line([(58, 30), (62, 30)], fill=(198, 178, 150, 255))
    # little legs
    d.rectangle([18, 54, 24, 60], fill=PAPER, outline=INK)
    d.rectangle([40, 54, 46, 60], fill=PAPER, outline=INK)
    return im


# ---------------------------------------------------------------------------
# Props
# ---------------------------------------------------------------------------

def bakery_cart() -> Image.Image:
    im = new(64, 48)
    d = ImageDraw.Draw(im)
    # awning
    d.rectangle([2, 2, 61, 6], fill=WOOD_DARK)
    for i in range(4, 62, 14):
        d.rectangle([i, 6, i + 6, 17], fill=(198, 82, 72, 255))
        d.rectangle([i + 7, 6, i + 13, 17], fill=CREAM)
    d.rectangle([2, 16, 61, 20], fill=WOOD_DARK)
    for x in range(4, 62, 7):
        d.rectangle([x, 17, x + 3, 19], fill=(216, 158, 98, 255))
    # body
    d.rectangle([5, 20, 58, 39], fill=WOOD_DARK)
    d.rectangle([7, 22, 56, 37], fill=WOOD)
    d.line([(8, 24), (55, 24)], fill=WOOD_LIGHT)
    d.line([(8, 32), (55, 32)], fill=(156, 102, 60, 255))
    d.rectangle([10, 26, 20, 30], fill=(176, 116, 68, 255))
    d.rectangle([46, 26, 54, 30], fill=(176, 116, 68, 255))
    # bread
    for x, y, w in ((12, 18, 12), (28, 17, 14), (44, 19, 10)):
        d.ellipse([x, y, x + w, y + 8], fill=(218, 162, 96, 255), outline=(150, 98, 58, 255))
        d.line([(x + 3, y + 2), (x + w - 4, y + 2)], fill=(246, 210, 154, 255))
    # wheels
    for cx in (17, 47):
        d.ellipse([cx - 8, 34, cx + 8, 46], fill=INK)
        d.ellipse([cx - 6, 36, cx + 6, 44], fill=WOOD_DARK)
        d.ellipse([cx - 3, 38, cx + 3, 42], fill=WOOD)
        d.rectangle([cx - 1, 38, cx + 1, 42], fill=IRON)
    # handle
    d.line([(58, 24), (63, 30)], fill=IRON, width=2)
    d.line([(60, 22), (62, 24)], fill=IRON_LIGHT, width=2)
    return im


def tea_lamp() -> Image.Image:
    im = new(32, 64)
    d = ImageDraw.Draw(im)
    # no painted halo: the lantern pane itself stays crisp and the scene
    # provides any real light bloom.
    # post and base
    d.rectangle([14, 20, 17, 58], fill=INK)
    d.rectangle([15, 20, 16, 58], fill=WOOD)
    d.rectangle([9, 56, 22, 62], fill=INK)
    d.rectangle([10, 57, 21, 61], fill=IRON)
    d.rectangle([12, 58, 19, 59], fill=IRON_LIGHT)
    # arm
    d.rectangle([16, 20, 27, 23], fill=INK)
    d.rectangle([17, 21, 26, 22], fill=WOOD_DARK)
    d.line([(26, 22), (26, 27)], fill=IRON)
    # lantern
    d.rectangle([19, 2, 31, 20], fill=INK)
    d.rectangle([20, 3, 30, 19], fill=(54, 40, 34, 255))
    d.rectangle([22, 6, 28, 17], fill=AMBER)
    d.rectangle([23, 7, 27, 16], fill=AMBER_LIGHT)
    d.rectangle([19, 1, 31, 4], fill=IRON_LIGHT)
    d.rectangle([19, 18, 31, 21], fill=IRON_LIGHT)
    d.line([(25, 0), (25, 2)], fill=IRON)
    # tea cup and steam
    d.rectangle([2, 52, 10, 58], fill=CREAM, outline=WOOD_DARK)
    d.arc([9, 53, 13, 58], 270, 90, fill=WOOD_DARK)
    d.line([(5, 48), (4, 52)], fill=(224, 216, 196, 255))
    d.line([(8, 46), (7, 52)], fill=(224, 216, 196, 255))
    return im


def xray_board() -> Image.Image:
    im = new(48, 56)
    d = ImageDraw.Draw(im)
    # legs
    d.line([(14, 40), (8, 54)], fill=INK, width=4)
    d.line([(34, 40), (40, 54)], fill=INK, width=4)
    d.line([(14, 40), (9, 53)], fill=IRON, width=2)
    d.line([(34, 40), (39, 53)], fill=IRON, width=2)
    d.line([(6, 54), (16, 54)], fill=IRON_LIGHT, width=2)
    d.line([(32, 54), (42, 54)], fill=IRON_LIGHT, width=2)
    # frame
    d.rectangle([3, 1, 44, 42], fill=INK)
    d.rectangle([4, 2, 43, 41], fill=(32, 62, 60, 255))
    d.rectangle([6, 4, 41, 39], outline=CYAN_DARK)
    d.rectangle([8, 6, 39, 37], outline=(78, 170, 158, 255))
    # glow
    for box, a in (([8, 2, 40, 34], 22), ([12, 6, 36, 30], 34)):
        soft(im, box, (122, 232, 216, a))
    # tooth
    d.polygon([(18, 10), (30, 10), (28, 22), (26, 26), (24, 22),
               (22, 26), (20, 22)], fill=CYAN)
    d.ellipse([21, 12, 27, 18], fill=(214, 255, 248, 255))
    # ribs
    for y in (28, 32, 36):
        d.arc([10, y - 4, 38, y + 4], 200, 340, fill=CYAN, width=1)
    # labels / clips
    d.rectangle([8, 36, 17, 38], fill=CYAN_DARK)
    d.rectangle([31, 36, 40, 38], fill=CYAN_DARK)
    for x, y in ((5, 3), (41, 3), (5, 37), (41, 37)):
        d.rectangle([x, y, x + 2, y + 2], fill=IRON_LIGHT)
    return im


def mildew_patch() -> Image.Image:
    im = new(48, 32)
    d = ImageDraw.Draw(im)
    # wet floor puddle
    d.ellipse([1, 21, 44, 31], fill=(74, 108, 88, 255))
    d.ellipse([3, 22, 41, 29], fill=(98, 138, 108, 255))
    d.ellipse([7, 23, 24, 27], fill=(132, 174, 132, 255))
    d.line([(8, 26), (18, 26)], fill=(176, 210, 168, 255))
    # mop leaning on a bucket
    d.line([(9, 4), (16, 24)], fill=INK, width=3)
    d.line([(9, 5), (16, 24)], fill=WOOD, width=1)
    d.rectangle([4, 1, 13, 6], fill=(200, 196, 176, 255), outline=INK)
    for x in (5, 8, 11):
        d.line([(x, 6), (x - 1, 10)], fill=(226, 220, 200, 255))
    # bucket
    d.polygon([(28, 14), (46, 14), (43, 28), (31, 28)], fill=INK)
    d.polygon([(29, 15), (45, 15), (42, 27), (32, 27)], fill=IRON)
    d.polygon([(31, 16), (35, 16), (33, 26), (30, 26)], fill=IRON_LIGHT)
    d.arc([28, 9, 46, 18], 180, 360, fill=IRON_LIGHT)
    d.ellipse([32, 16, 42, 22], fill=(120, 168, 126, 255))
    # moss clumps
    for x, y in ((6, 20), (40, 21), (18, 29)):
        d.ellipse([x - 3, y - 2, x + 3, y + 2], fill=MOLD)
        d.ellipse([x - 1, y - 3, x + 2, y], fill=MOLD_LIGHT)
    return im


def records_cart() -> Image.Image:
    im = new(48, 48)
    d = ImageDraw.Draw(im)
    # cart body
    d.rectangle([5, 24, 42, 40], fill=INK)
    d.rectangle([7, 26, 40, 38], fill=WOOD)
    d.line([(8, 28), (39, 28)], fill=WOOD_LIGHT)
    d.line([(8, 34), (39, 34)], fill=(156, 102, 60, 255))
    # folders and papers piled on top
    for x, y, w, h, color in (
        (8, 18, 12, 8, (204, 168, 96, 255)),
        (20, 15, 14, 10, (230, 218, 194, 255)),
        (32, 17, 10, 9, (186, 148, 86, 255)),
    ):
        d.rectangle([x, y, x + w, y + h], fill=color, outline=INK_SOFT)
        d.rectangle([x + 2, y + 2, x + w - 3, y + 3], fill=CREAM)
        d.line([(x + 2, y + h - 3), (x + w - 3, y + h - 3)],
               fill=(170, 148, 118, 255))
    # red tape wrapped around the stack
    d.rectangle([18, 12, 22, 38], fill=RED_TAPE_DARK)
    d.rectangle([19, 12, 21, 38], fill=RED_TAPE)
    d.line([(12, 23), (36, 23)], fill=RED_TAPE_DARK)
    # wheels
    for cx in (14, 35):
        d.ellipse([cx - 6, 36, cx + 6, 46], fill=INK)
        d.ellipse([cx - 4, 37, cx + 4, 44], fill=WOOD_DARK)
        d.rectangle([cx - 1, 39, cx + 1, 43], fill=IRON)
    # handle
    d.line([(41, 26), (47, 18)], fill=WOOD_DARK, width=2)
    d.line([(46, 18), (47, 16)], fill=IRON, width=2)
    return im


# ---------------------------------------------------------------------------
# 16x16 item icons
# ---------------------------------------------------------------------------

def icon_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = new(16, 16)
    return im, ImageDraw.Draw(im)


def mirror_icon() -> Image.Image:
    im, d = icon_canvas()
    d.ellipse([2, 1, 13, 12], fill=INK)
    d.ellipse([3, 2, 12, 11], fill=(188, 202, 214, 255))
    d.ellipse([4, 3, 11, 10], fill=(220, 240, 248, 255))
    d.polygon([(5, 8), (5, 4), (8, 4)], fill=WHITE)
    d.rectangle([7, 11, 9, 15], fill=INK)
    d.rectangle([8, 11, 8, 14], fill=(198, 206, 214, 255))
    return im


def chair_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([2, 3, 6, 9], fill=INK)
    d.rectangle([3, 4, 5, 8], fill=(88, 174, 166, 255))
    d.rectangle([5, 8, 13, 11], fill=INK)
    d.rectangle([6, 8, 12, 10], fill=(108, 194, 184, 255))
    d.rectangle([12, 3, 14, 9], fill=INK)
    d.rectangle([12, 4, 13, 8], fill=(88, 174, 166, 255))
    d.line([(4, 11), (4, 15)], fill=IRON)
    d.line([(12, 11), (12, 15)], fill=IRON)
    d.line([(3, 15), (6, 15)], fill=IRON_LIGHT)
    d.line([(10, 15), (13, 15)], fill=IRON_LIGHT)
    return im


def curing_light_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([7, 7, 11, 15], fill=INK)
    d.rectangle([8, 8, 10, 14], fill=IRON)
    d.rectangle([6, 3, 12, 9], fill=INK)
    d.rectangle([7, 4, 11, 8], fill=AMBER)
    d.rectangle([8, 5, 10, 7], fill=AMBER_LIGHT)
    for x, y in ((3, 2), (13, 3), (2, 7), (14, 8)):
        d.rectangle([x, y, x + 1, y + 1], fill=(255, 220, 130, 255))
    return im


def sterilizer_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([1, 3, 14, 14], fill=INK)
    d.rectangle([2, 4, 13, 13], fill=(178, 192, 200, 255))
    d.rectangle([3, 5, 12, 12], fill=(206, 222, 228, 255))
    d.rectangle([5, 7, 11, 11], fill=(96, 132, 146, 255))
    d.rectangle([6, 8, 10, 10], fill=(64, 96, 110, 255))
    d.rectangle([12, 5, 12, 12], fill=(132, 152, 162, 255))
    d.rectangle([3, 6, 4, 7], fill=(120, 220, 160, 255))
    d.line([(3, 13), (12, 13)], fill=(132, 152, 162, 255))
    return im


def xray_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([1, 2, 14, 14], fill=INK)
    d.rectangle([2, 3, 13, 13], fill=(34, 72, 70, 255))
    d.rectangle([3, 4, 12, 12], outline=(78, 178, 166, 255))
    d.polygon([(6, 5), (10, 5), (9, 9), (8, 11), (7, 9)], fill=CYAN)
    d.rectangle([7, 6, 8, 8], fill=WHITE)
    d.arc([4, 9, 12, 12], 200, 340, fill=(78, 178, 166, 255))
    return im


def records_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([2, 2, 13, 14], fill=INK)
    d.rectangle([3, 3, 12, 13], fill=(206, 168, 96, 255))
    d.rectangle([8, 1, 14, 4], fill=INK)
    d.rectangle([9, 2, 13, 3], fill=(230, 196, 128, 255))
    d.rectangle([5, 5, 11, 12], fill=(242, 234, 216, 255))
    for y in (6, 8, 10):
        d.line([(6, y), (10, y)], fill=(150, 128, 100, 255))
    d.rectangle([3, 3, 4, 13], fill=(180, 142, 74, 255))
    return im


def bell_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([2, 12, 13, 14], fill=INK)
    d.rectangle([3, 11, 12, 13], fill=(196, 142, 44, 255))
    d.ellipse([3, 4, 12, 13], fill=INK)
    d.ellipse([4, 5, 11, 12], fill=(246, 196, 78, 255))
    d.rectangle([4, 10, 11, 11], fill=(200, 142, 40, 255))
    d.rectangle([7, 2, 8, 5], fill=(246, 196, 78, 255))
    d.rectangle([6, 1, 9, 2], fill=(255, 234, 150, 255))
    d.rectangle([5, 7, 6, 8], fill=(255, 240, 180, 255))
    return im


def empty_slot_icon() -> Image.Image:
    im, d = icon_canvas()
    d.rectangle([1, 1, 14, 14], outline=(176, 168, 150, 255))
    d.rectangle([3, 3, 12, 12], outline=(214, 206, 188, 255))
    d.point((2, 2), fill=(214, 206, 188, 255))
    d.point((13, 2), fill=(214, 206, 188, 255))
    d.point((2, 13), fill=(214, 206, 188, 255))
    d.point((13, 13), fill=(214, 206, 188, 255))
    return im


# ---------------------------------------------------------------------------
# HUD wood panel and Continue buttons
# ---------------------------------------------------------------------------

def wood_panel() -> Image.Image:
    im = new(40, 22)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 39, 21], fill=(58, 34, 22, 255))
    d.rectangle([1, 1, 38, 20], fill=(184, 98, 52, 255))
    d.rectangle([2, 2, 37, 19], fill=(200, 112, 62, 255))
    d.line([(5, 2), (34, 2)], fill=(232, 148, 88, 255))
    d.line([(5, 3), (34, 3)], fill=(218, 128, 74, 255))
    d.line([(4, 19), (35, 19)], fill=(126, 62, 32, 255))
    d.line([(4, 18), (35, 18)], fill=(146, 76, 40, 255))
    # grain
    d.line([(9, 3), (9, 18)], fill=(178, 92, 50, 255))
    d.line([(30, 3), (30, 18)], fill=(178, 92, 50, 255))
    # inset
    d.rectangle([5, 5, 34, 16], fill=(112, 56, 30, 255))
    d.rectangle([6, 6, 33, 15], fill=(238, 178, 132, 255))
    d.line([(8, 6), (31, 6)], fill=(196, 132, 94, 255))
    d.line([(8, 15), (31, 15)], fill=(255, 214, 176, 255))
    # rivets
    for x, y in ((2, 2), (35, 2), (2, 17), (35, 17)):
        d.rectangle([x, y, x + 2, y + 2], fill=(92, 52, 28, 255))
        d.rectangle([x + 1, y + 1, x + 1, y + 1], fill=(246, 206, 96, 255))
    return im


CONTINUE_GLYPHS = {
    "C": [".##.", "#...", "#...", "#...", ".##."],
    "O": [".##.", "#..#", "#..#", "#..#", ".##."],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "T": ["####", ".#..", ".#..", ".#..", ".#.."],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "U": ["#..#", "#..#", "#..#", "#..#", ".##."],
    "E": ["####", "#...", "###.", "#...", "####"],
}


def continue_button(source: str, target: str, hover: bool) -> None:
    from PIL import Image as _Image

    base = _Image.open(ROOT / "Scenes" / "MainMenu" / "Sprites" / source).convert("RGBA")
    # Most common interior colour becomes the clean fill behind the label.
    counts: dict[tuple[int, int, int, int], int] = {}
    for y in range(4, 13):
        for x in range(4, 44):
            px = base.getpixel((x, y))
            if px[3] == 0 or px[0] > 210 and px[1] > 210 and px[2] > 210:
                continue
            counts[px] = counts.get(px, 0) + 1
    fill = max(counts, key=counts.get)
    for y in range(4, 13):
        for x in range(4, 44):
            base.putpixel((x, y), fill)

    text = "CONTINUE"
    widths = [len(CONTINUE_GLYPHS[c][0]) for c in text]
    total = sum(widths) + len(text) - 1
    x = (48 - total) // 2
    y = 5
    pixels: list[tuple[int, int]] = []
    for letter in text:
        glyph = CONTINUE_GLYPHS[letter]
        for gy, row in enumerate(glyph):
            for gx, cell in enumerate(row):
                if cell == "#":
                    pixels.append((x + gx, y + gy))
        x += len(glyph[0]) + 1
    # A four-way outline keeps the word bold without turning the interior
    # into a solid dark slab.
    glyph_pixels = set(pixels)
    outline: set[tuple[int, int]] = set()
    for px, py in pixels:
        for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cell = (px + ox, py + oy)
            if cell not in glyph_pixels:
                outline.add(cell)
    for px, py in outline:
        if 4 <= px <= 44 and 4 <= py <= 12:
            base.putpixel((px, py), (14, 32, 52, 255))
    for px, py in pixels:
        base.putpixel((px, py), (255, 255, 255, 255))
    base.save(ROOT / "Scenes" / "MainMenu" / "Sprites" / target)
    print("wrote", target, base.size)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    # Existing clinic cast
    save(sheet([npc_frame(True, i) for i in range(8)]),
         "Scenes/NPC/Sprites/Priya_Long.png")
    save(sheet([npc_frame(False, i) for i in range(8)]),
         "Scenes/NPC/Sprites/Mehta_Long.png")
    save(sheet([priya_frame(i) for i in range(4)]),
         "Scenes/NPC/Portraits/Priya_Dialogue.png")
    save(sheet([mehta_frame(i) for i in range(4)]),
         "Scenes/NPC/Portraits/Mehta_Dialogue.png")
    save(sheet([blueshirt_frame(i) for i in range(4)]),
         "Scenes/NPC/Portraits/npc_portrait_01.png")

    # Sugar creatures
    save(blorb_sprite(), "Assets_Imported/villains/blorb.png")
    save(sheet([blorb_frame(i) for i in range(4)]),
         "Assets_Imported/villains/blorb_portrait.png")
    save(wobble_sprite(), "Assets_Imported/villains/wobble.png")
    save(sheet([wobble_frame(i) for i in range(4)]),
         "Assets_Imported/villains/wobble_portrait.png")
    save(gloam_sprite(), "Assets_Imported/villains/gloam.png")
    save(sheet([gloam_frame(i) for i in range(4)]),
         "Assets_Imported/villains/gloam_portrait.png")
    save(rattle_sprite(), "Assets_Imported/villains/rattle.png")
    save(sheet([rattle_frame(i) for i in range(4)]),
         "Assets_Imported/villains/rattle_portrait.png")
    save(mildew_sprite(), "Assets_Imported/villains/mildew.png")
    save(sheet([mildew_frame(i) for i in range(4)]),
         "Assets_Imported/villains/mildew_portrait.png")
    save(redtape_sprite(), "Assets_Imported/villains/redtape.png")
    save(sheet([redtape_frame(i) for i in range(4)]),
         "Assets_Imported/villains/redtape_portrait.png")

    # Props and UI
    save(bakery_cart(), "Assets_Imported/town/bakery_cart.png")
    save(tea_lamp(), "Assets_Imported/town/tea_lamp.png")
    save(xray_board(), "Assets_Imported/town/xray_board.png")
    save(mildew_patch(), "Assets_Imported/town/mildew_patch.png")
    save(records_cart(), "Assets_Imported/town/records_cart.png")
    for image, name in (
        (mirror_icon(), "mirror_set"),
        (chair_icon(), "chair"),
        (curing_light_icon(), "curing_light"),
        (sterilizer_icon(), "sterilizer"),
        (xray_icon(), "xray"),
        (records_icon(), "records"),
        (bell_icon(), "bell"),
        (empty_slot_icon(), "empty_slot"),
    ):
        save(image, f"Assets_Imported/ui/items/{name}.png")
    save(wood_panel(), "GUI/sprites/wood_panel.png")
    continue_button("Start_Idle_Button_new.png", "Continue_idle_Button.png", False)
    continue_button("Start_hover_Button_new.png", "Continue_hover_Button.png", True)


if __name__ == "__main__":
    main()
