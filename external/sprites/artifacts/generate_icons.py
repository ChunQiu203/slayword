from PIL import Image, ImageDraw
import math
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

def rounded_rect_mask(size, radius):
    mask = Image.new('L', size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return mask

def draw_background(draw, img):
    mask = rounded_rect_mask((128, 128), 20)
    bg = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    bg_draw.rectangle([0, 0, 127, 127], fill=(26, 39, 68, 255))
    img.paste(bg, (0, 0), mask)

def draw_star(draw, cx, cy, outer_r, inner_r, points, fill, outline=None):
    coords = []
    for i in range(points * 2):
        angle = math.pi / 2 + i * math.pi / points
        r = outer_r if i % 2 == 0 else inner_r
        x = cx + r * math.cos(angle)
        y = cy - r * math.sin(angle)
        coords.append((x, y))
    draw.polygon(coords, fill=fill, outline=outline)

def draw_small_stars(draw, positions):
    for x, y in positions:
        draw_star(draw, x, y, 2.5, 1, 4, (200, 220, 255, 180))

# --- 1. Brass Astrolabe ---
def draw_brass_astrolabe():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    brass = (205, 170, 80)
    brass_light = (230, 200, 120)
    brass_dark = (160, 130, 50)

    cx, cy = 64, 64

    draw.ellipse([18, 18, 110, 110], fill=brass, outline=brass_dark, width=3)
    draw.ellipse([28, 28, 100, 100], fill=(22, 34, 58), outline=brass, width=2)
    draw.ellipse([38, 38, 90, 90], fill=brass_dark, outline=brass_light, width=2)

    for i in range(12):
        angle = i * math.pi / 6
        x1 = cx + 20 * math.cos(angle)
        y1 = cy + 20 * math.sin(angle)
        x2 = cx + 32 * math.cos(angle)
        y2 = cy + 32 * math.sin(angle)
        draw.line([(x1, y1), (x2, y2)], fill=brass_light, width=2)

    draw.ellipse([58, 58, 70, 70], fill=brass_light, outline=brass, width=1)

    for i in range(8):
        angle = i * math.pi / 4
        x1 = cx + 40 * math.cos(angle)
        y1 = cy + 40 * math.sin(angle)
        draw.line([(cx, cy), (x1, y1)], fill=(brass_light[0], brass_light[1], brass_light[2], 100), width=1)

    draw.ellipse([44, 44, 84, 84], outline=brass_light, width=1)

    img.save(os.path.join(OUTPUT_DIR, 'artifact_brass_astrolabe.png'))

# --- 2. Star Map ---
def draw_star_map():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    scroll = (180, 160, 120)
    scroll_light = (210, 190, 150)

    draw.rounded_rectangle([20, 10, 108, 118], radius=5, fill=scroll, outline=(140, 120, 80), width=2)
    draw.rounded_rectangle([24, 14, 104, 114], radius=3, fill=(22, 34, 58))

    stars = [(40, 35), (70, 30), (90, 50), (55, 55), (35, 75), (80, 80), (50, 95), (95, 70), (28, 50)]
    for x, y in stars:
        draw_star(draw, x, y, 4, 2, 5, (220, 230, 255))

    lines = [(0, 1), (1, 2), (1, 3), (3, 4), (4, 6), (3, 5), (5, 7), (4, 8), (0, 8), (2, 7)]
    for a, b in lines:
        draw.line([stars[a], stars[b]], fill=(150, 180, 220, 140), width=1)

    for x, y in [(30, 45), (60, 40), (75, 60), (45, 80), (85, 90)]:
        draw.ellipse([x-1, y-1, x+1, y+1], fill=(180, 200, 240, 120))

    img.save(os.path.join(OUTPUT_DIR, 'artifact_star_map.png'))

# --- 3. Lens of Clarity ---
def draw_lens_of_clarity():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    cx, cy = 64, 60

    for r, alpha in [(42, 40), (38, 60), (34, 80)]:
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(100, 180, 240, alpha), outline=(150, 200, 255, 120), width=1)

    draw.ellipse([cx-28, cy-28, cx+28, cy+28], fill=(140, 210, 255, 180), outline=(180, 220, 255, 200), width=2)

    for i in range(8):
        angle = i * math.pi / 4
        x1 = cx + 20 * math.cos(angle)
        y1 = cy + 20 * math.sin(angle)
        x2 = cx + 35 * math.cos(angle)
        y2 = cy + 35 * math.sin(angle)
        draw.line([(x1, y1), (x2, y2)], fill=(220, 240, 255, 80), width=1)

    draw_star(draw, cx, cy, 8, 3, 4, (255, 255, 255, 200))

    for dx, dy in [(-12, -12), (15, -8), (-8, 14), (10, 12)]:
        draw_star(draw, cx+dx, cy+dy, 3, 1, 4, (200, 230, 255, 160))

    draw.arc([cx-50, cy-4, cx+50, cy+20], start=0, end=180, fill=(180, 160, 140), width=3)

    img.save(os.path.join(OUTPUT_DIR, 'artifact_lens_of_clarity.png'))

# --- 4. Mercury's Quill ---
def draw_mercury_quill():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    quill_body = [(45, 100), (55, 95), (65, 40), (60, 20), (50, 25), (42, 60), (38, 95)]
    draw.polygon(quill_body, fill=(200, 200, 210), outline=(160, 160, 180))

    draw.polygon([(50, 25), (60, 20), (68, 30), (55, 45)], fill=(220, 220, 230))
    draw.polygon([(42, 40), (50, 25), (45, 55)], fill=(180, 180, 200))

    draw.polygon([(38, 95), (55, 95), (52, 105), (42, 108)], fill=(80, 80, 100))

    glow_r = 22
    for r in range(glow_r, 0, -2):
        alpha = int(40 * (1 - r / glow_r))
        draw.ellipse([55-r, 20-r, 55+r, 20+r], fill=(100, 180, 255, alpha))

    draw_star(draw, 55, 20, 6, 2, 4, (200, 230, 255, 200))

    for dx, dy in [(-10, -5), (12, -3), (5, -12), (-8, 8)]:
        draw_star(draw, 55+dx, 20+dy, 2, 0.8, 4, (180, 220, 255, 150))

    img.save(os.path.join(OUTPUT_DIR, 'artifact_mercury_quill.png'))

# --- 5. Eclipse Prism ---
def draw_eclipse_prism():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    prism_pts = [(64, 20), (30, 100), (98, 100)]
    draw.polygon(prism_pts, fill=(60, 60, 100), outline=(140, 140, 200), width=2)

    inner = [(64, 35), (42, 90), (86, 90)]
    draw.polygon(inner, fill=(40, 40, 70))

    for r in range(18, 0, -2):
        alpha = int(50 * (1 - r / 18))
        draw.ellipse([64-r, 55-r, 64+r, 55+r], fill=(255, 200, 50, alpha))

    colors = [(255, 80, 80, 180), (255, 200, 50, 180), (50, 200, 100, 180), (80, 120, 255, 180), (180, 80, 220, 180)]
    for i, color in enumerate(colors):
        angle = -math.pi / 6 + i * math.pi / 15
        x1 = 64 + 15 * math.cos(angle)
        y1 = 55 + 15 * math.sin(angle)
        x2 = 64 + 50 * math.cos(angle - 0.3)
        y2 = 55 + 50 * math.sin(angle - 0.3)
        draw.line([(x1, y1), (x2, y2)], fill=color, width=2)

    draw_star(draw, 64, 55, 5, 2, 5, (255, 240, 200, 200))

    img.save(os.path.join(OUTPUT_DIR, 'artifact_eclipse_prism.png'))

# --- 6. Saturn's Ring ---
def draw_saturn_ring():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    cx, cy = 64, 62

    draw.ellipse([cx-20, cy-20, cx+20, cy+20], fill=(180, 160, 120), outline=(200, 180, 140), width=2)
    draw.ellipse([cx-14, cy-14, cx+14, cy+14], fill=(160, 140, 100))
    draw.ellipse([cx-8, cy-8, cx+8, cy+8], fill=(140, 120, 80))

    for i in range(4):
        angle = i * math.pi / 2 + math.pi / 6
        x = cx + 10 * math.cos(angle)
        y = cy + 10 * math.sin(angle)
        draw.line([(cx, cy), (x, y)], fill=(120, 100, 70), width=1)

    for i in range(2):
        for angle in range(0, 360, 3):
            rad = math.radians(angle)
            r = 36 + i * 6
            x = cx + r * math.cos(rad)
            y = cy + r * 0.35 * math.sin(rad)
            alpha = 180 - abs(angle - 180)
            c = int(180 + 40 * (1 - abs(angle - 180) / 180))
            draw.ellipse([x-1, y-1, x+1, y+1], fill=(c, c-20, c-60, max(alpha, 60)))

    draw.ellipse([cx-42, cy-18, cx+42, cy+18], outline=(200, 180, 140, 160), width=2)
    draw.ellipse([cx-36, cy-14, cx+36, cy+14], outline=(180, 160, 120, 120), width=1)

    for r in range(10, 0, -1):
        alpha = int(30 * (1 - r / 10))
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(240, 220, 180, alpha))

    img.save(os.path.join(OUTPUT_DIR, 'artifact_saturn_ring.png'))

# --- 7. Cosmic Clock ---
def draw_cosmic_clock():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    cx, cy = 64, 64

    draw.ellipse([18, 18, 110, 110], fill=(40, 45, 70), outline=(140, 160, 200), width=3)
    draw.ellipse([26, 26, 102, 102], fill=(28, 38, 62), outline=(120, 140, 180), width=1)

    markers = []
    for i in range(12):
        angle = i * math.pi / 6 - math.pi / 2
        x1 = cx + 36 * math.cos(angle)
        y1 = cy + 36 * math.sin(angle)
        x2 = cx + 40 * math.cos(angle)
        y2 = cy + 40 * math.sin(angle)
        draw.line([(x1, y1), (x2, y2)], fill=(180, 200, 240, 200), width=2 if i % 3 == 0 else 1)
        mx = cx + 32 * math.cos(angle)
        my = cy + 32 * math.sin(angle)
        markers.append((mx, my))

    draw.line([(cx, cy), (cx + 25, cy - 10)], fill=(220, 230, 255), width=2)
    draw.line([(cx, cy), (cx - 5, cy + 20)], fill=(200, 210, 240), width=1)

    draw.ellipse([cx-3, cy-3, cx+3, cy+3], fill=(220, 230, 255))

    for x, y in [(40, 40), (88, 38), (42, 88), (86, 86)]:
        draw_star(draw, x, y, 3, 1.2, 4, (180, 200, 240, 160))

    draw_star(draw, cx, cy - 48, 4, 1.5, 5, (200, 220, 255, 180))

    img.save(os.path.join(OUTPUT_DIR, 'artifact_cosmic_clock.png'))

# --- 8. Nebula Gem ---
def draw_nebula_gem():
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_background(draw, img)

    cx, cy = 64, 64

    for r in range(40, 0, -1):
        t = r / 40
        red = int(60 + 120 * (1 - t))
        green = int(20 + 60 * (1 - t))
        blue = int(120 + 135 * (1 - t))
        alpha = int(50 * (1 - t))
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(red, green, blue, alpha))

    gem_pts = [(64, 22), (88, 50), (78, 98), (50, 98), (40, 50)]
    draw.polygon(gem_pts, fill=(100, 50, 180), outline=(160, 100, 240), width=2)

    inner_pts = [(64, 32), (80, 52), (72, 90), (56, 90), (48, 52)]
    draw.polygon(inner_pts, fill=(80, 40, 160))

    highlight_pts = [(64, 35), (72, 50), (64, 55), (56, 50)]
    draw.polygon(highlight_pts, fill=(160, 120, 220, 150))

    for x, y in [(50, 45), (78, 55), (60, 80), (70, 75)]:
        draw_star(draw, x, y, 2, 0.8, 4, (200, 180, 255, 150))

    for dx, dy in [(-15, -10), (18, -5), (10, 18), (-12, 15)]:
        draw_star(draw, cx+dx, cy+dy, 3, 1, 5, (180, 160, 240, 120))

    img.save(os.path.join(OUTPUT_DIR, 'artifact_nebula_gem.png'))

if __name__ == '__main__':
    draw_brass_astrolabe()
    draw_star_map()
    draw_lens_of_clarity()
    draw_mercury_quill()
    draw_eclipse_prism()
    draw_saturn_ring()
    draw_cosmic_clock()
    draw_nebula_gem()
    print("All 8 artifact icons generated successfully!")
