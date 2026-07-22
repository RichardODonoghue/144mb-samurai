"""Generate 24x20 samurai face sprites for the HUD.
Outputs src/face_data.inc with 5 damage states."""

# Palette indices
BG  = 254  # transparent/panel bg
SK  = 181  # skin light
SD  = 182  # skin dark
BL  = 183  # black (hair, eyes, mouth, headband, collar)
RD  = 190  # blood red
BR  = 250  # bruise purple

T = BG     # shorthand for transparent

def face_grid():
    """Create a 24x20 grid filled with transparent/background."""
    return [[T]*24 for _ in range(20)]

def draw_rect(g, x, y, w, h, c):
    for dy in range(h):
        for dx in range(w):
            if 0 <= x+dx < 24 and 0 <= y+dy < 20:
                g[y+dy][x+dx] = c

def draw_line_h(g, x, y, w, c):
    draw_rect(g, x, y, w, 1, c)

def draw_line_v(g, x, y, h, c):
    draw_rect(g, x, y, 1, h, c)

def draw_pixel(g, x, y, c):
    if 0 <= x < 24 and 0 <= y < 20:
        g[y][x] = c

def draw_eye(g, lx, rx, y_center, pupil_side='center'):
    """Draw almond-shaped eyes. lx=left eye center X, rx=right eye X."""
    for eye_x in (lx, rx):
        # Eye top: 2px wide
        draw_pixel(g, eye_x-1, y_center, BL)
        draw_pixel(g, eye_x, y_center, BL)
        # Eye body: 4px wide with white + pupil
        draw_pixel(g, eye_x-2, y_center+1, BL)
        draw_pixel(g, eye_x-1, y_center+1, SK)
        draw_pixel(g, eye_x, y_center+1, SK)
        draw_pixel(g, eye_x+1, y_center+1, BL)
        # Eye bottom: 2px wide
        draw_pixel(g, eye_x-1, y_center+2, BL)
        draw_pixel(g, eye_x, y_center+2, BL)
        
        # Pupil position based on damage state
        if pupil_side == 'center':
            px, py = eye_x, y_center+1
        elif pupil_side == 'left':
            px, py = eye_x-1, y_center+1
        else:
            px, py = eye_x, y_center+1
        draw_pixel(g, px, py, BL)

def draw_eyebrow(g, lx, rx, y, angled=False):
    """Draw eyebrows. If angled, outer edge is lower (angry/pained)."""
    # Left eyebrow
    if angled:
        draw_pixel(g, lx-2, y+1, BL)
        draw_pixel(g, lx-1, y, BL)
        draw_pixel(g, lx, y, BL)
        draw_pixel(g, lx+1, y, BL)
    else:
        draw_pixel(g, lx-2, y, BL)
        draw_pixel(g, lx-1, y, BL)
        draw_pixel(g, lx, y, BL)
        draw_pixel(g, lx+1, y, BL)
    # Right eyebrow
    if angled:
        draw_pixel(g, rx-1, y, BL)
        draw_pixel(g, rx, y, BL)
        draw_pixel(g, rx+1, y, BL)
        draw_pixel(g, rx+2, y+1, BL)
    else:
        draw_pixel(g, rx-1, y, BL)
        draw_pixel(g, rx, y, BL)
        draw_pixel(g, rx+1, y, BL)
        draw_pixel(g, rx+2, y, BL)

def gen_healthy():
    g = face_grid()
    
    # Hair: chonmage topknot, rows 0-4
    draw_rect(g, 5, 0, 14, 1, BL)
    draw_rect(g, 4, 1, 16, 1, BL)
    draw_rect(g, 3, 2, 18, 1, BL)
    draw_rect(g, 3, 3, 18, 1, BL)
    draw_rect(g, 4, 4, 16, 1, BL)
    
    # Headband (hachimaki): rows 5-6
    draw_rect(g, 3, 5, 18, 2, BL)
    
    # Forehead: rows 7-8
    draw_rect(g, 4, 7, 16, 2, SK)
    
    # Eyebrows: row 9
    draw_eyebrow(g, 8, 15, 9)
    
    # Eyes: rows 10-12 (3 rows)
    # Row 10: upper eyelid line
    draw_pixel(g, 7, 10, SD); draw_pixel(g, 8, 10, BL); draw_pixel(g, 9, 10, BL); draw_pixel(g, 10, 10, SD)
    draw_pixel(g, 13, 10, SD); draw_pixel(g, 14, 10, BL); draw_pixel(g, 15, 10, BL); draw_pixel(g, 16, 10, SD)
    
    # Row 11: eye body - white sclera + dark pupil
    # Left eye (cols 7-10): SD | BL(pupil) | SK(white) | SD
    draw_pixel(g, 7, 11, SD); draw_pixel(g, 8, 11, BL); draw_pixel(g, 9, 11, SK); draw_pixel(g, 10, 11, SD)
    # Right eye (cols 13-16): SD | SK(white) | BL(pupil) | SD
    draw_pixel(g, 13, 11, SD); draw_pixel(g, 14, 11, SK); draw_pixel(g, 15, 11, BL); draw_pixel(g, 16, 11, SD)
    
    # Row 12: lower eyelid
    draw_pixel(g, 7, 12, SD); draw_pixel(g, 8, 12, BL); draw_pixel(g, 9, 12, BL); draw_pixel(g, 10, 12, SD)
    draw_pixel(g, 13, 12, SD); draw_pixel(g, 14, 12, BL); draw_pixel(g, 15, 12, BL); draw_pixel(g, 16, 12, SD)
    
    # Nose bridge: row 13
    draw_pixel(g, 9, 13, SD); draw_pixel(g, 10, 13, SD); draw_pixel(g, 11, 13, SD); draw_pixel(g, 12, 13, SD); draw_pixel(g, 13, 13, SD); draw_pixel(g, 14, 13, SD)
    
    # Nose bottom / nostrils: row 14
    draw_pixel(g, 9, 14, SD); draw_pixel(g, 10, 14, SD); draw_pixel(g, 11, 14, SD); draw_pixel(g, 12, 14, BL); draw_pixel(g, 13, 14, SD); draw_pixel(g, 14, 14, SD)
    
    # Philtrum: row 15
    draw_pixel(g, 11, 15, SD); draw_pixel(g, 12, 15, SD)
    
    # Mouth: thin line, row 16
    draw_pixel(g, 9, 16, BL); draw_pixel(g, 10, 16, BL); draw_pixel(g, 11, 16, BL); draw_pixel(g, 12, 16, BL); draw_pixel(g, 13, 16, BL); draw_pixel(g, 14, 16, BL)
    
    # Lower lip shadow: row 17
    draw_pixel(g, 10, 17, SD); draw_pixel(g, 11, 17, SD); draw_pixel(g, 12, 17, SD); draw_pixel(g, 13, 17, SD)
    
    # Jaw shadow: row 18
    draw_rect(g, 5, 18, 14, 1, SD)
    
    # Collar: row 19
    draw_rect(g, 4, 19, 16, 1, BL)
    
    # Fill remaining face with skin
    for y in range(7, 19):
        for x in range(24):
            if g[y][x] == T:
                # Any unfilled pixel in face region gets skin color
                if 3 <= x <= 20:
                    g[y][x] = SK
    
    # Re-apply face outline at edges
    for y in range(7, 18):
        if g[y][4] == SK: g[y][4] = SD
        if g[y][19] == SK: g[y][19] = SD
    
    return g

def gen_hurt1():
    """Minor damage: cut on right cheek."""
    g = gen_healthy()
    # Blood cut on right cheek
    draw_pixel(g, 17, 14, RD); draw_pixel(g, 18, 15, RD); draw_pixel(g, 18, 16, RD)
    # Slight grimace: mouth slightly wider
    draw_pixel(g, 8, 16, BL); draw_pixel(g, 15, 16, BL)
    # Left eyebrow slightly angled
    draw_pixel(g, 7, 9, BL); draw_pixel(g, 10, 9, T)
    return g

def gen_hurt2():
    """Injured: multiple cuts, bruise on left cheek, blood trickle."""
    g = gen_healthy()
    # Bruise on left cheek
    draw_rect(g, 5, 13, 3, 4, BR)
    draw_rect(g, 4, 14, 2, 2, BR)
    # Blood trickle from right brow
    draw_pixel(g, 16, 10, RD); draw_pixel(g, 17, 11, RD); draw_pixel(g, 17, 12, RD); draw_pixel(g, 18, 13, RD)
    # Cuts on cheeks
    draw_pixel(g, 17, 14, RD); draw_pixel(g, 18, 15, RD)
    draw_pixel(g, 6, 12, RD); draw_pixel(g, 5, 13, RD)
    # Grimace: wider mouth with teeth showing (gap in middle)
    draw_pixel(g, 8, 16, BL); draw_pixel(g, 15, 16, BL)
    draw_pixel(g, 11, 16, SK); draw_pixel(g, 12, 16, SK)  # teeth gap
    # Angled eyebrows
    draw_pixel(g, 7, 9, BL); draw_pixel(g, 16, 9, BL)
    draw_pixel(g, 10, 9, T); draw_pixel(g, 13, 9, T)
    return g

def gen_hurt3():
    """Heavy damage: swollen left eye, heavy bruising, blood from nose."""
    g = gen_healthy()
    # Swollen left eye: bruise covers eye area
    draw_rect(g, 5, 10, 5, 3, BR)
    draw_pixel(g, 8, 11, RD)  # blood in eye
    # Bruise spread
    draw_rect(g, 4, 9, 3, 2, BR)
    draw_rect(g, 4, 13, 4, 3, BR)
    # Blood from nose
    draw_pixel(g, 11, 13, RD); draw_pixel(g, 12, 13, RD)
    draw_pixel(g, 11, 14, RD); draw_pixel(g, 12, 14, RD)
    draw_pixel(g, 11, 15, RD); draw_pixel(g, 12, 15, RD)
    # Right cheek blood
    draw_pixel(g, 17, 14, RD); draw_pixel(g, 18, 15, RD); draw_pixel(g, 19, 16, RD)
    # Cuts
    draw_pixel(g, 7, 14, RD); draw_pixel(g, 15, 13, RD); draw_pixel(g, 16, 14, RD)
    # Pained mouth: open wider, blood
    draw_pixel(g, 7, 16, BL); draw_pixel(g, 16, 16, BL)
    draw_pixel(g, 10, 17, RD); draw_pixel(g, 11, 17, RD); draw_pixel(g, 12, 17, RD); draw_pixel(g, 13, 17, RD)
    draw_pixel(g, 11, 16, RD); draw_pixel(g, 12, 16, RD)  # blood in mouth
    # Angry eyebrows
    draw_pixel(g, 7, 9, BL); draw_pixel(g, 16, 9, BL)
    return g

def gen_hurt4():
    """Near-death: right eye swollen, face covered in blood, gasping."""
    g = gen_healthy()
    # Both eyes damaged
    draw_rect(g, 5, 10, 5, 3, BR)   # left eye bruised
    draw_rect(g, 13, 10, 5, 3, BR)  # right eye bruised
    draw_pixel(g, 8, 11, RD); draw_pixel(g, 15, 11, RD)  # blood in eyes
    # Heavy bruising everywhere
    draw_rect(g, 4, 8, 16, 2, BR)
    draw_rect(g, 3, 13, 18, 4, BR)
    # Blood everywhere  
    for x, y in [(5,11),(6,12),(7,14),(8,15),(9,16),(10,17),
                 (14,13),(15,14),(16,15),(17,14),(18,12),
                 (11,13),(12,13),(13,14),(11,16),(12,16)]:
        draw_pixel(g, x, y, RD)
    # Blood from nose
    for x in (11,12):
        for y in (13,14,15,16):
            draw_pixel(g, x, y, RD)
    # Gaping mouth
    draw_pixel(g, 8, 16, BL); draw_pixel(g, 9, 16, BL); draw_pixel(g, 14, 16, BL); draw_pixel(g, 15, 16, BL)
    draw_pixel(g, 10, 17, BL); draw_pixel(g, 11, 17, BL); draw_pixel(g, 12, 17, BL); draw_pixel(g, 13, 17, BL)
    draw_pixel(g, 11, 16, RD); draw_pixel(g, 12, 16, RD)
    # Blood on chin
    draw_pixel(g, 10, 18, RD); draw_pixel(g, 11, 18, RD); draw_pixel(g, 12, 18, RD); draw_pixel(g, 13, 18, RD)
    # Hair disheveled (some skin showing through)
    draw_pixel(g, 6, 1, T); draw_pixel(g, 7, 2, T); draw_pixel(g, 18, 3, T)
    return g

def grid_to_nasm(g, name):
    lines = [f"; {name}"]
    lines.append(f"face_{name}:")
    for row in g:
        lines.append(" db " + ",".join(str(c) for c in row))
    return "\n".join(lines) + "\n"

def main():
    faces = [
        ("healthy", gen_healthy()),
        ("hurt1", gen_hurt1()),
        ("hurt2", gen_hurt2()),
        ("hurt3", gen_hurt3()),
        ("hurt4", gen_hurt4()),
    ]
    
    with open("src/face_data.inc", "w") as f:
        f.write("; ------------------------------------------------------------------\n")
        f.write(";  SAMURAI FACE SPRITES - 24x20 pixels x 5 damage states (auto-generated)\n")
        f.write(";  Palette: 181=skin light, 182=skin dark, 183=black, 190=blood, 250=bruise, 254=bg\n")
        f.write("; ------------------------------------------------------------------\n\n")
        
        for name, grid in faces:
            f.write(grid_to_nasm(grid, name))
            f.write("\n")
        
        f.write("; Face selector LUT: health% -> face index\n")
        f.write("face_table: dq face_healthy, face_hurt1, face_hurt2, face_hurt3, face_hurt4\n")
    
    # Also print a visual preview of the healthy face
    print("Healthy face preview:")
    g = faces[0][1]
    chars = {T:'.', SK:'@', SD:'#', BL:'X', RD:'R', BR:'B'}
    for row in g:
        print(''.join(chars.get(c,'?') for c in row))

    # --- Heart sprites ---
    print("\nGenerating hearts...")
    gen_heart_sprites()

def gen_heart_sprites():
    """Generate 20x18 heart sprites at 5 fill levels."""
    HW, HH = 20, 18
    
    # Heart outline mask (1=outline, 0=not) - proper heart shape with two lobes
    mask = [
        [0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0],
        [0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0],
        [0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0],
        [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0],
        [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0],
        [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0],
        [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0],
        [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0],
        [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0],
        [0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0],
        [0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0],
        [0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0],
    ]
    
    # Interior mask (1=can be filled)
    interior = []
    for y in range(HH):
        row_interior = []
        inside = False
        for x in range(HW):
            if mask[y][x]:
                if not inside:
                    inside = True
                    row_interior.append(0)  # outline pixel
                else:
                    inside = False
                    row_interior.append(0)  # outline pixel
            else:
                if inside:
                    row_interior.append(1)  # interior pixel
                else:
                    row_interior.append(0)  # outside
        interior.append(row_interior)
    
    # Fill levels: 0=full red, 1=75%, 2=50%, 3=25%, 4=empty
    hearts = []
    for level in range(5):
        cutoff_row = level * 4  # rows from bottom to blacken (0,4,8,12,16)
    for level in range(5):
        cutoff_row = level * 3  # rows from bottom to blacken
        g = [[T]*HW for _ in range(HH)]
        for y in range(HH):
            for x in range(HW):
                if mask[y][x]:
                    g[y][x] = 183  # outline = black
                elif interior[y][x]:
                    if y >= HH - cutoff_row:
                        g[y][x] = 183  # empty = black
                    else:
                        g[y][x] = 190  # filled = red
        hearts.append((['full', '75', '50', '25', 'empty'][level], g))
    
    # Write to face_data.inc
    with open("src/face_data.inc", "a") as f:
        f.write("\n; --- HEART SPRITES: 20x18 x 5 fill levels ---\n")
        for name, grid in hearts:
            f.write(f"; heart_{name}\n")
            f.write(f"heart_{name}:\n")
            for row in grid:
                f.write(" db " + ",".join(str(c) for c in row) + "\n")
            f.write("\n")
        f.write("; Heart selector LUT: health% -> heart index\n")
        f.write("heart_table: dq heart_full, heart_75, heart_50, heart_25, heart_empty\n")
    
    # Preview
    chars = {T:'.', 183:'X', 190:'R'}
    print("Heart full preview:")
    for row in hearts[0][1]:
        print(''.join(chars.get(c,'?') for c in row))

if __name__ == '__main__':
    main()
