# Generate 32x32 wall/floor textures and all data tables for 144mb-samurai
# Uses Perlin-style value noise (math + random stdlib only)
# Outputs: tex_gen.inc, palette_data.inc, shade_data.inc

import math, random, struct

# ============================================================
# NOISE FUNCTIONS
# ============================================================
rng = random.Random(1337)
PERM = list(range(256))
rng.shuffle(PERM)
PERM = PERM * 2

def _fade(t):
    return t * t * t * (t * (t * 6 - 15) + 10)

def _lerp(a, b, t):
    return a + t * (b - a)

def _grad(h, x, y):
    g = h & 3
    return (x if (g & 1) == 0 else -x) + (y if (g & 2) == 0 else -y)

def noise(x, y):
    xi = int(math.floor(x)) & 255
    yi = int(math.floor(y)) & 255
    xf = x - math.floor(x)
    yf = y - math.floor(y)
    u = _fade(xf)
    v = _fade(yf)
    aa = PERM[PERM[xi] + yi]
    ab = PERM[PERM[xi] + yi + 1]
    ba = PERM[PERM[xi + 1] + yi]
    bb = PERM[PERM[xi + 1] + yi + 1]
    n0 = _lerp(_grad(aa, xf, yf), _grad(ba, xf - 1, yf), u)
    n1 = _lerp(_grad(ab, xf, yf - 1), _grad(bb, xf - 1, yf - 1), u)
    return _lerp(n0, n1, v)

def fbm(x, y, octaves=3, lacunarity=2.0, gain=0.5):
    v = 0.0
    a = 1.0
    f = 1.0
    mx = 0.0
    for _ in range(octaves):
        v += noise(x * f, y * f) * a
        mx += a
        a *= gain
        f *= lacunarity
    return v / mx

def cell_noise(x, y, scale=1.0):
    """Simple cellular/Voronoi-like pattern"""
    ix = int(math.floor(x * scale))
    iy = int(math.floor(y * scale))
    fx = x * scale - ix
    fy = y * scale - iy
    min_dist = 999.0
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            h = PERM[PERM[(ix + dx) & 255] + (iy + dy) & 255]
            px = dx + (h & 15) / 16.0
            py = dy + ((h >> 4) & 15) / 16.0
            d = (fx - px) ** 2 + (fy - py) ** 2
            if d < min_dist:
                min_dist = d
    return min_dist

# ============================================================
# TEXTURE GENERATORS
# ============================================================

def gen_brick():
    """Staggered brick wall with noise variation per brick"""
    rows = []
    brick_h = 8
    brick_w = 16
    for y in range(32):
        row = []
        brick_row = y // brick_h
        offset = (brick_row & 1) * (brick_w // 2)
        for x in range(32):
            local_x = (x + offset) % brick_w
            if local_x == 0 or local_x == brick_w - 1 or (y % brick_h) == 0 or (y % brick_h) == brick_h - 1:
                # Mortar line
                n = noise(x * 0.3, y * 0.3)
                row.append(1 + int(n * 1.5))
            else:
                # Brick surface with variation
                n = fbm(x * 0.2, y * 0.2, 2, 2.0, 0.5)
                v = 3 + int((n + 0.5) * 3)
                if v < 3: v = 3
                if v > 7: v = 7
                row.append(v)
        rows.append(row)
    return rows

def gen_stone():
    """Rough stone wall with irregular block shapes via cell noise"""
    rows = []
    for y in range(32):
        row = []
        for x in range(32):
            # Cell noise for block boundaries
            c = cell_noise(x, y, 0.25)
            # Surface roughness via fbm
            n = fbm(x * 0.3, y * 0.3, 3, 2.0, 0.6)
            # Block boundary = darker mortar
            if c < 0.02:
                v = 1 + int(abs(noise(x, y)) * 2)
            else:
                v = 3 + int((n + 1.0) * 2.0)
                if v < 3: v = 3
                if v > 7: v = 7
                # Random darker stone block
                bx = int(x / 8)
                by = int(y / 8)
                if PERM[(bx + by * 7) & 255] & 3 == 0:
                    v = min(v, 5)
            row.append(v)
        rows.append(row)
    return rows

def gen_wood_shop():
    """Shop front with wood grain, noren curtain, counter"""
    rows = []
    # Place 3 knot holes randomly
    knot_seed = random.Random(42)
    knots = [(knot_seed.randint(6, 26), knot_seed.randint(6, 26), 4) for _ in range(3)]
    for y in range(32):
        row = []
        for x in range(32):
            if y < 4:
                # Roof tiles
                row.append(5 if (y & 1) else 7)
            elif y < 6:
                # Eaves shadow
                row.append(6)
            elif y < 13:
                # Noren curtain area
                if y == 6:
                    row.append(7)  # Top bar
                elif x == 15 or x == 16:
                    row.append(2)  # Center slit
                elif x < 4 or x > 27:
                    row.append(6)  # Edge posts
                else:
                    # Curtain with pattern noise
                    n = fbm(x * 0.15, y * 0.2, 2, 2.5, 0.5)
                    v = 3 + int(n * 2)
                    if v < 1: v = 1
                    if v > 5: v = 5
                    # Horizontal stripe pattern
                    if y & 1:
                        v = max(1, v - 1)
                    row.append(v)
            elif y < 17:
                # Counter
                if y == 13:
                    row.append(7)  # Counter top
                elif y == 15:
                    row.append(6)  # Counter edge
                elif x < 4 or x > 27:
                    row.append(6)  # Side posts
                else:
                    row.append(4 if y == 14 else 3)
            elif y < 28:
                # Lower wood planks with grain
                n = fbm(x * 0.08, y * 0.8, 3, 2.0, 0.5)
                v = 2 + int((n + 1.0) * 2.5)
                if v < 1: v = 1
                if v > 7: v = 7
                # Knot holes
                for kx, ky, kr in knots:
                    if ((x - kx)**2 + (y - 28 - ky)**2) < kr**2:
                        v = min(v + 2, 7)
                # Plank boundaries
                if y % 5 == 0:
                    v = max(1, v - 2)
                row.append(v)
            else:
                # Foundation
                n = cell_noise(x, y, 0.3)
                if n < 0.03:
                    row.append(2)
                else:
                    row.append(6 if y == 31 else 5)
        rows.append(row)
    return rows

def gen_burnt():
    """Charred building with visible structure and burn hole"""
    rows = []
    for y in range(32):
        row = []
        for x in range(32):
            # Base char texture
            n = fbm(x * 0.2, y * 0.2, 3, 2.0, 0.6)

            # Roof area
            if y < 5:
                v = 4 + int(n * 2) if (y & 1) == 0 else 5 + int(n * 2)
            elif y < 7:
                # Broken eaves
                v = 5 if (x % 6 < 2) else 6
            elif y < 11:
                # Upper wall, charring
                v = 5 + int(n * 1.5) if (x % 4 >= 2) else 6
            elif y < 23:
                # Mid section with burn hole
                if 6 <= x <= 25 and 13 <= y <= 20:
                    # Burned-out window hole
                    nh = fbm(x * 0.1, y * 0.1, 2, 2.0, 0.5)
                    v = max(0, int(nh * 2))
                elif y == 11 or y == 22:
                    v = 7 if (5 <= x <= 26) else 6  # Frame
                elif x == 5 or x == 26:
                    v = 7  # Side posts
                else:
                    v = 4 + int(n * 2)
            elif y < 28:
                # Lower wall
                if x % 5 == 0:
                    v = 2  # Plank edge
                else:
                    v = 4 + int(n * 2)
            else:
                # Foundation ruins
                v = 6 if y in (28, 30) else 5

            if v < 0: v = 0
            if v > 7: v = 7
            row.append(v)
        rows.append(row)
    return rows

def gen_fire():
    """Burning building texture with layered flames"""
    rows = []
    for y in range(32):
        row = []
        for x in range(32):
            flame_h = 1.0 - y / 32.0  # 1.0 at bottom, 0.0 at top
            fn = fbm(x * 0.25 + y * 0.05, y * 0.3, 3, 1.8, 0.6)

            # Building structure overlay
            struct = 0
            if y < 5 and (y & 1) == 0:    struct = 1  # Roof beams
            elif y == 6:                    struct = 1  # Eave
            elif y >= 10 and y < 22:
                if y == 10 or y == 21:      struct = 1  # Frame
                elif x == 4 or x == 27:     struct = 1  # Posts
                elif x == 15:               struct = 1  # Center pillar
            elif y >= 22 and x % 5 == 0:    struct = 1  # Lower planks

            if y < 6:
                # Smoke/ember top
                v = 3 if fn > 0 else 4
                if struct: v = min(v + 1, 7)
            elif y < 14:
                # Upper flames, structure visible
                n = fn * flame_h * 3
                if struct and n < 1.5:
                    v = 3  # Structure silhouetted
                else:
                    v = int(5 - flame_h * 3 + abs(n) * 2)
            elif y < 22:
                # Mid section burning
                n = fn * flame_h * 4
                if struct and n < 2:
                    v = 2  # Charring structure
                else:
                    v = int(n + 1)
            elif y < 28:
                # Lower intense flames
                n = fn * 3 + flame_h * 3
                v = int(n) + 1
                if struct: v = min(v + 1, 7)
            else:
                # Base: white-hot cores
                n = abs(fn)
                v = int(n * 2)

            if v < 0: v = 0
            if v > 7: v = 7
            row.append(v)
        rows.append(row)
    return rows

def gen_floor_dirt():
    """Dirt/earth floor texture"""
    rows = []
    for y in range(32):
        row = []
        for x in range(32):
            n = fbm(x * 0.25, y * 0.25, 4, 2.0, 0.5)
            v = 2 + int((n + 1.0) * 2.5)
            if v < 0: v = 0
            if v > 7: v = 7
            # Occasional pebble
            h = PERM[(x * 31 + y * 17) & 255]
            if h < 30:
                v = min(v + 2, 7)
            elif h < 35:
                v = max(0, v - 1)  # Dark spot
            row.append(v)
        rows.append(row)
    return rows

def gen_floor_stone():
    """Stone tile floor"""
    rows = []
    # Stone flooring with irregular flagstones
    for y in range(32):
        row = []
        for x in range(32):
            c = cell_noise(x + 100, y + 100, 0.22)
            n = fbm(x * 0.2, y * 0.2, 3, 2.0, 0.5)
            if c < 0.015:
                v = 1  # Mortar line
            else:
                # Flagstone surface
                v = 4 + int((n + 0.8) * 2)
                if v < 3: v = 3
                if v > 7: v = 7
                # Random darker stone
                bx = int(x / 8)
                by = int(y / 8)
                if PERM[((bx + 10) + (by + 10) * 7) & 255] & 7 == 0:
                    v = min(v, 5)
            row.append(v)
        rows.append(row)
    return rows

def gen_floor_wood():
    """Wood plank floor"""
    rows = []
    knots = [(10, 20, 3), (25, 10, 4)]
    for y in range(32):
        row = []
        for x in range(32):
            n = fbm(x * 0.06, y * 1.2, 4, 2.0, 0.5)
            v = 2 + int((n + 1.0) * 2.5)
            if v < 1: v = 1
            if v > 7: v = 7
            # Plank lines
            if y % 8 == 0 or y % 8 == 7:
                v = max(1, v - 2)
            # Knot holes
            for kx, ky, kr in knots:
                d = math.sqrt((x - kx)**2 + (y - ky)**2)
                if d < kr:
                    v = min(v + int((1 - d/kr) * 3), 7)
            row.append(v)
        rows.append(row)
    return rows

def gen_hud_panel():
    """Dark metal plate texture for HUD panel background."""
    rows = []
    for y in range(32):
        row = []
        for x in range(32):
            n = fbm(x * 0.3, y * 0.3, 2, 3.0, 0.4)
            v = 3 + int(n * 1.5)
            if v < 2: v = 2
            if v > 5: v = 5
            h = PERM[(x * 73 + y * 37) & 255]
            if h > 240: v = 6
            elif h > 230: v = 1
            row.append(v)
        rows.append(row)
    return rows

# ============================================================
# PALETTE DATA GENERATION
# ============================================================

def pal_hex(r, g, b):
    """Format RGB as NASM hex dd: 00RRGGBBh"""
    return f"00{r:02X}{g:02X}{b:02X}h"

def gen_wall_palette(dark_rgb, mid_rgb, bright_rgb, dark2_rgb=None):
    """Generate 8-entry gradient for a wall type (X-side)
    Returns list of 8 hex strings (dd format)"""
    entries = []
    dark_r, dark_g, dark_b = dark_rgb
    mid_r, mid_g, mid_b = mid_rgb
    bright_r, bright_g, bright_b = bright_rgb

    if dark2_rgb is None:
        # Linear gradient dark→mid→bright across 8 entries
        for i in range(8):
            t = i / 7.0
            if t < 0.5:
                s = t * 2.0
                r = int(dark_r + (mid_r - dark_r) * s)
                g = int(dark_g + (mid_g - dark_g) * s)
                b = int(dark_b + (mid_b - dark_b) * s)
            else:
                s = (t - 0.5) * 2.0
                r = int(mid_r + (bright_r - mid_r) * s)
                g = int(mid_g + (bright_g - mid_g) * s)
                b = int(mid_b + (bright_b - mid_b) * s)
            entries.append(pal_hex(r, g, b))
    else:
        # Two-phase gradient
        d2r, d2g, d2b = dark2_rgb
        for i in range(8):
            if i < 2:
                t = i / 2.0
                r = int(dark_r + (d2r - dark_r) * t)
                g = int(dark_g + (d2g - dark_g) * t)
                b = int(dark_b + (d2b - dark_b) * t)
            elif i < 5:
                t = (i - 2) / 3.0
                r = int(d2r + (mid_r - d2r) * t)
                g = int(d2g + (mid_g - mid_g) * t)
                b = int(d2b + (mid_b - mid_b) * t)
            else:
                t = (i - 5) / 3.0
                r = int(mid_r + (bright_r - mid_r) * t)
                g = int(mid_g + (bright_g - bright_g) * t)
                b = int(mid_b + (bright_b - bright_b) * t)
            entries.append(pal_hex(r, g, b))
    return entries

def gen_wall_pal_dark(light_entries, factor=0.6):
    """Generate darker Y-side entries from X-side"""
    dark = []
    for ent in light_entries:
        # Parse the hex value (format: 00RRGGBBh)
        val = int(ent.replace('h', ''), 16)
        r = (val >> 16) & 0xFF
        g = (val >> 8) & 0xFF
        b = val & 0xFF
        r = int(r * factor)
        g = int(g * factor)
        b = int(b * factor)
        dark.append(pal_hex(r, g, b))
    return dark

# ============================================================
# PALETTE DEFINITION
# ============================================================
# Wall type gradients (X-side = light, Y-side = dark factor 0.55)
pal_brick_x   = gen_wall_palette((64, 10, 10), (140, 40, 20), (220, 80, 40))
pal_brick_y   = gen_wall_pal_dark(pal_brick_x, 0.55)

pal_stone_x   = gen_wall_palette((40, 40, 40), (100, 100, 100), (180, 180, 180))
pal_stone_y   = gen_wall_pal_dark(pal_stone_x, 0.55)

pal_wood_x    = gen_wall_palette((30, 15, 20), (100, 50, 40), (190, 120, 90))
pal_wood_y    = gen_wall_pal_dark(pal_wood_x, 0.55)

pal_burnt_x   = gen_wall_palette((15, 18, 22), (40, 44, 52), (80, 86, 100))
pal_burnt_y   = gen_wall_pal_dark(pal_burnt_x, 0.55)

pal_fire_x    = gen_wall_palette((140, 20, 0), (220, 120, 0), (255, 230, 60))
pal_fire_y    = gen_wall_pal_dark(pal_fire_x, 0.50)

# Floor palettes
pal_floor_dirt_x = gen_wall_palette((40, 25, 10), (90, 60, 30), (150, 110, 70))
pal_floor_dirt_y = gen_wall_pal_dark(pal_floor_dirt_x, 0.55)

pal_floor_stone_x = gen_wall_palette((50, 45, 40), (100, 95, 90), (160, 155, 150))
pal_floor_stone_y = gen_wall_pal_dark(pal_floor_stone_x, 0.55)

pal_floor_wood_x = gen_wall_palette((40, 20, 10), (120, 65, 35), (210, 140, 90))
pal_floor_wood_y = gen_wall_pal_dark(pal_floor_wood_x, 0.55)

# Weapon/skin palette
pal_weapon = [
    pal_hex(0, 255, 0),       # 0: Green marker
    pal_hex(50, 50, 50),      # 1: Tsuba dark grey
    pal_hex(192, 192, 208),   # 2: Blade silver
    pal_hex(240, 240, 255),   # 3: Blade edge shine
    pal_hex(40, 20, 10),      # 4: Tsuka wrap brown
    pal_hex(220, 180, 160),   # 5: Skin light
    pal_hex(180, 140, 115),   # 6: Skin dark
    pal_hex(0, 0, 0),         # 7: Black
]

# Fire animation palette (4 cycles × 4 entries)
fire_cycle0 = [pal_hex(255, 230, 60), pal_hex(255, 140, 20), pal_hex(220, 40, 10), pal_hex(255, 180, 80)]
fire_cycle1 = [pal_hex(255, 180, 80), pal_hex(255, 230, 60), pal_hex(255, 140, 20), pal_hex(220, 40, 10)]
fire_cycle2 = [pal_hex(220, 40, 10), pal_hex(255, 180, 80), pal_hex(255, 230, 60), pal_hex(255, 140, 20)]
fire_cycle3 = [pal_hex(255, 140, 20), pal_hex(220, 40, 10), pal_hex(255, 180, 80), pal_hex(255, 230, 60)]

# Fog ramp: 32 entries, pure purple fog at increasing intensity
pal_fog = []
for i in range(32):
    t = i / 31.0
    r = int(20 + t * 120)
    b = int(20 + t * 120)
    g = int(t * 30)
    pal_fog.append(pal_hex(r, g, b))

# ============================================================
# DATA TABLES
# ============================================================

def gen_shade_table():
    """64-byte table: perpWallDist → texel dim offset (0-7)"""
    table = []
    for d in range(64):
        # Closer than ~4 units: no shade
        # 4-8: slight shade (0-2)
        # 8-16: medium shade (2-4)
        # 16-32: heavy shade (4-6)
        # 32+: full shade (7)
        dist = d * 0.5  # scale to reasonable wall distances
        if dist < 2.0:
            s = 0
        elif dist < 4.0:
            s = int((dist - 2.0) / 2.0 * 2)
        elif dist < 8.0:
            s = 2 + int((dist - 4.0) / 4.0 * 2)
        elif dist < 16.0:
            s = 4 + int((dist - 8.0) / 8.0 * 2)
        else:
            s = 6 + min(1, int((dist - 16.0) / 16.0))
        if s > 7: s = 7
        table.append(s)
    return table

def gen_floor_gradient():
    """100 bytes: floor brightness per row y=100..199.
    Brighter near horizon (y=100), darker at bottom (y=199).
    Values are row-fill color indices (palette entry)."""
    grad = []
    for y in range(100, 200):
        # Distance factor: 0 at horizon, 1 at bottom
        t = (y - 100) / 100.0
        # Brightness: 1.0 at horizon, fades quickly
        bright = 1.0 - t * t * 0.9  # Quadratic fade
        # Map to floor palette indices (64-95 range, 32 entries)
        idx = 64 + int((1.0 - bright) * 31)
        if idx < 64: idx = 64
        if idx > 95: idx = 95
        grad.append(idx)
    return grad

def gen_sky_gradient():
    """100 bytes: sky color per row y=0..99.
    Darker at top (y=0), brighter at horizon (y=99).
    Values are row-fill color indices. Uses sky palette 0-63."""
    grad = []
    for y in range(0, 100):
        t = 1.0 - y / 100.0  # 1.0 at top, 0.0 at horizon
        bright = t * t  # Quadratic brightening toward horizon
        idx = int(bright * 63)
        if idx < 0: idx = 0
        if idx > 63: idx = 63
        grad.append(idx)
    return grad

def gen_vignette_lut():
    """Generate vignette lookup: for each palette entry, return dimmed version.
    Sky (0-63): shift down 2-3 entries toward darker
    Floor (64-95): shift down toward darker in same range
    Walls (80-159): shift down toward darker in same range
    Everything else: no change
    Returns list of 256 bytes (the dimmed palette index for each source index)."""
    lut = []
    for i in range(256):
        d = i
        if i < 64:
            d = max(0, i - 3)       # Sky: darken by 3 entries
        elif i < 96:
            # Floor: darken within floor range
            base = 64
            offset = max(0, i - base - 3)
            d = max(base, i - 3)
        elif i < 160:
            # Wall palettes (each 16 entries: 8 light + 8 dark)
            # Find which wall type and darken within it
            wall_idx = (i - 80) // 16    # 0=brick, 1=stone, 2=wood, 3=burnt, 4=fire
            wall_base = wall_idx * 16
            wall_off = i - wall_base
            if wall_off < 8:
                d = max(wall_base, i - 2)  # Darken light side
            else:
                d = max(wall_base + 8, i - 1)  # Slightly darken dark side
            if d >= wall_base + 16:
                d = wall_base + 15
        elif i < 176:
            d = i  # Weapon/skin: no vignette
        elif i < 192:
            d = i  # Spare: no vignette
        elif i < 224:
            d = i  # Fog: no vignette
        else:
            d = i  # Reserved: no vignette
        lut.append(d)
    return lut

def gen_vignette_rle():
    """Generate vignette spatial mask as RLE-compressed bytes.
    Values: 0 (no vignette, center) or 1 (apply vignette LUT, edges).
    Only affects outer 5% of screen. Very subtle.
    RLE encoding: count byte, value byte."""
    v = []
    for y in range(200):
        cy = abs(y - 100) / 100.0
        for x in range(320):
            cx = abs(x - 160) / 160.0
            d = math.sqrt(cx * cx + cy * cy)
            if d > 0.95:
                val = 1
            else:
                val = 0
            v.append(val)

    # RLE encode
    rle = []
    i = 0
    while i < len(v):
        cnt = 1
        while i + cnt < len(v) and v[i + cnt] == v[i] and cnt < 255:
            cnt += 1
        rle.append(f"    db {cnt}, {v[i]}")
        i += cnt
    return rle, len(v)

def gen_roof_profile():
    """Generate 32-byte roof height profile for each wallX position.
    Peaked sin-curve with upturned eave curl at edges."""
    profile = []
    max_h = 16  # MAX_ROOF_HEIGHT
    for x in range(32):
        t = x / 31.0  # 0.0 to 1.0
        # Sin curve: peaks at center (x=15.5), zero at edges
        h = math.sin(t * math.pi) * max_h
        # Eave curl: +4 height at extreme edges, fading by t=0.25/0.75
        curl = 0
        if t < 0.25:
            curl = 4 * (1.0 - t / 0.25)
        elif t > 0.75:
            curl = 4 * ((t - 0.75) / 0.25)
        profile.append(int(h + curl))
    return profile

def gen_roof_type_heights():
    """6-byte table: per-wall-type roof height multiplier.
    Index = wall_type - 1: brick, stone, wood, (unused), burnt, fire."""
    return [18, 0, 14, 0, 8, 0]  # tall home, no roof, moderate shop, -, damaged, none


def gen_roof_tile():
    """32x32 Japanese curved roof tile texture. Uses palette 248-253 directly.
    Two horizontal rows of semi-cylindrical tiles with mortar gaps."""
    rows = []
    for y in range(32):
        row = []
        tile_row = y // 16        ; within_tile = y % 16
        for x in range(32):
            wt = y % 16
            if wt <= 1:
                row.append(251)       # shadow under tile edge
            elif wt <= 3:
                row.append(248)       # dark tile body
            elif wt <= 5:
                row.append(253)       # highlight ridge near top
                if x % 6 < 2:
                    row[-1] = 249     # lighter highlight alternating
            elif wt <= 12:
                row.append(249)       # light tile body
                if (x + tile_row * 8) % 13 < 3:
                    row[-1] = 248     # subtle vertical shadow bands
            elif wt <= 14:
                row.append(248)       # dark top of next tile
            else:
                row.append(251)       # deep shadow under next tile
        rows.append(row)
    return rows


def gen_foundation_tile():
    """32x8 stone block foundation texture. Uses palette 248-253.
    Stone blocks with mortar lines and surface texture."""
    h = 8
    rows = []
    for y in range(h):
        row = []
        for x in range(32):
            bx, by = x // 8, y // 4
            # Mortar lines between blocks
            if x % 8 == 0 or y % 4 == 0:
                row.append(251)       # dark mortar
            else:
                n = PERM[(x + y * 31 + bx * 17) & 255] / 255.0
                if n < 0.25:
                    row.append(248)   # dark stone variation
                elif n < 0.6:
                    row.append(252)   # mid stone (foundation color)
                else:
                    row.append(253)   # light stone highlight
        rows.append(row)
    return rows

# ============================================================
# OUTPUT FILES
# ============================================================

def write_tex(f, name, rows):
    f.write(f"; {name}\n")
    f.write(f"tex_{name}:\n")
    for row in rows:
        f.write("    db " + ",".join(str(b) for b in row) + "\n")
    f.write("\n")

def write_pal_list(f, name, entries):
    f.write(f"{name}:\n")
    for i, e in enumerate(entries):
        if i % 4 == 0:
            if i > 0:
                f.write("\n")
            f.write("    dd ")
        else:
            f.write(", ")
        f.write(e)
    f.write("\n\n")

def main():
    # Generate textures
    print("Generating textures...")
    textures = {
        'brick': gen_brick(),
        'stone': gen_stone(),
        'wood_shop': gen_wood_shop(),
        'burnt': gen_burnt(),
        'fire': gen_fire(),
        'floor_dirt': gen_floor_dirt(),
        'floor_stone': gen_floor_stone(),
        'floor_wood': gen_floor_wood(),
        'hud_panel': gen_hud_panel(),
        'roof': gen_roof_tile(),
        'foundation': gen_foundation_tile(),
    }

    with open("src/tex_gen.inc", "w") as f:
        f.write("; Auto-generated wall, floor, roof, and foundation textures\n")
        f.write("; Wall/floor textures: 32x32, 4-bit texels 0-7\n")
        f.write("; Roof/foundation textures: direct palette indices (8-bit)\n\n")
        for name, rows in textures.items():
            write_tex(f, name, rows)

    # Write palette data
    print("Generating palettes...")
    with open("src/palette_data.inc", "w") as f:
        f.write("; Auto-generated palette data\n\n")

        f.write("; Wall type gradients (X-side = light)\n")
        write_pal_list(f, "pal_brick_x", pal_brick_x)
        write_pal_list(f, "pal_stone_x", pal_stone_x)
        write_pal_list(f, "pal_wood_x", pal_wood_x)
        write_pal_list(f, "pal_burnt_x", pal_burnt_x)
        write_pal_list(f, "pal_fire_x", pal_fire_x)

        f.write("; Wall type gradients (Y-side = dark)\n")
        write_pal_list(f, "pal_brick_y", pal_brick_y)
        write_pal_list(f, "pal_stone_y", pal_stone_y)
        write_pal_list(f, "pal_wood_y", pal_wood_y)
        write_pal_list(f, "pal_burnt_y", pal_burnt_y)
        write_pal_list(f, "pal_fire_y", pal_fire_y)

        f.write("; Floor palettes\n")
        write_pal_list(f, "pal_floor_dirt_x", pal_floor_dirt_x)
        write_pal_list(f, "pal_floor_dirt_y", pal_floor_dirt_y)
        write_pal_list(f, "pal_floor_stone_x", pal_floor_stone_x)
        write_pal_list(f, "pal_floor_stone_y", pal_floor_stone_y)
        write_pal_list(f, "pal_floor_wood_x", pal_floor_wood_x)
        write_pal_list(f, "pal_floor_wood_y", pal_floor_wood_y)

        f.write("; Weapon / skin / debug palette\n")
        write_pal_list(f, "pal_weapon", pal_weapon)

        f.write("; Fire animation cycles (4 frames, 4 entries each)\n")
        write_pal_list(f, "fire_cycle0", fire_cycle0)
        write_pal_list(f, "fire_cycle1", fire_cycle1)
        write_pal_list(f, "fire_cycle2", fire_cycle2)
        write_pal_list(f, "fire_cycle3", fire_cycle3)

        f.write("; Fog ramp (32 entries)\n")
        write_pal_list(f, "pal_fog", pal_fog)

    # Write shade/gradient/vignette data
    print("Generating data tables...")
    shade = gen_shade_table()
    floor_grad = gen_floor_gradient()
    sky_grad = gen_sky_gradient()
    vignette_lut = gen_vignette_lut()
    vignette_rle, vignette_len = gen_vignette_rle()
    roof_profile = gen_roof_profile()
    roof_type_heights = gen_roof_type_heights()

    with open("src/shade_data.inc", "w") as f:
        f.write("; Auto-generated shade/gradient/vignette/roof tables\n\n")

        f.write("; shade_table: perpWallDist bucket (0-63) -> texel shade offset (0-7)\n")
        f.write("shade_table:\n")
        f.write("    db " + ",".join(str(s) for s in shade) + "\n\n")

        f.write("; floor_gradient: floor row fill color for y=100..199\n")
        f.write("floor_gradient:\n")
        f.write("    db " + ",".join(str(s) for s in floor_grad) + "\n\n")

        f.write("; sky_gradient: sky row fill color for y=0..99\n")
        f.write("sky_gradient:\n")
        f.write("    db " + ",".join(str(s) for s in sky_grad) + "\n\n")

        f.write("; roof_profile: 32-byte roof height profile (sin curve + eave curl)\n")
        f.write("roof_profile:\n")
        f.write("    db " + ",".join(str(h) for h in roof_profile) + "\n\n")

        f.write("; roof_type_height: 6-byte per-wall-type roof height multiplier\n")
        f.write("roof_type_height:\n")
        f.write("    db " + ",".join(str(h) for h in roof_type_heights) + "\n\n")

        f.write("; vignette_lut: per-palette-index dimmed version (256 bytes)\n")
        f.write("vignette_lut:\n")
        f.write("    db " + ",".join(str(v) for v in vignette_lut) + "\n\n")

        f.write(f"; vignette_rle: RLE-compressed spatial mask (uncompressed: {vignette_len} bytes)\n")
        f.write("vignette_rle:\n")
        for line in vignette_rle:
            f.write(line + "\n")
        f.write(f"vignette_rle_len: dd {len(vignette_rle) * 2}\n")
        f.write(f"vignette_full_len: dd {vignette_len}\n")

    print("Done! Generated tex_gen.inc, palette_data.inc, shade_data.inc")

if __name__ == '__main__':
    main()
