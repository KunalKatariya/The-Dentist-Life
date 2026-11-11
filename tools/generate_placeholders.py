#!/usr/bin/env python3
"""Generate placeholder art for The Great Clinic Robbery.

These are intentionally simple stand-ins. Replace them on the polish day.
Run from the project root:

    python3 tools/generate_placeholders.py

Requires Pillow. Files are written with hard pixel edges so Godot's nearest
filter keeps them crisp.
"""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent


def upscale(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("wrote", rel, img.size)


# ---------------------------------------------------------------------------
# World sprites: 8 frames of 32x32 (idle 0-3, walk 4-7)
# ---------------------------------------------------------------------------

def npc_sheet(skin, hair, shirt, trousers, shoes, bun=False, glasses=False,
              grey_hair=False):
    """Draw a 16x16 character per frame, then upscale 2x to 32x32."""
    sheet = Image.new("RGBA", (256, 32), (0, 0, 0, 0))

    for frame in range(8):
        f = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(f)

        bob = 1 if frame in (1, 3) else 0
        walking = frame >= 4
        step = (frame - 4) % 2

        # legs
        leg_y = 13 + bob
        if walking:
            d.rectangle([5, leg_y, 6, 15], fill=trousers)
            d.rectangle([9, leg_y - (1 if step else 0), 10, 15],
                        fill=trousers)
            d.rectangle([4, 15, 6, 15], fill=shoes)
            d.rectangle([9, 15, 11, 15], fill=shoes)
        else:
            d.rectangle([5, leg_y, 6, 15], fill=trousers)
            d.rectangle([9, leg_y, 10, 15], fill=trousers)
            d.rectangle([4, 15, 6, 15], fill=shoes)
            d.rectangle([9, 15, 11, 15], fill=shoes)

        # body
        d.rectangle([5, 8 + bob, 10, 12 + bob], fill=shirt)
        d.rectangle([3, 9 + bob, 4, 12 + bob], fill=shirt)
        d.rectangle([11, 9 + bob, 12, 12 + bob], fill=shirt)
        d.rectangle([5, 9 + bob, 10, 9 + bob], fill=skin)

        # head
        d.ellipse([4, 1 + bob, 11, 8 + bob], fill=skin)
        d.rectangle([4, 1 + bob, 11, 3 + bob], fill=hair)
        d.ellipse([4, 0 + bob, 11, 4 + bob], fill=hair)
        if bun:
            d.ellipse([9, 0 + bob, 12, 3 + bob], fill=hair)
        if grey_hair:
            d.rectangle([4, 2 + bob, 11, 2 + bob], fill=hair)

        # eyes
        d.point((6, 5 + bob), fill=(40, 30, 30, 255))
        d.point((9, 5 + bob), fill=(40, 30, 30, 255))
        if glasses:
            d.rectangle([5, 4 + bob, 7, 6 + bob], outline=(60, 50, 40, 255))
            d.rectangle([8, 4 + bob, 10, 6 + bob], outline=(60, 50, 40, 255))
            d.line([7, 5 + bob, 8, 5 + bob], fill=(60, 50, 40, 255))

        # mouth
        d.point((7, 7 + bob), fill=(120, 60, 60, 255))

        sheet.paste(upscale(f, 2), (frame * 32, 0))

    return sheet


# ---------------------------------------------------------------------------
# Portraits: 4 frames of 100x148
# ---------------------------------------------------------------------------

def portrait_frame(bg, skin, hair, shirt, mouth="smile", blink=False,
                   glasses=False, blob=False, spots=None):
    """Draw one 50x74 bust, then upscale 2x to 100x148."""
    f = Image.new("RGBA", (50, 74), bg)
    d = ImageDraw.Draw(f)

    # soft background bubbles
    for cx, cy, r, col in [
        (8, 10, 5, (255, 255, 255, 40)),
        (42, 18, 7, (255, 255, 255, 30)),
        (15, 60, 6, (255, 255, 255, 25)),
    ]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)

    if blob:
        # rounded plaque blob
        d.ellipse([6, 18, 44, 72], fill=skin)
        d.ellipse([8, 20, 42, 68], fill=skin)
        if spots:
            for sx, sy, sr in spots:
                d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr],
                          fill=(90, 170, 140, 255))
        # eyes
        if blink:
            d.line([17, 38, 22, 38], fill=(30, 50, 45, 255), width=2)
            d.line([28, 38, 33, 38], fill=(30, 50, 45, 255), width=2)
        else:
            d.ellipse([17, 33, 23, 41], fill=(250, 250, 245, 255))
            d.ellipse([27, 33, 33, 41], fill=(250, 250, 245, 255))
            d.ellipse([19, 36, 21, 39], fill=(30, 50, 45, 255))
            d.ellipse([29, 36, 31, 39], fill=(30, 50, 45, 255))
        # mouth
        if mouth == "open":
            d.ellipse([22, 48, 28, 56], fill=(120, 60, 70, 255))
        else:
            d.arc([21, 47, 29, 55], 10, 170, fill=(60, 90, 80, 255), width=1)
        return upscale(f, 2)

    # shoulders
    d.ellipse([2, 56, 48, 86], fill=shirt)
    d.rectangle([20, 48, 30, 62], fill=skin)

    # head
    d.ellipse([10, 10, 40, 46], fill=skin)
    # ears
    d.ellipse([7, 26, 11, 33], fill=skin)
    d.ellipse([39, 26, 43, 33], fill=skin)
    # hair
    d.ellipse([9, 6, 41, 26], fill=hair)
    d.rectangle([9, 18, 13, 32], fill=hair)
    d.rectangle([37, 18, 41, 32], fill=hair)
    if glasses:
        d.rectangle([14, 28, 23, 35], outline=(50, 45, 40, 255))
        d.rectangle([27, 28, 36, 35], outline=(50, 45, 40, 255))
        d.line([23, 31, 27, 31], fill=(50, 45, 40, 255))

    # eyes
    if blink:
        d.line([16, 31, 21, 31], fill=(40, 30, 30, 255), width=1)
        d.line([29, 31, 34, 31], fill=(40, 30, 30, 255), width=1)
    else:
        d.ellipse([15, 27, 22, 35], fill=(250, 250, 245, 255))
        d.ellipse([28, 27, 35, 35], fill=(250, 250, 245, 255))
        d.ellipse([17, 29, 20, 34], fill=(60, 40, 30, 255))
        d.ellipse([30, 29, 33, 34], fill=(60, 40, 30, 255))

    # nose and mouth
    d.point((25, 37), fill=(150, 90, 80, 255))
    if mouth == "open":
        d.ellipse([21, 40, 29, 48], fill=(130, 60, 60, 255))
        d.rectangle([23, 41, 27, 42], fill=(250, 250, 245, 255))
    elif mouth == "worry":
        d.arc([20, 42, 30, 49], 200, 340, fill=(120, 60, 60, 255), width=1)
    else:
        d.arc([20, 40, 30, 48], 20, 160, fill=(120, 60, 60, 255), width=1)

    return upscale(f, 2)


def portrait_sheet(frames):
    sheet = Image.new("RGBA", (400, 148), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * 100, 0))
    return sheet


# ---------------------------------------------------------------------------
# Item icons: 16x16
# ---------------------------------------------------------------------------

def icon(draw_fn, bg=(0, 0, 0, 0)):
    img = Image.new("RGBA", (16, 16), bg)
    draw_fn(ImageDraw.Draw(img))
    return img


def mirror_icon():
    def draw(d):
        d.ellipse([3, 1, 12, 10], fill=(200, 230, 240, 255),
                  outline=(70, 90, 100, 255))
        d.ellipse([5, 3, 10, 8], fill=(240, 250, 255, 255))
        d.line([7, 10, 7, 14], fill=(120, 120, 130, 255), width=2)
        d.line([5, 14, 9, 14], fill=(120, 120, 130, 255))
    return icon(draw)


def chair_icon():
    def draw(d):
        d.rectangle([4, 6, 12, 9], fill=(90, 150, 200, 255))
        d.rectangle([4, 2, 6, 6], fill=(90, 150, 200, 255))
        d.rectangle([6, 9, 8, 15], fill=(70, 80, 90, 255))
        d.rectangle([10, 9, 12, 15], fill=(70, 80, 90, 255))
    return icon(draw)


def light_icon():
    def draw(d):
        d.ellipse([4, 1, 11, 7], fill=(255, 220, 110, 255),
                  outline=(130, 100, 40, 255))
        d.rectangle([7, 7, 8, 12], fill=(150, 160, 170, 255))
        d.rectangle([4, 12, 11, 14], fill=(90, 100, 110, 255))
    return icon(draw)


def sterilizer_icon():
    def draw(d):
        d.rectangle([2, 3, 13, 14], fill=(220, 235, 240, 255),
                    outline=(90, 110, 120, 255))
        d.rectangle([4, 5, 11, 9], fill=(130, 180, 200, 255))
        d.point((6, 11), fill=(80, 80, 80, 255))
        d.point((9, 11), fill=(80, 80, 80, 255))
    return icon(draw)


def xray_icon():
    def draw(d):
        d.rectangle([1, 2, 14, 13], fill=(40, 50, 60, 255),
                    outline=(100, 120, 130, 255))
        d.rectangle([5, 4, 10, 6], fill=(200, 240, 255, 255))
        d.rectangle([4, 6, 5, 10], fill=(200, 240, 255, 255))
        d.rectangle([10, 6, 11, 10], fill=(200, 240, 255, 255))
        d.rectangle([5, 10, 10, 11], fill=(200, 240, 255, 255))
    return icon(draw)


def records_icon():
    def draw(d):
        d.rectangle([2, 4, 13, 14], fill=(230, 200, 130, 255),
                    outline=(120, 90, 50, 255))
        d.rectangle([2, 2, 7, 5], fill=(230, 200, 130, 255),
                    outline=(120, 90, 50, 255))
        d.line([4, 8, 11, 8], fill=(120, 90, 50, 255))
        d.line([4, 10, 11, 10], fill=(120, 90, 50, 255))
        d.line([4, 12, 9, 12], fill=(120, 90, 50, 255))
    return icon(draw)


def bell_icon():
    def draw(d):
        d.ellipse([4, 2, 11, 9], fill=(250, 210, 90, 255),
                  outline=(150, 110, 30, 255))
        d.rectangle([3, 9, 12, 10], fill=(250, 210, 90, 255),
                    outline=(150, 110, 30, 255))
        d.rectangle([7, 10, 8, 12], fill=(150, 110, 30, 255))
        d.ellipse([6, 12, 9, 14], fill=(150, 110, 30, 255))
    return icon(draw)


def empty_slot_icon():
    def draw(d):
        d.rectangle([1, 1, 14, 14], outline=(150, 160, 170, 120))
        d.point((1, 1), fill=(150, 160, 170, 120))
        d.point((14, 1), fill=(150, 160, 170, 120))
        d.point((1, 14), fill=(150, 160, 170, 120))
        d.point((14, 14), fill=(150, 160, 170, 120))
    return icon(draw)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    # NPC world sprites
    save(npc_sheet(
        skin=(230, 180, 150, 255),
        hair=(55, 35, 30, 255),
        shirt=(80, 180, 170, 255),
        trousers=(60, 70, 90, 255),
        shoes=(240, 240, 240, 255),
        bun=True,
    ), "Scenes/NPC/Sprites/Priya_Long.png")

    save(npc_sheet(
        skin=(220, 170, 140, 255),
        hair=(170, 170, 175, 255),
        shirt=(210, 170, 70, 255),
        trousers=(90, 80, 70, 255),
        shoes=(70, 60, 55, 255),
        glasses=True,
        grey_hair=True,
    ), "Scenes/NPC/Sprites/Mehta_Long.png")

    # Portraits: normal, blink, mouth open, normal
    priya_bg = (250, 226, 205, 255)
    save(portrait_sheet([
        portrait_frame(priya_bg, (230, 180, 150, 255), (55, 35, 30, 255),
                       (80, 180, 170, 255), mouth="smile"),
        portrait_frame(priya_bg, (230, 180, 150, 255), (55, 35, 30, 255),
                       (80, 180, 170, 255), mouth="smile", blink=True),
        portrait_frame(priya_bg, (230, 180, 150, 255), (55, 35, 30, 255),
                       (80, 180, 170, 255), mouth="open"),
        portrait_frame(priya_bg, (230, 180, 150, 255), (55, 35, 30, 255),
                       (80, 180, 170, 255), mouth="smile"),
    ]), "Scenes/NPC/Portraits/Priya_Dialogue.png")

    mehta_bg = (220, 236, 220, 255)
    save(portrait_sheet([
        portrait_frame(mehta_bg, (220, 170, 140, 255), (170, 170, 175, 255),
                       (210, 170, 70, 255), mouth="worry", glasses=True),
        portrait_frame(mehta_bg, (220, 170, 140, 255), (170, 170, 175, 255),
                       (210, 170, 70, 255), mouth="worry", blink=True,
                       glasses=True),
        portrait_frame(mehta_bg, (220, 170, 140, 255), (170, 170, 175, 255),
                       (210, 170, 70, 255), mouth="open", glasses=True),
        portrait_frame(mehta_bg, (220, 170, 140, 255), (170, 170, 175, 255),
                       (210, 170, 70, 255), mouth="worry", glasses=True),
    ]), "Scenes/NPC/Portraits/Mehta_Dialogue.png")

    # Blorb: portrait and world sprite
    blorb_bg = (232, 220, 245, 255)
    blorb_spots = [(18, 26, 3), (32, 50, 4), (14, 55, 3), (36, 28, 2)]
    save(portrait_sheet([
        portrait_frame(blorb_bg, (140, 215, 180, 255), None, None, blob=True,
                       spots=blorb_spots),
        portrait_frame(blorb_bg, (140, 215, 180, 255), None, None, blob=True,
                       blink=True, spots=blorb_spots),
        portrait_frame(blorb_bg, (140, 215, 180, 255), None, None,
                       mouth="open", blob=True, spots=blorb_spots),
        portrait_frame(blorb_bg, (140, 215, 180, 255), None, None, blob=True,
                       spots=blorb_spots),
    ]), "Assets_Imported/villains/blorb_portrait.png")

    # 32x32 blob -> 64x64 world sprite
    b = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(b)
    d.ellipse([2, 6, 30, 31], fill=(120, 200, 165, 255))
    d.ellipse([5, 9, 27, 28], fill=(145, 220, 185, 255))
    for sx, sy, sr in [(11, 14, 2), (22, 20, 3), (12, 24, 2), (24, 12, 2)]:
        d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(95, 175, 140, 255))
    d.ellipse([9, 15, 14, 21], fill=(250, 250, 245, 255))
    d.ellipse([18, 15, 23, 21], fill=(250, 250, 245, 255))
    d.ellipse([10, 17, 12, 20], fill=(35, 55, 50, 255))
    d.ellipse([20, 17, 22, 20], fill=(35, 55, 50, 255))
    d.arc([12, 22, 20, 28], 10, 170, fill=(60, 100, 85, 255), width=1)
    save(upscale(b, 2), "Assets_Imported/villains/blorb.png")

    # Item icons
    save(mirror_icon(), "Assets_Imported/ui/items/mirror_set.png")
    save(chair_icon(), "Assets_Imported/ui/items/chair.png")
    save(light_icon(), "Assets_Imported/ui/items/curing_light.png")
    save(sterilizer_icon(), "Assets_Imported/ui/items/sterilizer.png")
    save(xray_icon(), "Assets_Imported/ui/items/xray.png")
    save(records_icon(), "Assets_Imported/ui/items/records.png")
    save(bell_icon(), "Assets_Imported/ui/items/bell.png")
    save(empty_slot_icon(), "Assets_Imported/ui/items/empty_slot.png")


if __name__ == "__main__":
    main()
