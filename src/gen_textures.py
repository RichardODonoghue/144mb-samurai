"""Generate all textures, palettes, shade tables for 144mb-samurai.
Outputs C header files: tex_gen.h, palette_data.h, shade_data.h
64x64 building textures (8-bit direct palette), 32x32 floor/hud textures.
"""

import math, random, os

rng = random.Random(1337)
PERM = list(range(256)); rng.shuffle(PERM); PERM = PERM * 2

def fade(t): return t*t*t*(t*(t*6-15)+10)
def noise(x, y):
    xi, yi = int(math.floor(x)) & 255, int(math.floor(y)) & 255
    xf, yf = x - int(math.floor(x)), y - int(math.floor(y))
    u, v = fade(xf), fade(yf)
    h = [PERM[PERM[xi]+yi], PERM[PERM[xi+1]+yi], PERM[PERM[xi]+yi+1], PERM[PERM[xi+1]+yi+1]]
    def grad(h,x,y): return ((h&1)and x or -x)+((h&2)and y or -y)
    return ((grad(h[0],xf,yf)*(1-u)+grad(h[1],xf-1,yf)*u)*(1-v)+(grad(h[2],xf,yf-1)*(1-u)+grad(h[3],xf-1,yf-1)*u)*v)
def fbm(x, y, octaves=3, lac=2.0, gain=0.5):
    val, amp, freq = 0.0, 1.0, 1.0
    for _ in range(octaves): val += noise(x*freq, y*freq)*amp; amp*=gain; freq*=lac
    return val
def cell_noise(x, y, scale=1.0):
    sx, sy = x*scale, y*scale; cx, cy = int(math.floor(sx)), int(math.floor(sy))
    min_d = 1e9
    for dx in (-1,0,1):
        for dy in (-1,0,1):
            px,py=PERM[(cx+dx)&255],PERM[(cy+dy)&255]
            d=math.sqrt((sx-cx-dx-(px/256.0))**2+(sy-cy-dy-(py/256.0))**2)
            if d<min_d: min_d=d
    return max(0.0, 1.0-min_d*3.0)

# Building palette indices (64-95)
W0,W1,W2,W3 = 64,65,66,67  # white plaster
R0,R1,R2,R3 = 68,69,70,71  # red lacquer
T0,T1,T2,T3 = 72,73,74,75  # dark timber
N0,N1,N2,N3 = 76,77,78,79  # natural tan wood
B0,B1,B2,B3 = 80,81,82,83  # warm brown wood
G0,G1,G2,G3 = 84,85,86,87  # grey roof tiles
S0,S1,S2,S3 = 88,89,90,91  # stone/foundation
M0,M1,M2,M3 = 92,93,94,95  # mural accents

def make_tex64(): return [[0]*64 for _ in range(64)]
def fill_rect(g,x,y,w,h,c):
    for dy in range(h):
        for dx in range(w):
            if 0<=x+dx<64 and 0<=y+dy<64: g[y+dy][x+dx]=c
def hline(g,y,x1,x2,c):
    for x in range(max(0,x1),min(64,x2+1)): g[y][x]=c
def vline(g,x,y1,y2,c):
    for y in range(max(0,y1),min(64,y2+1)): g[y][x]=c
def plaster_bg(g,ys,ye):
    for y in range(ys,ye):
        for x in range(64):
            n=noise(x*0.5,y*0.3)*0.5; g[y][x]=W0 if n>0.1 else (W1 if n>-0.1 else W2)
def plaster_noise(g,x,y):
    n=noise(x*0.4,y*0.4); return W0 if n>0.05 else (W1 if n>-0.1 else W2)
def timber_frame(g,x,y,base):
    n=noise(x*1.0,y*0.5); return base if n>0 else base+1

# ---- 6 Building Generators ----

def gen_machiya():
    g=make_tex64()
    for y in range(6):
        for x in range(64): n=noise(x*0.4,y*0.4); g[y][x]=S2 if n<-0.1 else S1
    plaster_bg(g,6,14); hline(g,14,0,63,T3); hline(g,13,0,63,T2)
    for y in range(15,32):
        for x in range(64):
            if x%5==0: g[y][x]=T2
            elif x%5==2: g[y][x]=T1
            else: g[y][x]=plaster_noise(g,x,y)
    for y in (32,33): hline(g,y,0,63,T2)
    plaster_bg(g,34,54)
    for y in range(38,52):
        for x in range(64):
            if int(x/8+y/4)%3==0 and noise(x*0.7,y*0.7)>0.3: g[y][x]=M0 if (x+y)%4<2 else W0
    for y in (54,55,56): hline(g,y,0,63,T2 if y==54 else T1)
    for y in range(57,64):
        for x in range(64): g[y][x]=G2 if (x//8+y)&1 else G1
    for y in range(0,13):
        for x in range(24,40): g[y][x]=T3
    vline(g,24,0,14,T1); vline(g,39,0,14,T1)
    for y in range(15,25):
        for x in range(26,38):
            if x==31 or x==32: g[y][x]=W0
            elif x<=30: g[y][x]=M2 if y%2==0 else B2
            else: g[y][x]=M2 if y%2 else B2
    hline(g,15,24,40,T1)
    fill_rect(g,44,40,10,8,T3); fill_rect(g,46,42,6,4,W0)
    return g

def gen_minka():
    g=make_tex64()
    for y in range(5):
        for x in range(64):
            n=cell_noise(x,y,0.3); g[y][x]=S3 if n<0.03 else (S2 if n<0.1 else S1)
    for y in (5,6): hline(g,y,0,63,T2)
    for y in range(7,53):
        for x in range(64):
            plank,edge=x//6,x%6
            if edge==0 or edge==5: g[y][x]=T3
            else:
                grain=fbm(x*0.08,y*0.5,3,2.0,0.5)
                g[y][x]=N1 if grain>0.25 else (N2 if grain>-0.1 else N3)
    for y in range(7,53,10): hline(g,y,0,63,T2)
    hline(g,53,0,63,T2); hline(g,54,0,63,T1); hline(g,55,0,63,T1)
    for y in range(56,64):
        for x in range(64): g[y][x]=G3 if (x//6+y)&1 else G1
    for y in range(5,25):
        for x in range(26,38): g[y][x]=B3
    vline(g,26,5,25,T1); vline(g,37,5,25,T1)
    fill_rect(g,12,30,8,8,T3); fill_rect(g,14,32,4,4,W0)
    return g

def gen_kura():
    g=make_tex64()
    for y in range(6):
        for x in range(64):
            n=cell_noise(x,y,0.35); g[y][x]=S3 if n<0.03 else (S2 if n<0.08 else S1)
    hline(g,6,0,63,T2)
    for y in range(7,57):
        for x in range(64):
            if (x%16)<=2 or (x%16)>=13: g[y][x]=timber_frame(g,x,y,T2)
            elif (y-7)%12<=1: g[y][x]=T2
            else: n=noise(x*0.5,y*0.3); g[y][x]=W0 if n>0 else W1
    for y in (57,58,59): hline(g,y,0,63,T2)
    for y in range(60,64):
        for x in range(64): g[y][x]=G2 if (x//8+y)&1 else G1
    cx,cy,ww,wh=32,42,8,8
    fill_rect(g,cx-ww//2-1,cy-wh//2-1,ww+2,wh+2,T3)
    fill_rect(g,cx-ww//2,cy-wh//2,ww,wh,T3)
    fill_rect(g,cx-3,cy-3,6,6,W0)
    vline(g,cx,cy-4,cy+3,T3); hline(g,cy,cx-4,cx+3,T3)
    for y in range(6,30):
        for x in range(26,38): g[y][x]=T3
    vline(g,26,6,30,T1); vline(g,37,6,30,T1); hline(g,18,26,37,T1)
    return g

def gen_temple():
    g=make_tex64()
    for y in range(4): hline(g,y,0,63,S1 if y<3 else S2)
    for y in range(4,56):
        for x in range(64):
            if 6<=x<=12: g[y][x]=R1 if noise(x,y*0.3)>0 else R2
            elif 52<=x<=58: g[y][x]=R1 if noise(x,y*0.3)>0 else R2
            else: n=noise(x*0.5,y*0.3); g[y][x]=W0 if n>0.05 else W1
    for y in range(4,8):
        for x in range(6,13): g[y][x]=R3 if noise(x,y)>0 else R2
        for x in range(52,59): g[y][x]=R3 if noise(x,y)>0 else R2
    for y in range(28,34):
        for x in range(14,52): g[y][x]=T2
    hline(g,28,0,63,T2); hline(g,33,0,63,T2)
    fill_rect(g,12,29,4,4,M1); fill_rect(g,50,29,4,4,M1)
    for y in range(50,57):
        for x in range(14,52):
            if y>=53 and (x%8<=2): g[y][x]=T2
            elif y>=50 and (x%20<=3 or x%20>=17): g[y][x]=T1
            elif y==52: g[y][x]=T2 if x%16<8 else T1
    for y in range(57,60): hline(g,y,0,63,T3)
    for y in range(60,64):
        for x in range(64): g[y][x]=G1 if (x//6+y)&1 else G2
    for y in range(14,26):
        for x in range(26,38):
            g[y][x]=M1 if (x==31 or x==32) else (M2 if noise(x,y)>0 else R3)
    fill_rect(g,24,13,16,2,T2); fill_rect(g,24,26,16,2,T2)
    return g

def gen_castle():
    g=make_tex64()
    for y in range(20):
        for x in range(64):
            n=cell_noise(x,y,0.35); g[y][x]=S3 if n<0.04 else (S2 if n<0.15 else S1)
    for y in (20,21): hline(g,y,0,63,S1)
    for y in (22,23): hline(g,y,0,63,T2)
    for y in range(24,55):
        for x in range(64):
            if x%22<=2 or x%22>=19: g[y][x]=timber_frame(g,x,y,T2)
            elif (y-24)%10<=1: g[y][x]=T2
            else: n=noise(x*0.5,y*0.3); g[y][x]=W0 if n>0 else W1
    for x_base in (11,33,55):
        if x_base>=64: continue
        fill_rect(g,x_base,28,2,10,T3)
        fill_rect(g,x_base-1,27,4,1,T1); fill_rect(g,x_base-1,38,4,1,T1)
    for y in range(55,59): hline(g,y,0,63,T2)
    for y in range(56,59):
        for x in range(4,60,8): fill_rect(g,x-1,y-1,3,3,T1)
    for y in range(59,64):
        for x in range(64): g[y][x]=G2 if (x//6+y)&1 else G1
    return g

def gen_residence():
    g=make_tex64()
    for y in range(5): hline(g,y,0,63,S2 if y<4 else T2)
    for y in range(5,12):
        for x in range(64): g[y][x]=T2 if (x//8)%2==0 else T1
    hline(g,11,0,63,T2)
    for y in range(12,52):
        for x in range(64):
            if x%20<=1 or x%20>=18: g[y][x]=timber_frame(g,x,y,T1)
            elif (y-12)%14<=1: g[y][x]=T2
            else: n=noise(x*0.5,y*0.3); g[y][x]=W0 if n>-0.05 else W1
    for y in range(16,46):
        for x in range(64):
            if x%20<=2 or x%20>=17: continue
            dx,dy=abs((x%20)-10),abs((y%14)-7)
            if dx+dy<6: g[y][x]=M0 if noise(x*0.8,y*0.8)>0 else M1
    for y in range(5,42):
        for x in range(24,28): g[y][x]=T1
        for x in range(36,40): g[y][x]=T1
    hline(g,28,24,39,T2); hline(g,29,24,39,T2)
    fill_rect(g,22,30,20,3,T2)
    for y in range(28,30):
        for x in range(22,42): g[y][x]=G1 if (x//4+y)&1 else G2
    for y in (52,53): hline(g,y,0,63,T2)
    for y in (54,55,56): hline(g,y,0,63,T1 if y<56 else T3)
    for y in range(57,64):
        for x in range(64): g[y][x]=G1 if (x//6+y)&1 else G2
    return g

BUILDING_GENERATORS = {
    'machiya': gen_machiya, 'minka': gen_minka, 'kura': gen_kura,
    'temple': gen_temple, 'castle': gen_castle, 'residence': gen_residence,
}

# ---- Floor textures (32x32, 4-bit) ----

def gen_floor_dirt():
    rows=[]
    for y in range(32):
        row=[]
        for x in range(32):
            n=fbm(x*0.3,y*0.3,4,2.0,0.5)
            v=int((n+1.0)*3.5); v=min(7,max(0,v))
            if PERM[(x+y*31)&255]<30: v=min(v+2,7)
            if PERM[(y+x*17)&255]<10: v=max(0,v-1)
            row.append(v)
        rows.append(row)
    return rows

_knot_seed=random.Random(42)
_knots=[(_knot_seed.randint(4,28),_knot_seed.randint(4,28),3) for _ in range(3)]
def gen_floor_wood():
    rows=[]
    for y in range(32):
        row=[]
        for x in range(32):
            n=fbm(x*0.08,y*1.2,4,2.0,0.5); v=2+int((n+1.0)*2.5); v=min(7,max(1,v))
            for kx,ky,kr in _knots:
                if ((x-kx)**2+(y-ky)**2)<kr**2: v=min(v+2,7)
            if y%8==0: v=max(1,v-2)
            row.append(v)
        rows.append(row)
    return rows

def gen_floor_stone():
    rows=[]
    for y in range(32):
        row=[]
        for x in range(32):
            c=cell_noise(x,y,0.22)
            if c<0.03: row.append(2)
            else:
                n=fbm(x*0.3,y*0.3,3,2.0,0.6); v=3+int((n+1.0)*2.0); v=min(7,max(3,v))
                if PERM[(x//8+y//8*7)&255]&3==0: v=min(v,5)
                row.append(v)
        rows.append(row)
    return rows

def gen_hud_panel():
    rows=[]
    for y in range(32):
        row=[]
        for x in range(32):
            n=fbm(x*0.2,y*0.2,2,2.0,0.5); v=int((n+1.0)*1.5)
            if PERM[(x+y*31)&255]<5: v=min(v+2,7)
            if PERM[(y+x*17)&255]<20: v=max(0,v-1)
            row.append(v)
        rows.append(row)
    return rows

def gen_roof_tile():
    rows=[]
    for y in range(32):
        row=[]; tr=y//16; wt=y%16
        for x in range(32):
            if wt<=1: row.append(251)
            elif wt<=3: row.append(248)
            elif wt<=5: row.append(253 if x%6<2 else 249)
            elif wt<=12: row.append(248 if (x+tr*8)%13<3 else 249)
            elif wt<=14: row.append(248)
            else: row.append(251)
        rows.append(row)
    return rows

def gen_foundation_tile():
    rows=[]
    for y in range(8):
        row=[]; bx,by=y//4,y//4
        for x in range(32):
            if x%8==0 or y%4==0: row.append(251)
            else:
                n=PERM[(x+y*31+bx*17)&255]/255.0
                row.append(248 if n<0.25 else (252 if n<0.6 else 253))
        rows.append(row)
    return rows

# ---- Palette generation ----

def pal_hex(r,g,b): return f"0x00{r:02X}{g:02X}{b:02X}"
def lerp_rgb(c1,c2,t): return (int(c1[0]+(c2[0]-c1[0])*t),int(c1[1]+(c2[1]-c1[1])*t),int(c1[2]+(c2[2]-c1[2])*t))
def grad4(dark,bright): return [pal_hex(*lerp_rgb(dark,bright,i/3)) for i in range(4)]

def gen_building_palette():
    e=[]
    e.extend(grad4((200,195,185),(240,238,230)))  # white
    e.extend(grad4((140,35,25),(210,60,40)))      # red
    e.extend(grad4((35,22,15),(80,50,35)))        # timber
    e.extend(grad4((120,90,65),(200,160,120)))    # tan wood
    e.extend(grad4((80,45,25),(160,100,60)))      # warm wood
    e.extend(grad4((50,48,52),(110,105,108)))     # roof grey
    e.extend(grad4((80,75,70),(150,145,140)))     # stone
    e.append(pal_hex(40,130,140)); e.append(pal_hex(210,180,100))
    e.append(pal_hex(180,30,20)); e.append(pal_hex(80,110,60))
    return e

def gen_floor_palette(dark,mid,bright):
    out=[]
    for i in range(4): out.append(pal_hex(*lerp_rgb(dark,mid,i/3)))
    for i in range(4): out.append(pal_hex(*lerp_rgb(mid,bright,i/3)))
    return out

def gen_floor_pal_dark(entries,factor=0.55):
    out=[]
    for e in entries:
        r=int(int(e[4:6],16)*factor); g=int(int(e[6:8],16)*factor); b=int(int(e[8:10],16)*factor)
        out.append(pal_hex(r,g,b))
    return out

def gen_shade_table():
    table=[]
    for d in range(64):
        dist=d*0.5
        if dist<=2: s=0
        elif dist<=4: s=1
        elif dist<=8: s=2
        elif dist<=16: s=3
        elif dist<=24: s=4
        elif dist<=32: s=5
        elif dist<=40: s=6
        else: s=7
        table.append(s)
    return table

def gen_shade_lut():
    luts=[]; offsets=[0,1,2,3]
    for offset in offsets:
        lut=list(range(256))
        for i in range(64,96):
            family=(i-64)//4; sub=(i-64)%4; new_sub=min(3,sub+offset)
            lut[i]=64+family*4+new_sub
        luts.append(lut)
    return luts

def gen_floor_gradient():
    grad=[]
    for y in range(100):
        t=y/99.0; bright=1.0-t*t*0.85; val=int(96+(127-96)*(1.0-bright)); val=max(96,min(127,val))
        grad.append(val)
    return grad

def gen_sky_gradient():
    grad=[]
    for y in range(100):
        t=1.0-y/99.0; bright=t*t; val=int(63*(1.0-bright)); val=max(0,val)
        grad.append(val)
    return grad

def gen_roof_profile():
    profile=[]
    for x in range(32):
        t=x/31.0; h=math.sin(t*math.pi)*16; curl=0
        if t<0.25: curl=6*(1.0-t/0.25)
        elif t>0.75: curl=6*((t-0.75)/0.25)
        profile.append(int(h+curl))
    return profile

def gen_roof_type_heights(): return [18,14,8,16,20,16]

def gen_vignette_lut():
    lut=[]
    for i in range(256):
        if i<64: d=max(0,i-3)
        elif i<96: d=max(64,i-2)
        elif i<176: d=max(64,i-1)
        else: d=i
        lut.append(d)
    return lut

def gen_vignette_rle():
    w,h=320,200; cx,cy=w/2,h/2; runs=[]; count=0; current=None
    for y in range(h):
        for x in range(w):
            dx=(x-cx)/(w*0.46); dy=(y-cy)/(h*0.46); d=math.sqrt(dx*dx+dy*dy)
            v=1 if d>0.95 else 0
            if v!=current:
                if count>0: runs.append(f"    {count},{current},")
                current=v; count=1
            else:
                count+=1
                if count==255: runs.append(f"    {count},{current},"); count=0
    if count>0: runs.append(f"    {count},{current},")
    return runs,w*h


# ---- C HEADER OUTPUT ----

def write_tex_c(f, name, rows, w, direct=False):
    f.write(f"static const unsigned char tex_{name}[{w}*{w}] = {{\n")
    for row in rows:
        f.write("    "+",".join(str(b) for b in row)+",\n")
    f.write("};\n\n")

def write_tex_rect_c(f, name, rows, w, h):
    f.write(f"static const unsigned char tex_{name}[{h}][{w}] = {{\n")
    for row in rows:
        f.write("    {"+",".join(str(b) for b in row)+"},\n")
    f.write("};\n\n")

def write_pal_c(f, name, entries):
    count = len(entries)
    f.write(f"static const unsigned int {name}[{count}] = {{\n")
    for i in range(0, count, 4):
        f.write("    "+", ".join(entries[i:i+4])+",\n")
    f.write("};\n\n")

def main():
    out_dir = os.path.join(os.path.dirname(__file__) or ".")
    tex_path = os.path.join(out_dir, "tex_gen.h")
    pal_path = os.path.join(out_dir, "palette_data.h")
    shade_path = os.path.join(out_dir, "shade_data.h")

    print("Generating building textures (64x64)...")
    with open(tex_path, "w") as f:
        f.write("// Auto-generated textures for 144mb-samurai\n")
        f.write("#ifndef TEX_GEN_H\n#define TEX_GEN_H\n\n")
        for name, gen_fn in BUILDING_GENERATORS.items():
            rows = gen_fn(); write_tex_c(f, name, rows, 64)
            print(f"  tex_{name} (64x64)")
        print("Generating floor textures (32x32)...")
        for name, gen_fn in [('floor_dirt',gen_floor_dirt),('floor_stone',gen_floor_stone),('floor_wood',gen_floor_wood),('hud_panel',gen_hud_panel)]:
            rows = gen_fn(); write_tex_c(f, name, rows, 32)
        print("Generating roof/foundation...")
        write_tex_rect_c(f, 'roof', gen_roof_tile(), 32, 32)
        write_tex_rect_c(f, 'foundation', gen_foundation_tile(), 32, 8)
        f.write("#endif // TEX_GEN_H\n")

    print("Generating palettes...")
    with open(pal_path, "w") as f:
        f.write("// Auto-generated palette data\n")
        f.write("#ifndef PALETTE_DATA_H\n#define PALETTE_DATA_H\n\n")
        f.write("// Building palette (64-95): 32 entries\n")
        write_pal_c(f, "pal_building", gen_building_palette())
        for name, dark, mid, bright in [
            ('floor_dirt_x',(40,25,10),(90,60,30),(150,110,70)),
            ('floor_stone_x',(50,45,40),(100,95,90),(160,155,150)),
            ('floor_wood_x',(40,20,10),(120,65,35),(210,140,90))]:
            px=gen_floor_palette(dark,mid,bright); py=gen_floor_pal_dark(px)
            write_pal_c(f, f"pal_{name}", px); write_pal_c(f, f"pal_{name.replace('_x','_y')}", py)
        pal_wpn=[pal_hex(0,255,0),pal_hex(50,50,50),pal_hex(192,192,208),pal_hex(240,240,255),pal_hex(40,20,10),pal_hex(220,180,160),pal_hex(180,140,115),pal_hex(0,0,0)]
        write_pal_c(f, "pal_weapon", pal_wpn)
        for cycle in range(4):
            entries=[pal_hex(255-cycle*20,140+cycle*30,cycle*15),pal_hex(200-cycle*15,80+cycle*20,cycle*10),pal_hex(150-cycle*10,40+cycle*15,0),pal_hex(100-cycle*5,20,0)]
            write_pal_c(f, f"fire_cycle{cycle}", entries)
        fog=[pal_hex(int(20+120*i/31),int(20+30*i/31),int(50+150*i/31)) for i in range(32)]
        write_pal_c(f, "pal_fog", fog)
        f.write("#endif // PALETTE_DATA_H\n")

    print("Generating data tables...")
    shade_table=gen_shade_table(); floor_grad=gen_floor_gradient(); sky_grad=gen_sky_gradient()
    shade_luts=gen_shade_lut(); vig_lut=gen_vignette_lut(); vig_rle,vig_len=gen_vignette_rle()
    roof_profile=gen_roof_profile(); roof_heights=gen_roof_type_heights()
    with open(shade_path, "w") as f:
        f.write("// Auto-generated shade/gradient/vignette/roof tables\n")
        f.write("#ifndef SHADE_DATA_H\n#define SHADE_DATA_H\n\n")
        f.write("static const unsigned char shade_table[64] = {"+",".join(str(s) for s in shade_table)+"};\n\n")
        f.write("static const unsigned char shade_lut[4][256] = {\n")
        for band in shade_luts:
            f.write("    {"); f.write(",".join(str(b) for b in band[0:128])); f.write(",\n")
            f.write("     "); f.write(",".join(str(b) for b in band[128:256])); f.write("},\n")
        f.write("};\n\n")
        f.write("static const unsigned char floor_gradient[100] = {"+",".join(str(s) for s in floor_grad)+"};\n\n")
        f.write("static const unsigned char sky_gradient[100] = {"+",".join(str(s) for s in sky_grad)+"};\n\n")
        f.write("static const unsigned char roof_profile[32] = {"+",".join(str(h) for h in roof_profile)+"};\n\n")
        f.write("static const unsigned char roof_type_height[6] = {"+",".join(str(h) for h in roof_heights)+"};\n\n")
        f.write("static const unsigned char vignette_lut[256] = {"+",".join(str(v) for v in vig_lut)+"};\n\n")
        f.write(f"// vignette_rle ({vig_len} bytes uncompressed)\n")
        f.write("static const unsigned char vignette_rle[] = {\n")
        for line in vig_rle: f.write(line+"\n")
        f.write("};\n")
        f.write(f"static const int vignette_rle_count = {(len(vig_rle)*2)};\n")
        f.write(f"static const int vignette_full_len = {vig_len};\n")
        f.write("#endif // SHADE_DATA_H\n")

    print("Done.")

if __name__ == "__main__": main()
