#!/usr/bin/env python3
"""Generate smooth, DrGT-style dialogue portraits.

The dialogue system expects a 400x148 strip with four 100x148 frames:
    0 = calm / mouth closed
    1 = blink / mouth closed
    2 = happy / mouth open
    3 = blink + happy / mouth open

Each frame is described as an SVG (vector art, so it stays crisp), rendered at
4x with rsvg-convert and downsampled. Run from the repo root:

    python3 tools/generate_portraits.py
"""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass

from PIL import Image

OUT_DIR = os.path.join("Scenes", "NPC", "Portraits")
SCALE = 4
W, H = 100, 148


@dataclass
class Character:
    key: str
    filename: str
    skin: str
    skin_shadow: str
    skin_light: str
    hair: str
    hair_dark: str
    hair_light: str
    shirt: str
    shirt_dark: str
    hair_style: str
    iris: str = "#5B3623"
    lip: str = "#A85F58"
    brow: str = ""
    has_glasses: bool = False
    has_beard: bool = False


PRIYA = Character(
    key="priya",
    filename="Priya_Dialogue.png",
    skin="#F2C3A2",
    skin_shadow="#DE9E7C",
    skin_light="#FFDCC1",
    hair="#3E2A22",
    hair_dark="#271813",
    hair_light="#634436",
    shirt="#4FB3A9",
    shirt_dark="#2F817A",
    hair_style="bob",
    iris="#6B4227",
    lip="#B4665C",
    brow="#4A3027",
)

MEHTA = Character(
    key="mehta",
    filename="Mehta_Dialogue.png",
    skin="#E3B091",
    skin_shadow="#C98E6E",
    skin_light="#F4CBAE",
    hair="#B7BCC4",
    hair_dark="#878D98",
    hair_light="#D8DDE4",
    shirt="#D2AA46",
    shirt_dark="#A9812C",
    hair_style="short",
    iris="#4A3527",
    lip="#9C5C52",
    brow="#8A8F99",
    has_glasses=True,
)

BLUE_GUY = Character(
    key="blue_guy",
    filename="npc_portrait_01.png",
    skin="#EDB183",
    skin_shadow="#D08C62",
    skin_light="#FFD2AC",
    hair="#7A4438",
    hair_dark="#4C2A24",
    hair_light="#B0775F",
    shirt="#4884FF",
    shirt_dark="#2E5FC4",
    hair_style="wavy",
    iris="#6A4A2E",
    lip="#A55E52",
    brow="#5E352B",
    has_beard=True,
)


def eye(cx: float, cy: float, expr: int, c: Character) -> str:
    lash = c.hair_dark
    if expr in (1, 3):
        return f"""
        <path d="M {cx - 10.8},{cy - 2.4} Q {cx},{cy + 5.4} {cx + 10.8},{cy - 2.4}"
              fill="none" stroke="{lash}" stroke-width="2.0" stroke-linecap="round"/>
        <path d="M {cx - 11.0},{cy - 2.6} Q {cx - 12.0},{cy - 4.0} {cx - 13.2},{cy - 4.2}"
              fill="none" stroke="{lash}" stroke-width="1.5" stroke-linecap="round"/>
        <path d="M {cx + 11.0},{cy - 2.6} Q {cx + 12.0},{cy - 4.0} {cx + 13.2},{cy - 4.2}"
              fill="none" stroke="{lash}" stroke-width="1.5" stroke-linecap="round"/>
        <path d="M {cx - 8.4},{cy + 1.6} Q {cx},{cy + 5.6} {cx + 8.4},{cy + 1.6}"
              fill="none" stroke="{c.skin_shadow}" stroke-width="1.0"
              stroke-linecap="round" opacity="0.55"/>
        """
    return f"""
    <ellipse cx="{cx}" cy="{cy}" rx="10.6" ry="8.3" fill="#FFFFFF"/>
    <ellipse cx="{cx}" cy="{cy}" rx="10.6" ry="8.3" fill="url(#eyeShadow)"/>
    <ellipse cx="{cx}" cy="{cy + 0.7}" rx="6.4" ry="6.9" fill="{c.iris}"/>
    <ellipse cx="{cx}" cy="{cy + 1.1}" rx="5.6" ry="6.0" fill="url(#irisGrad)"/>
    <ellipse cx="{cx}" cy="{cy + 1.5}" rx="2.9" ry="3.3" fill="#241611"/>
    <circle cx="{cx - 2.4}" cy="{cy - 2.4}" r="2.1" fill="#FFFFFF"/>
    <circle cx="{cx + 2.6}" cy="{cy + 2.6}" r="1.05" fill="#FFFFFF" opacity="0.8"/>
    <path d="M {cx - 10.7},{cy - 2.0} Q {cx},{cy - 8.9} {cx + 10.7},{cy - 2.0}"
          fill="none" stroke="{lash}" stroke-width="1.6" stroke-linecap="round"/>
    <path d="M {cx - 10.7},{cy - 2.0} Q {cx - 12.0},{cy - 3.4} {cx - 13.2},{cy - 3.6}"
          fill="none" stroke="{lash}" stroke-width="1.3" stroke-linecap="round"/>
    <path d="M {cx + 10.7},{cy - 2.0} Q {cx + 12.0},{cy - 3.4} {cx + 13.2},{cy - 3.6}"
          fill="none" stroke="{lash}" stroke-width="1.3" stroke-linecap="round"/>
    <path d="M {cx - 8.2},{cy + 5.6} Q {cx},{cy + 8.4} {cx + 8.2},{cy + 5.6}"
          fill="none" stroke="{c.skin_shadow}" stroke-width="0.9"
          stroke-linecap="round" opacity="0.6"/>
    <path d="M {cx - 7.6},{cy - 10.4} Q {cx},{cy - 12.4} {cx + 7.6},{cy - 10.4}"
          fill="none" stroke="{c.skin_shadow}" stroke-width="0.9"
          stroke-linecap="round" opacity="0.3"/>
    """


def brow(cx: float, cy: float, expr: int, c: Character) -> str:
    colour = c.brow or c.hair
    lift = -1.3 if expr in (2, 3) else 0.0
    return f"""
    <path d="M {cx - 9.6},{cy + 1.2 + lift} Q {cx - 1},{cy - 4.8 + lift} {cx + 9.8},{cy - 0.2 + lift}"
          fill="none" stroke="{colour}" stroke-width="1.4" stroke-linecap="round"
          opacity="0.92"/>
    """


def mouth(expr: int, c: Character) -> str:
    if expr in (2, 3):
        return f"""
        <path d="M 41.6,90.4 Q 50,86.2 58.4,90.4 Q 57.0,101.2 50,102.2 Q 43.0,101.2 41.6,90.4 Z"
              fill="{c.lip}" stroke="#7C3A33" stroke-width="0.9"/>
        <path d="M 43.4,91.2 Q 50,89.0 56.6,91.2 Q 55.0,94.2 50,94.6 Q 45.0,94.2 43.4,91.2 Z"
              fill="#FFF7EC"/>
        <ellipse cx="50" cy="99.0" rx="5.2" ry="2.5" fill="#D97C7C" opacity="0.9"/>
        """
    return f"""
    <path d="M 43.6,91.6 Q 50,96.4 56.4,91.6" fill="none" stroke="#8A4A44"
          stroke-width="1.6" stroke-linecap="round"/>
    <path d="M 46.4,95.0 Q 50,96.8 53.6,95.0" fill="none" stroke="{c.skin_shadow}"
          stroke-width="1.0" stroke-linecap="round" opacity="0.6"/>
    """


def hair_back(c: Character) -> str:
    if c.hair_style == "bob":
        return f"""
        <path d="M 17,64 C 16,31 31,12 50,12 C 69,12 84,31 83,64
                 C 84,84 84,100 85,110 C 84,118 76,121 71,115
                 C 70,102 69,94 67,87 L 33,87 C 31,94 30,102 29,115
                 C 24,121 16,118 15,110 C 16,100 16,84 17,64 Z"
              fill="url(#hairGrad)" stroke="{c.hair_dark}" stroke-width="1.0"/>
        <path d="M 21,58 C 21,34 33,20 50,20" fill="none" stroke="{c.hair_light}"
              stroke-width="2.0" stroke-linecap="round" opacity="0.5"/>
        <path d="M 79,58 C 79,34 67,20 50,20" fill="none" stroke="{c.hair_light}"
              stroke-width="1.5" stroke-linecap="round" opacity="0.32"/>
        <path d="M 20,88 C 19,98 19,108 21,114" fill="none" stroke="{c.hair_light}"
              stroke-width="1.4" stroke-linecap="round" opacity="0.35"/>
        <path d="M 80,88 C 81,98 81,108 79,114" fill="none" stroke="{c.hair_light}"
              stroke-width="1.4" stroke-linecap="round" opacity="0.35"/>
        """
    if c.hair_style == "wavy":
        return f"""
        <path d="M 14,68 C 12,33 29,10 50,10 C 71,10 88,33 86,68
                 C 88,86 87,102 90,116 C 86,126 76,124 74,114
                 C 71,118 65,116 67,107 L 65,85 L 35,85 L 33,107
                 C 35,116 29,118 26,114 C 24,124 14,126 10,116
                 C 13,102 12,86 14,68 Z"
              fill="url(#hairGrad)" stroke="{c.hair_dark}" stroke-width="1.0"/>
        <path d="M 18,60 C 17,32 32,17 50,17" fill="none" stroke="{c.hair_light}"
              stroke-width="2.2" stroke-linecap="round" opacity="0.5"/>
        <path d="M 82,62 C 83,36 68,18 52,17" fill="none" stroke="{c.hair_light}"
              stroke-width="1.7" stroke-linecap="round" opacity="0.35"/>
        <path d="M 19,78 C 22,88 20,98 17,106" fill="none" stroke="{c.hair_light}"
              stroke-width="1.6" stroke-linecap="round" opacity="0.38"/>
        <path d="M 23,94 C 25,104 23,112 20,118" fill="none" stroke="{c.hair_dark}"
              stroke-width="1.3" stroke-linecap="round" opacity="0.55"/>
        <path d="M 81,78 C 78,88 80,98 83,106" fill="none" stroke="{c.hair_light}"
              stroke-width="1.6" stroke-linecap="round" opacity="0.38"/>
        <path d="M 77,94 C 75,104 77,112 80,118" fill="none" stroke="{c.hair_dark}"
              stroke-width="1.3" stroke-linecap="round" opacity="0.55"/>
        """
    # short, side-parted
    return f"""
    <path d="M 22,58 C 21,31 32,18 50,18 C 67,18 79,31 78,56
             L 77,66 C 74,53 68,45 60,42 C 51,39 42,42 35,48
             C 30,52 26,56 23,62 Z"
          fill="url(#hairGrad)" stroke="{c.hair_dark}" stroke-width="1.0"/>
    <path d="M 26,46 C 35,28 48,22 63,25" fill="none" stroke="{c.hair_light}"
          stroke-width="2.0" stroke-linecap="round" opacity="0.55"/>
    <path d="M 43,23 C 39,31 35,40 32,50" fill="none" stroke="{c.hair_dark}"
          stroke-width="1.0" stroke-linecap="round" opacity="0.45"/>
    <path d="M 52,22 C 60,27 68,34 73,43" fill="none" stroke="{c.hair_light}"
          stroke-width="1.1" stroke-linecap="round" opacity="0.4"/>
    """


def hair_front(c: Character) -> str:
    if c.hair_style == "bob":
        return f"""
        <path d="M 23,54 C 23,30 35,20 50,20 C 65,20 77,30 77,54
                 C 73,46 67,42 60,44 C 54,40 46,40 39,44 C 32,42 27,46 23,54 Z"
              fill="url(#hairGrad)"/>
        <path d="M 28,42 C 33,31 40,25 48,23" fill="none" stroke="{c.hair_light}"
              stroke-width="1.7" stroke-linecap="round" opacity="0.55"/>
        <path d="M 56,23 C 65,26 72,34 75,46" fill="none" stroke="{c.hair_light}"
              stroke-width="1.2" stroke-linecap="round" opacity="0.4"/>
        <path d="M 42,30 C 38,35 35,41 34,48" fill="none" stroke="{c.hair_dark}"
              stroke-width="1.0" stroke-linecap="round" opacity="0.5"/>
        <path d="M 58,29 C 62,35 65,41 66,48" fill="none" stroke="{c.hair_dark}"
              stroke-width="1.0" stroke-linecap="round" opacity="0.5"/>
        """
    if c.hair_style == "wavy":
        return f"""
        <path d="M 22,54 C 23,29 35,19 50,19 C 65,19 77,29 78,54
                 C 73,46 67,42 60,44 C 54,40 46,40 39,44 C 31,42 26,46 22,54 Z"
              fill="url(#hairGrad)"/>
        <path d="M 27,42 C 31,31 38,24 46,22" fill="none" stroke="{c.hair_light}"
              stroke-width="1.9" stroke-linecap="round" opacity="0.55"/>
        <path d="M 56,22 C 66,26 73,35 76,49" fill="none" stroke="{c.hair_light}"
              stroke-width="1.3" stroke-linecap="round" opacity="0.4"/>
        <path d="M 41,29 C 37,35 34,41 33,48" fill="none" stroke="{c.hair_dark}"
              stroke-width="1.0" stroke-linecap="round" opacity="0.5"/>
        <path d="M 59,28 C 63,34 66,41 67,48" fill="none" stroke="{c.hair_dark}"
              stroke-width="1.0" stroke-linecap="round" opacity="0.5"/>
        """
    # short side part with a soft swept fringe
    return f"""
    <path d="M 22,54 C 23,30 34,20 50,20 C 65,20 77,30 77,51
             C 70,43 62,40 54,41 C 45,42 36,45 30,54 Z"
          fill="url(#hairGrad)" stroke="{c.hair_dark}" stroke-width="0.7"/>
    <path d="M 28,41 C 36,28 48,23 60,25" fill="none" stroke="{c.hair_light}"
          stroke-width="1.5" stroke-linecap="round" opacity="0.55"/>
    <path d="M 46,21 C 42,29 37,38 32,47" fill="none" stroke="{c.hair_light}"
          stroke-width="1.0" stroke-linecap="round" opacity="0.45"/>
    """


def clothing(c: Character) -> str:
    if c.key == "priya":
        return f"""
        <path d="M 42,112 L 50,126 L 58,112" fill="none" stroke="#EFF7F4"
              stroke-width="2.4" stroke-linejoin="round"/>
        <path d="M 50,126 L 50,148" fill="none" stroke="{c.shirt_dark}"
              stroke-width="0.9" opacity="0.5"/>
        <rect x="63" y="131" width="19" height="13" rx="2" fill="#F7FAF8"
              stroke="#BFD8D4" stroke-width="0.8"/>
        <path d="M 66,135 L 79,135 M 66,138.5 L 75,138.5" stroke="#7FA9A3"
              stroke-width="1.0" stroke-linecap="round"/>
        <path d="M 63,131 L 58,124" stroke="#BFD8D4" stroke-width="1.0"/>
        """
    if c.key == "mehta":
        return f"""
        <path d="M 42,112 L 50,126 L 58,112 L 54,109 L 50,115 L 46,109 Z"
              fill="#F2EAD7" stroke="#D8C8A8" stroke-width="0.7"/>
        <path d="M 50,126 L 50,148" fill="none" stroke="{c.shirt_dark}"
              stroke-width="0.9" opacity="0.6"/>
        <circle cx="50" cy="134" r="1.1" fill="#8A6A22"/>
        <circle cx="50" cy="141" r="1.1" fill="#8A6A22"/>
        """
    # blue t-shirt with a simple crew neck
    return f"""
    <path d="M 37,114 C 37,106 43,103 50,103 C 57,103 63,106 63,114
             C 57,116 43,116 37,114 Z"
          fill="{c.shirt_dark}"/>
    <path d="M 39,108 C 42,104 46,103 50,103 C 54,103 58,104 61,108"
          fill="none" stroke="#7FA7FF" stroke-width="1.1"
          stroke-linecap="round" opacity="0.55"/>
    """


def glasses(c: Character) -> str:
    if not c.has_glasses:
        return ""
    return f"""
    <g fill="none" stroke="#4A3826" stroke-width="1.25">
        <rect x="24.8" y="59.0" width="25.0" height="17.4" rx="3.6"/>
        <rect x="50.2" y="59.0" width="25.0" height="17.4" rx="3.6"/>
        <path d="M 49.4,65.2 Q 50,64.4 50.6,65.2" stroke-width="1.0"/>
        <path d="M 24.8,64.2 L 21,66.2" stroke-width="1.0"/>
        <path d="M 75.2,64.2 L 79,66.2" stroke-width="1.0"/>
    </g>
    <path d="M 27,61.6 L 40,61.6" stroke="#FFFFFF" stroke-width="0.9"
          stroke-linecap="round" opacity="0.5"/>
    <path d="M 53,61.6 L 66,61.6" stroke="#FFFFFF" stroke-width="0.9"
          stroke-linecap="round" opacity="0.5"/>
    """


def beard(c: Character) -> str:
    if not c.has_beard:
        return ""
    return f"""
    <path d="M 24,70 C 25,92 36,103 50,104 C 64,103 75,92 76,70
             C 71,74 66,77 63,78 C 62,83 62,86 62,86
             L 61,92 C 60,98 56,100 50,100 C 44,100 40,98 39,92
             L 38,86 C 38,86 38,83 37,78 C 34,77 29,74 24,70 Z"
          fill="{c.hair_dark}" stroke="{c.hair_dark}" stroke-width="0.9"/>
    <ellipse cx="50" cy="92.8" rx="9.6" ry="6.8" fill="{c.skin}"
             stroke="{c.skin_shadow}" stroke-width="0.7"/>
    <path d="M 41.5,89.4 Q 50,93.2 58.5,89.4" fill="none"
          stroke="{c.skin_shadow}" stroke-width="0.9" opacity="0.5"/>
    <path d="M 41.6,84.2 Q 46,82.6 49.2,84.6 Q 50,85.4 50.8,84.6
             Q 54,82.6 58.4,84.2 Q 55.6,87.4 50,87.4 Q 44.4,87.4 41.6,84.2 Z"
          fill="{c.hair_dark}" stroke="{c.hair_dark}" stroke-width="0.6"/>
    <path d="M 31,80 C 34,90 39,97 46,100" fill="none" stroke="{c.hair_light}"
          stroke-width="1.1" stroke-linecap="round" opacity="0.45"/>
    <path d="M 69,80 C 66,90 61,97 54,100" fill="none" stroke="{c.hair_light}"
          stroke-width="1.1" stroke-linecap="round" opacity="0.45"/>
    <path d="M 44,97 C 47,100 53,100 56,97" fill="none" stroke="{c.hair_light}"
          stroke-width="0.8" stroke-linecap="round" opacity="0.35"/>
    """


def frame_svg(c: Character, expr: int) -> str:
    happy = expr in (2, 3)

    return f"""
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2F7FD6"/>
      <stop offset="0.55" stop-color="#57A8EA"/>
      <stop offset="1" stop-color="#9BD4F5"/>
    </linearGradient>
    <linearGradient id="skinGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{c.skin_light}"/>
      <stop offset="0.5" stop-color="{c.skin}"/>
      <stop offset="1" stop-color="{c.skin_shadow}"/>
    </linearGradient>
    <linearGradient id="hairGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{c.hair}"/>
      <stop offset="0.55" stop-color="{c.hair}"/>
      <stop offset="1" stop-color="{c.hair_dark}"/>
    </linearGradient>
    <radialGradient id="blush" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#F58E83" stop-opacity="0.6"/>
      <stop offset="1" stop-color="#F58E83" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="eyeShadow" cx="0.5" cy="0.2" r="0.8">
      <stop offset="0" stop-color="#C9D7E8" stop-opacity="0"/>
      <stop offset="0.7" stop-color="#C9D7E8" stop-opacity="0"/>
      <stop offset="1" stop-color="#8FA3BC" stop-opacity="0.35"/>
    </radialGradient>
    <linearGradient id="irisGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#B7824D"/>
      <stop offset="0.5" stop-color="{c.iris}"/>
      <stop offset="1" stop-color="#2C1B12"/>
    </linearGradient>
    <linearGradient id="shirtGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{c.shirt}"/>
      <stop offset="1" stop-color="{c.shirt_dark}"/>
    </linearGradient>
    <linearGradient id="bottomShade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#000000" stop-opacity="0"/>
      <stop offset="1" stop-color="#000000" stop-opacity="0.18"/>
    </linearGradient>
    <clipPath id="frameClip">
      <rect x="3" y="3" width="94" height="142" rx="10"/>
    </clipPath>
  </defs>

  <rect x="0.5" y="0.5" width="99" height="147" rx="12" fill="url(#sky)"/>
  <g clip-path="url(#frameClip)">
    <!-- sky clouds -->
    <ellipse cx="18" cy="20" rx="17" ry="8" fill="#FFFFFF" opacity="0.9"/>
    <ellipse cx="34" cy="15" rx="12" ry="6" fill="#FFFFFF" opacity="0.75"/>
    <ellipse cx="82" cy="30" rx="18" ry="8" fill="#FFFFFF" opacity="0.85"/>
    <ellipse cx="68" cy="22" rx="11" ry="5" fill="#FFFFFF" opacity="0.6"/>
    <ellipse cx="12" cy="43" rx="12" ry="5" fill="#FFFFFF" opacity="0.4"/>
    <ellipse cx="92" cy="52" rx="14" ry="6" fill="#FFFFFF" opacity="0.3"/>

    <!-- neck -->
    <path d="M 41,92 L 41,115 C 44,120 56,120 59,115 L 59,92 Z"
          fill="{c.skin}" stroke="{c.skin_shadow}" stroke-width="0.8"/>
    <path d="M 41,94 C 45,99 55,99 59,94 L 59,104 C 54,108 46,108 41,104 Z"
          fill="{c.skin_shadow}" opacity="0.38"/>

    <!-- shoulders / torso -->
    <path d="M 2,148 L 2,138 C 12,122 30,114 41,113 L 59,113
             C 70,114 88,122 98,138 L 98,148 Z"
          fill="url(#shirtGrad)"/>

    <!-- hair behind the head -->
    {hair_back(c)}

    <!-- head -->
    <path d="M 23,58 C 23,31 33,20 50,20 C 67,20 77,31 77,58
             C 77,82 68,100 50,102 C 32,100 23,82 23,58 Z"
          fill="url(#skinGrad)" stroke="{c.skin_shadow}" stroke-width="0.9"/>
    <ellipse cx="23.4" cy="69" rx="3.6" ry="5.6" fill="{c.skin}"
             stroke="{c.skin_shadow}" stroke-width="0.8"/>
    <ellipse cx="76.6" cy="69" rx="3.6" ry="5.6" fill="{c.skin}"
             stroke="{c.skin_shadow}" stroke-width="0.8"/>
    <path d="M 24,67 C 26,70 26,74 24,76" fill="none" stroke="{c.skin_shadow}"
          stroke-width="0.9" opacity="0.55"/>
    <path d="M 76,67 C 74,70 74,74 76,76" fill="none" stroke="{c.skin_shadow}"
          stroke-width="0.9" opacity="0.55"/>

    <!-- soft forehead shading -->
    <path d="M 27,44 C 30,30 40,24 50,24 C 60,24 70,30 73,44
             C 68,36 60,32 50,32 C 40,32 32,36 27,44 Z"
          fill="{c.skin_shadow}" opacity="0.12"/>

    <!-- eyes + brows -->
    {eye(37.5, 68.5, expr, c)}
    {eye(62.5, 68.5, expr, c)}
    {brow(37.5, 56.8 if c.has_glasses else 58.2, expr, c)}
    {brow(62.5, 56.8 if c.has_glasses else 58.2, expr, c)}

    <!-- nose -->
    <path d="M 50,77 C 48.9,80.6 49.3,82.8 51.4,83.5" fill="none"
          stroke="{c.skin_shadow}" stroke-width="1.0" stroke-linecap="round"/>
    <path d="M 48.6,83.4 C 49.9,84.3 51.5,84.1 52.5,83.4" fill="none"
          stroke="{c.skin_shadow}" stroke-width="0.9" stroke-linecap="round"
          opacity="0.65"/>
    <circle cx="48.9" cy="83.6" r="0.55" fill="{c.skin_shadow}" opacity="0.5"/>

    <!-- blush -->
    <ellipse cx="30.5" cy="81" rx="10" ry="5.4" fill="url(#blush)"
             opacity="{1.0 if happy else 0.65}"/>
    <ellipse cx="69.5" cy="81" rx="10" ry="5.4" fill="url(#blush)"
             opacity="{1.0 if happy else 0.65}"/>

    {beard(c)}
    {mouth(expr, c)}
    {glasses(c)}
    {hair_front(c)}
    {clothing(c)}

    <!-- soft bottom shading -->
    <rect x="3" y="116" width="94" height="29" fill="url(#bottomShade)"/>

    <!-- frame edge -->
    <rect x="3" y="3" width="94" height="142" rx="10" fill="none"
          stroke="#FFFFFF" stroke-width="4.5"/>
    <rect x="3" y="3" width="94" height="142" rx="10" fill="none"
          stroke="#D6DCE2" stroke-width="1.1"/>
  </g>
  <rect x="0.5" y="0.5" width="99" height="147" rx="12" fill="none"
        stroke="#FFFFFF" stroke-width="1.6"/>
</svg>
"""


def render_strip(character: Character) -> None:
    frames: list[Image.Image] = []
    with tempfile.TemporaryDirectory() as tmp:
        for expr in range(4):
            svg_path = os.path.join(tmp, f"{character.key}_{expr}.svg")
            png_path = os.path.join(tmp, f"{character.key}_{expr}.png")
            with open(svg_path, "w", encoding="utf-8") as fh:
                fh.write(frame_svg(character, expr))
            subprocess.run(
                ["rsvg-convert", "-w", str(W * SCALE), "-h", str(H * SCALE),
                 "-o", png_path, svg_path],
                check=True,
            )
            frame = Image.open(png_path).convert("RGBA")
            frame = frame.resize((W, H), Image.LANCZOS)
            frames.append(frame)

    strip = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.paste(frame, (index * W, 0), frame)

    target = os.path.join(OUT_DIR, character.filename)
    strip.save(target)
    print("wrote", target)


def main() -> None:
    if shutil.which("rsvg-convert") is None:
        raise SystemExit("rsvg-convert is required (brew install librsvg)")
    for character in (PRIYA, MEHTA, BLUE_GUY):
        render_strip(character)


if __name__ == "__main__":
    main()
