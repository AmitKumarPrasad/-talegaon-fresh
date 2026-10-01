"""Generates the FRESHORA app icon (1024x1024 PNG) matching the in-app FreshoraLogo widget."""
from PIL import Image, ImageDraw

SIZE = 1024
GREEN_DARK = (11, 91, 44)
GREEN_BRIGHT = (21, 148, 71)
YELLOW = (255, 215, 63)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Radial-ish gradient circle background (dark green -> bright green)
cx, cy, r = SIZE // 2, SIZE // 2, SIZE // 2
steps = 160
for i in range(steps, 0, -1):
    t = i / steps
    rr = int(GREEN_DARK[0] + (GREEN_BRIGHT[0] - GREEN_DARK[0]) * (1 - t))
    gg = int(GREEN_DARK[1] + (GREEN_BRIGHT[1] - GREEN_DARK[1]) * (1 - t))
    bb = int(GREEN_DARK[2] + (GREEN_BRIGHT[2] - GREEN_DARK[2]) * (1 - t))
    rad = int(r * t)
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(rr, gg, bb, 255))

# Leaf mark (two overlapping ellipses rotated) in yellow, centered
leaf = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
leaf_draw = ImageDraw.Draw(leaf)
lw, lh = int(SIZE * 0.34), int(SIZE * 0.56)
leaf_draw.ellipse([(SIZE - lw) // 2, (SIZE - lh) // 2, (SIZE + lw) // 2, (SIZE + lh) // 2], fill=YELLOW)
leaf = leaf.rotate(45, resample=Image.BICUBIC, center=(SIZE / 2, SIZE / 2))
img.alpha_composite(leaf)

# Leaf vein
draw.line([(cx, cy - int(SIZE * 0.22)), (cx, cy + int(SIZE * 0.22))], fill=GREEN_DARK, width=max(2, SIZE // 120))

img.save("assets/images/app_icon.png")
print("Saved assets/images/app_icon.png")
