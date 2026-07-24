"""Generate katana weapon and arm sprites for the weapon overlay system.

Palette: 0=transparent, 177=tsuba, 178=blade, 179=shine, 180=wrap,
         181=skin_l, 182=skin_d, 183=black
"""

import math, os

T     = 0
TSUBA = 177
BLADE = 178
SHINE = 179
WRAP  = 180
SKIN_L = 181
SKIN_D = 182
BLACK = 183

SPRITE_DIR = os.path.join(os.path.dirname(__file__), "sprites")


def make_grid(w, h):
    return [[T] * w for _ in range(h)]

def pset(g, x, y, c):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < len(g[0]) and 0 <= y < len(g):
        g[y][x] = c

def draw_line(g, x1, y1, x2, y2, c):
    x1, y1 = int(round(x1)), int(round(y1))
    x2, y2 = int(round(x2)), int(round(y2))
    dx = abs(x2 - x1); sx = 1 if x1 < x2 else -1
    dy = -abs(y2 - y1); sy = 1 if y1 < y2 else -1
    err = dx + dy
    while True:
        pset(g, x1, y1, c)
        if x1 == x2 and y1 == y2: break
        e2 = 2 * err
        if e2 >= dy: err += dy; x1 += sx
        if e2 <= dx: err += dx; y1 += sy

def rot(x, y, a):
    c, s = math.cos(a), math.sin(a)
    return x*c - y*s, x*s + y*c


# ---- Blade geometry (local: tsuba at origin, blade up/-Y) ----

SPINE_BASE  = ( 0,  5)     # spine at tsuba
SPINE_MID   = ( 1, -65)     # spine before kissaki
TIP         = ( 3, -93)     # tip point
EDGE_MID    = (-9, -65)     # edge before kissaki
EDGE_BASE   = (-10,  5)     # edge at tsuba

HANDLE_TOP_Y     = 5
HANDLE_LENGTH    = 52
HANDLE_W_TOP     = 7
HANDLE_W_BOT     = 6
TSUBA_RX, TSUBA_RY = 12, 4
POMMEL_LEN, POMMEL_W = 5, 9


def fill_scanlines(g, left_pts, right_pts, c):
    """Fill between two poly-lines using scanlines."""
    if len(left_pts) < 2 or len(right_pts) < 2:
        return
    min_y = int(math.floor(min(p[1] for p in left_pts + right_pts)))
    max_y = int(math.ceil(max(p[1] for p in left_pts + right_pts)))
    for y in range(min_y, max_y + 1):
        lx = _lerp_segments(left_pts, y)
        if lx is None: continue
        rx = _lerp_segments(right_pts, y)
        if rx is None: continue
        if lx > rx: lx, rx = rx, lx
        for x in range(int(math.floor(lx)), int(math.ceil(rx)) + 1):
            pset(g, x, y, c)

def _lerp_segments(pts, y):
    """Find X coordinate on a poly-line at given Y. Returns None if Y is out of range."""
    for i in range(len(pts) - 1):
        y1, y2 = pts[i][1], pts[i+1][1]
        if min(y1, y2) <= y <= max(y1, y2):
            if abs(y2 - y1) < 0.0001:
                return pts[i][0]
            t = (y - y1) / (y2 - y1)
            return pts[i][0] + t * (pts[i+1][0] - pts[i][0])
    return None


def draw_oval(g, cx, cy, rx, ry, angle, c, fill=True):
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    min_x = int(cx - rx - 3); max_x = int(cx + rx + 3)
    min_y = int(cy - ry - 3); max_y = int(cy + ry + 3)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            dx, dy = x - cx, y - cy
            lx = dx*cos_a + dy*sin_a
            ly = -dx*sin_a + dy*cos_a
            if fill:
                if (lx/rx)**2 + (ly/ry)**2 <= 1.0:
                    pset(g, x, y, c)
            else:
                d = (lx/rx)**2 + (ly/ry)**2
                if 0.75 <= d <= 1.35:
                    pset(g, x, y, c)


def draw_katana(g, rot_angle=0.0, cx=75, cy=100):
    def rtp(x, y):
        rx, ry = rot(x, y, rot_angle)
        return (rx + cx, ry + cy)

    # Blade polygon vertices (spine → tip → edge)
    spine_base = rtp(*SPINE_BASE)
    spine_mid  = rtp(*SPINE_MID)
    tip        = rtp(*TIP)
    edge_mid   = rtp(*EDGE_MID)
    edge_base  = rtp(*EDGE_BASE)

    # ---- Fill blade body ----
    # Spine edge: base → mid → tip
    # Edge edge:  base → mid → tip
    spine_edge = [spine_base, spine_mid, tip]
    edge_edge  = [edge_base, edge_mid, tip]
    fill_scanlines(g, edge_edge, spine_edge, BLADE)

    # ---- Blade outlines ----
    draw_line(g, *spine_base, *spine_mid, BLACK)
    draw_line(g, *spine_mid, *tip, BLACK)
    draw_line(g, *edge_base, *edge_mid, BLACK)
    draw_line(g, *edge_mid, *tip, BLACK)

    # ---- Shinogi (ridge line, 1/3 from spine) ----
    sb = (spine_base[0] + (edge_base[0]-spine_base[0])*0.30,
          spine_base[1] + (edge_base[1]-spine_base[1])*0.30)
    sm = (spine_mid[0] + (edge_mid[0]-spine_mid[0])*0.30,
          spine_mid[1] + (edge_mid[1]-spine_mid[1])*0.30)
    draw_line(g, *sb, *sm, BLACK)

    # ---- Edge shine (2px inside cutting edge) ----
    steps = 60
    for i in range(steps + 1):
        t = i / steps
        if t < 0.5:
            s = t * 2
            ex = edge_base[0] + (edge_mid[0] - edge_base[0]) * s
            ey = edge_base[1] + (edge_mid[1] - edge_base[1]) * s
            sx = spine_base[0] + (spine_mid[0] - spine_base[0]) * s
            sy = spine_base[1] + (spine_mid[1] - spine_base[1]) * s
        else:
            s = (t - 0.5) * 2
            ex = edge_mid[0] + (tip[0] - edge_mid[0]) * s
            ey = edge_mid[1] + (tip[1] - edge_mid[1]) * s
            sx = spine_mid[0] + (tip[0] - spine_mid[0]) * s
            sy = spine_mid[1] + (tip[1] - spine_mid[1]) * s
        dx, dy = sx - ex, sy - ey
        length = math.sqrt(dx*dx + dy*dy)
        if length > 0:
            nx, ny = dx/length, dy/length
            for off in (1, 2):
                pset(g, ex + nx*off, ey + ny*off, SHINE)

    # ---- Kissaki tip highlight ----
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if dx*dx + dy*dy <= 3:
                pset(g, tip[0] + dx, tip[1] + dy, SHINE)

    # ---- Handle endpoints ----
    htop = rtp(0, HANDLE_TOP_Y)
    hbot = rtp(0, HANDLE_TOP_Y + HANDLE_LENGTH)

    # Handle direction and perpendicular
    hdx = hbot[0] - htop[0]
    hdy = hbot[1] - htop[1]
    hlen = math.sqrt(hdx**2 + hdy**2)
    hnx, hny = -hdy, hdx
    if hlen > 0:
        hnx = -hdy / hlen
        hny = hdx / hlen

    # ---- Fill handle body as a polygon (under-layer: BLACK) ----
    hw_top = HANDLE_W_TOP
    hw_bot = HANDLE_W_BOT
    tl = (htop[0] + hnx * hw_top, htop[1] + hny * hw_top)
    tr = (htop[0] - hnx * hw_top, htop[1] - hny * hw_top)
    bl = (hbot[0] + hnx * hw_bot, hbot[1] + hny * hw_bot)
    br = (hbot[0] - hnx * hw_bot, hbot[1] - hny * hw_bot)

    # Draw handle as filled polygon
    handle_left  = [tl, bl]
    handle_right = [tr, br]
    fill_scanlines(g, handle_left, handle_right, BLACK)

    # ---- Ito wrap overlay (diamond pattern) ----
    for i in range(int(hlen)):
        t = i / max(hlen, 1)
        hx = htop[0] + hdx * t
        hy = htop[1] + hdy * t
        hw = HANDLE_W_TOP * (1 - t) + HANDLE_W_BOT * t
        phase = i % 5
        if phase < 2:
            start, end = -int(hw) + 1, int(hw)
        elif phase == 2:
            start, end = -int(hw) + 2, int(hw) - 1
        else:
            start, end = 0, -1  # skip (no wrap on these rows)
        for j in range(start, end):
            pset(g, hx + hnx*j, hy + hny*j, WRAP)

    # ---- Fuchi (metal collar above tsuba) ----
    fy1, fy2 = 1, 4
    for fy in (fy1, fy2):
        fx, fy_rot = rtp(0, fy)
        fy_rot_int = int(round(fy_rot))
        for j in range(-HANDLE_W_TOP, HANDLE_W_TOP + 1):
            px = int(round(fx + hnx * j))
            py = int(round(fy_rot + hny * j))
            pset(g, px, py, BLACK)
        for j in range(-HANDLE_W_TOP + 1, HANDLE_W_TOP):
            px = int(round(fx + hnx * j))
            py = int(round(fy_rot + hny * j))
            pset(g, px, py, TSUBA)

    # ---- Pommel (kashira) ----
    for i in range(POMMEL_LEN + 1):
        t = i / max(POMMEL_LEN, 1)
        hx = hbot[0] + hdx / max(HANDLE_LENGTH, 1) * i
        hy = hbot[1] + hdy / max(HANDLE_LENGTH, 1) * i
        pw = POMMEL_W * (1 - t) + HANDLE_W_BOT * t
        for j in range(-int(pw), int(pw) + 1):
            pset(g, hx + hnx*j, hy + hny*j, BLACK)
        if i < 3:
            for j in range(-int(pw) + 1, int(pw)):
                pset(g, hx + hnx*j, hy + hny*j, WRAP)

    # ---- Tsuba (guard) ----
    draw_oval(g, cx, cy, TSUBA_RX, TSUBA_RY, rot_angle, TSUBA)
    draw_oval(g, cx, cy, TSUBA_RX + 1, TSUBA_RY + 1, rot_angle, BLACK, fill=False)
    draw_oval(g, cx, cy, TSUBA_RX * 0.45, TSUBA_RY + 1.5, rot_angle, BLACK, fill=False)
    draw_oval(g, cx, cy, 3, 1.5, rot_angle, BLACK)


# ---- Arms ----

def fill_spine_strip(g, edge1, edge2, c):
    """Fill between two poly-lines."""
    min_y = int(math.floor(min(p[1] for p in edge1 + edge2)))
    max_y = int(math.ceil(max(p[1] for p in edge1 + edge2)))
    for y in range(min_y, max_y + 1):
        x1 = _lerp_segments(edge1, y)
        x2 = _lerp_segments(edge2, y)
        if x1 is not None and x2 is not None:
            if x1 > x2: x1, x2 = x2, x1
            for x in range(int(math.floor(x1)), int(math.ceil(x2)) + 1):
                pset(g, x, y, c)


def draw_arms(g, rot_angle=0.0, cx=65, cy=40):
    w, h = len(g[0]), len(g)

    def rtp(x, y):
        rx, ry = rot(x, y, rot_angle)
        return (rx + cx, ry + cy)

    grip = rtp(0, HANDLE_TOP_Y + HANDLE_LENGTH * 0.35)

    # Forearm edge points (two edges per arm forming a tapered strip)
    # Right arm
    r_bot1 = rtp(45, HANDLE_LENGTH + 15)
    r_bot2 = rtp(20, HANDLE_LENGTH + 15)
    r_top1 = (grip[0] + 8, grip[1] - 4)
    r_top2 = (grip[0] - 2, grip[1] + 4)

    # Left arm
    l_bot1 = rtp(-20, HANDLE_LENGTH + 25)
    l_bot2 = rtp(-45, HANDLE_LENGTH + 25)
    l_top1 = (grip[0] - 6, grip[1] - 2)
    l_top2 = (grip[0] - 14, grip[1] + 6)

    # Right arm fill (light skin)
    fill_spine_strip(g, [r_bot1, r_top1], [r_bot2, r_top2], SKIN_L)
    # Right arm outline
    draw_line(g, *r_bot1, *r_top1, SKIN_D)
    draw_line(g, *r_bot2, *r_top2, SKIN_D)

    # Left arm fill
    fill_spine_strip(g, [l_bot1, l_top1], [l_bot2, l_top2], SKIN_L)
    draw_line(g, *l_bot1, *l_top1, SKIN_D)
    draw_line(g, *l_bot2, *l_top2, SKIN_D)

    # Sleeve edges
    draw_line(g, r_bot1[0]-8, r_bot1[1], r_bot2[0]+8, r_bot2[1], BLACK)
    draw_line(g, l_bot2[0]-8, l_bot2[1], l_bot1[0]+8, l_bot1[1], BLACK)

    # Hand direction perpendicular
    c, s = math.cos(rot_angle), math.sin(rot_angle)
    hnx = s; hny = -c

    # Right hand blocks
    for i in range(-5, 7):
        for j in range(-3, 5):
            px = grip[0] + int(hnx*i + s*3)
            py = grip[1] + int(hny*i + j)
            if abs(i) <= 3 and abs(j) <= 1:
                continue
            pset(g, px, py, SKIN_D)

    # Left hand blocks
    for i in range(-4, 5):
        for j in range(-2, 3):
            px = grip[0] + int(hnx*i - s*6)
            py = grip[1] + int(hny*i + 5 + j)
            pset(g, px, py, SKIN_D)

    # Finger gaps
    for k in range(4):
        fi = -2 + k
        fx = grip[0] + int(hnx*fi + s*4)
        fy = grip[1] + int(hny*fi) + 1
        pset(g, fx, fy, BLACK)
        pset(g, fx + 1, fy - 1, BLACK)


# ================================================================
# POSE DEFINITIONS
# ================================================================

WEP_W, WEP_H = 150, 190
ARM_W, ARM_H = 130, 85
WEP_CX, WEP_CY = 75, 100
ARM_CX, ARM_CY = 65, 40

WEP_POSES = {
    "katana_idle":       (-0.30,),
    "katana_windup_1":   (-0.08,),
    "katana_windup_2":   ( 0.10,),
    "katana_swing_1":    ( 0.45,),
    "katana_swing_2":    ( 0.80,),
    "katana_swing_3":    ( 1.05,),
    "katana_block":      (-0.85,),
}

ARM_POSES = {
    "arms_idle":         (-0.30,),
    "arms_attack_1":     ( 0.10,),
    "arms_attack_2":     ( 0.45,),
    "arms_attack_3":     ( 0.80,),
    "arms_block":        (-0.85,),
}


# ================================================================
# OUTPUT
# ================================================================

def grid_to_asm(g, label):
    lines = [f"; {label}", f"spr_{label}:",
             f"    dw  {len(g[0])}    ; width",
             f"    dw  {len(g)}     ; height"]
    for row in g:
        lines.append("    db  " + ",".join(str(c) for c in row))
    return "\n".join(lines) + "\n"


def main():
    os.makedirs(SPRITE_DIR, exist_ok=True)

    for name, (angle,) in WEP_POSES.items():
        g = make_grid(WEP_W, WEP_H)
        draw_katana(g, rot_angle=angle, cx=WEP_CX, cy=WEP_CY)
        with open(os.path.join(SPRITE_DIR, f"{name}.inc"), "w") as f:
            f.write(f"; Katana: {name}\n")
            f.write(f"; Palette: 0=transparent, 177=tsuba, 178=blade, 179=shine, 180=wrap, 183=black\n")
            f.write(grid_to_asm(g, name))
        print(f"  {name}.inc ({WEP_W}x{WEP_H})")

    for name, (angle,) in ARM_POSES.items():
        g = make_grid(ARM_W, ARM_H)
        draw_arms(g, rot_angle=angle, cx=ARM_CX, cy=ARM_CY)
        with open(os.path.join(SPRITE_DIR, f"{name}.inc"), "w") as f:
            f.write(f"; Arms: {name}\n")
            f.write(f"; Palette: 0=transparent, 181=skin_l, 182=skin_d, 183=black\n")
            f.write(grid_to_asm(g, name))
        print(f"  {name}.inc ({ARM_W}x{ARM_H})")

    weapon_order = [
        "spr_katana_idle", "spr_katana_windup_1", "spr_katana_windup_2",
        "spr_katana_swing_1", "spr_katana_swing_2", "spr_katana_swing_3",
        "spr_katana_block",
    ]
    arm_order = [
        "spr_arms_idle", "spr_arms_attack_1", "spr_arms_attack_2",
        "spr_arms_attack_2", "spr_arms_attack_3", "spr_arms_attack_3",
        "spr_arms_block",
    ]

    with open(os.path.join(SPRITE_DIR, "_sprite_table.inc"), "w") as f:
        f.write("; Sprite lookup tables\n\nweapon_sprites:\n")
        for label in weapon_order:
            f.write(f"    dq  {label}\n")
        f.write("\narm_sprites:\n")
        for label in arm_order:
            f.write(f"    dq  {label}\n")
        f.write(f"\nWEAPON_SPRITE_COUNT equ {len(weapon_order)}\n")

    print("\n  Generated _sprite_table.inc")
    print("Done.")

if __name__ == "__main__":
    main()
