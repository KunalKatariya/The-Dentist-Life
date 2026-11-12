#!/usr/bin/env python3
"""Generate the wooden HUD sign used behind the equipment counter.

The art intentionally matches the day/night clock sign:
dark plank outline, warm orange wood, a peach inset panel and small brass
rivets in the corners. It is a 9-patch texture, so the rivets survive scaling.

    python3 tools/generate_hud_wood.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

OUT = os.path.join("GUI", "sprites", "wood_panel.png")
W, H = 40, 22


def rounded(draw: ImageDraw.ImageDraw, box, radius: int, fill) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def main() -> None:
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Dark outline + warm wooden frame.
    rounded(draw, (0, 0, W - 1, H - 1), 3, "#4A2A18")
    rounded(draw, (1, 1, W - 2, H - 2), 2, "#B96334")
    # Lit top edge and shaded bottom edge.
    draw.line([(6, 1), (W - 7, 1)], fill="#E08A45")
    draw.line([(6, 2), (W - 7, 2)], fill="#CE7439")
    draw.line([(6, H - 2), (W - 7, H - 2)], fill="#7E3D1E")
    # Vertical grain hints.
    draw.line([(10, 2), (10, H - 3)], fill="#AF5C31")
    draw.line([(W - 11, 2), (W - 11, H - 3)], fill="#AF5C31")

    # Peach inset panel.
    rounded(draw, (5, 5, W - 6, H - 6), 1, "#7E3D1E")
    rounded(draw, (6, 6, W - 7, H - 7), 1, "#F4B183")
    draw.line([(8, 6), (W - 9, 6)], fill="#C97A4A")
    draw.line([(8, H - 7), (W - 9, H - 7)], fill="#FFD0A6")

    # Brass rivets.
    for rx, ry in ((2, 2), (W - 5, 2), (2, H - 5), (W - 5, H - 5)):
        draw.rectangle((rx, ry, rx + 1, ry + 1), fill="#F5C64F")
        draw.point((rx, ry), fill="#FFF0B0")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    image.save(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
