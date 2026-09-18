#!/usr/bin/env python3
"""Sinh logo Echora và toàn bộ app icon cho Android/iOS.

Chạy: python3 tool/generate_icons.py
Cần: Pillow. Script này không phải dependency của app, chỉ dùng khi đổi logo.
"""

import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VIOLET = (91, 75, 216, 255)
VIOLET_DEEP = (58, 45, 168, 255)
PAPER = (251, 248, 243, 255)
CLAY = (232, 150, 110, 255)

SS = 4  # supersample


def _blend(base, box, radius, color):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius=radius, fill=color)
    return Image.alpha_composite(base, layer)


def _mark(img, box, ink=PAPER, accent=CLAY):
    """Ba dòng chữ mờ dần sau viền trái — câu đang đọc và tiếng vọng của nó."""
    x0, y0, w, h = box
    bar_h = h * 0.208
    spine_w = w * 0.092
    gap = (h - 3 * bar_h) / 2

    img = _blend(img, [x0, y0, x0 + spine_w, y0 + h], spine_w / 2, accent)

    text_x = x0 + w * 0.255
    for i, (alpha, length) in enumerate(((255, 1.0), (170, 0.78), (95, 0.52))):
        top = y0 + i * (bar_h + gap)
        right = text_x + (x0 + w - text_x) * length
        img = _blend(
            img,
            [text_x, top, right, top + bar_h],
            bar_h / 2,
            (ink[0], ink[1], ink[2], alpha),
        )
    return img


def render_logo(size, background=True):
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    if background:
        img = _blend(img, [0, 0, s - 1, s - 1], int(s * 0.225), VIOLET)

    side = s * 0.50
    img = _mark(img, (s * 0.26, s * 0.275, side, s * 0.45))
    return img.resize((size, size), Image.LANCZOS)


def render_foreground(size):
    """Adaptive icon foreground: mark nằm trong safe zone 66%."""
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    side = s * 0.33
    img = _mark(img, (s * 0.336, s * 0.351, side, s * 0.297))
    return img.resize((size, size), Image.LANCZOS)


def write(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("  ", os.path.relpath(path, ROOT))


def main():
    print("branding")
    write(render_logo(1024), os.path.join(ROOT, "assets/branding/logo.png"))
    write(render_logo(512, background=False), os.path.join(ROOT, "assets/branding/mark.png"))

    print("android")
    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = os.path.join(ROOT, "android/app/src/main/res")
    for folder, px in android.items():
        write(render_logo(px), os.path.join(res, folder, "ic_launcher.png"))
        write(render_foreground(int(px * 108 / 48)), os.path.join(res, folder, "ic_launcher_foreground.png"))

    print("ios")
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40, "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29, "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80, "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120, "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76, "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    appicon = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
    for name, px in ios_sizes.items():
        img = render_logo(px)
        if px == 1024:
            flat = Image.new("RGB", (px, px), VIOLET[:3])
            flat.paste(img, (0, 0), img)
            img = flat
        write(img, os.path.join(appicon, name))


if __name__ == "__main__":
    main()
