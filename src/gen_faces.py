"""Generate 24x20 samurai face sprites + 20x18 hearts for HUD.
Outputs C header: faces.h
"""
import os

BG=254; SK=181; SD=182; BL=183; RD=190; BR=250; T=254

def face_grid(): return [[T]*24 for _ in range(20)]
def draw_rect(g,x,y,w,h,c):
    for dy in range(h):
        for dx in range(w):
            if 0<=x+dx<24 and 0<=y+dy<20: g[y+dy][x+dx]=c
def draw_pixel(g,x,y,c):
    if 0<=x<24 and 0<=y<20: g[y][x]=c

def draw_eyebrow(g,lx,rx,y,angled=False):
    if angled:
        draw_pixel(g,lx-2,y+1,BL); draw_pixel(g,lx-1,y,BL); draw_pixel(g,lx,y,BL); draw_pixel(g,lx+1,y,BL)
        draw_pixel(g,rx-1,y,BL); draw_pixel(g,rx,y,BL); draw_pixel(g,rx+1,y,BL); draw_pixel(g,rx+2,y+1,BL)
    else:
        draw_pixel(g,lx-2,y,BL); draw_pixel(g,lx-1,y,BL); draw_pixel(g,lx,y,BL); draw_pixel(g,lx+1,y,BL)
        draw_pixel(g,rx-1,y,BL); draw_pixel(g,rx,y,BL); draw_pixel(g,rx+1,y,BL); draw_pixel(g,rx+2,y,BL)

def gen_healthy():
    g=face_grid()
    draw_rect(g,5,0,14,1,BL); draw_rect(g,4,1,16,1,BL)
    draw_rect(g,3,2,18,1,BL); draw_rect(g,3,3,18,1,BL)
    draw_rect(g,4,4,16,1,BL); draw_rect(g,3,5,18,2,BL)
    draw_rect(g,4,7,16,2,SK)
    draw_eyebrow(g,8,15,9)
    draw_pixel(g,7,10,SD); draw_pixel(g,8,10,BL); draw_pixel(g,9,10,BL); draw_pixel(g,10,10,SD)
    draw_pixel(g,13,10,SD); draw_pixel(g,14,10,BL); draw_pixel(g,15,10,BL); draw_pixel(g,16,10,SD)
    draw_pixel(g,7,11,SD); draw_pixel(g,8,11,BL); draw_pixel(g,9,11,SK); draw_pixel(g,10,11,SD)
    draw_pixel(g,13,11,SD); draw_pixel(g,14,11,SK); draw_pixel(g,15,11,BL); draw_pixel(g,16,11,SD)
    draw_pixel(g,7,12,SD); draw_pixel(g,8,12,BL); draw_pixel(g,9,12,BL); draw_pixel(g,10,12,SD)
    draw_pixel(g,13,12,SD); draw_pixel(g,14,12,BL); draw_pixel(g,15,12,BL); draw_pixel(g,16,12,SD)
    for x in range(9,15): draw_pixel(g,x,13,SD)
    draw_pixel(g,9,14,SD); draw_pixel(g,10,14,SD); draw_pixel(g,11,14,SD)
    draw_pixel(g,12,14,BL); draw_pixel(g,13,14,SD); draw_pixel(g,14,14,SD)
    draw_pixel(g,11,15,SD); draw_pixel(g,12,15,SD)
    for x in range(9,15): draw_pixel(g,x,16,BL)
    for x in range(10,14): draw_pixel(g,x,17,SD)
    draw_rect(g,5,18,14,1,SD); draw_rect(g,4,19,16,1,BL)
    for y in range(7,19):
        for x in range(24):
            if g[y][x]==T and 3<=x<=20: g[y][x]=SK
    for y in range(7,18):
        if g[y][4]==SK: g[y][4]=SD
        if g[y][19]==SK: g[y][19]=SD
    return g

def gen_hurt1():
    g=gen_healthy()
    draw_pixel(g,17,14,RD); draw_pixel(g,18,15,RD); draw_pixel(g,18,16,RD)
    draw_pixel(g,8,16,BL); draw_pixel(g,15,16,BL)
    draw_pixel(g,7,9,BL); draw_pixel(g,10,9,T)
    return g

def gen_hurt2():
    g=gen_healthy()
    draw_rect(g,5,13,3,4,BR); draw_rect(g,4,14,2,2,BR)
    draw_pixel(g,16,10,RD); draw_pixel(g,17,11,RD); draw_pixel(g,17,12,RD); draw_pixel(g,18,13,RD)
    draw_pixel(g,17,14,RD); draw_pixel(g,18,15,RD)
    draw_pixel(g,6,12,RD); draw_pixel(g,5,13,RD)
    draw_pixel(g,8,16,BL); draw_pixel(g,15,16,BL)
    draw_pixel(g,11,16,SK); draw_pixel(g,12,16,SK)
    draw_pixel(g,7,9,BL); draw_pixel(g,16,9,BL)
    draw_pixel(g,10,9,T); draw_pixel(g,13,9,T)
    return g

def gen_hurt3():
    g=gen_healthy()
    draw_rect(g,5,10,5,3,BR); draw_pixel(g,8,11,RD)
    draw_rect(g,4,9,3,2,BR); draw_rect(g,4,13,4,3,BR)
    draw_pixel(g,11,13,RD); draw_pixel(g,12,13,RD)
    draw_pixel(g,11,14,RD); draw_pixel(g,12,14,RD)
    draw_pixel(g,11,15,RD); draw_pixel(g,12,15,RD)
    draw_pixel(g,17,14,RD); draw_pixel(g,18,15,RD); draw_pixel(g,19,16,RD)
    draw_pixel(g,7,14,RD); draw_pixel(g,15,13,RD); draw_pixel(g,16,14,RD)
    draw_pixel(g,7,16,BL); draw_pixel(g,16,16,BL)
    draw_pixel(g,10,17,RD); draw_pixel(g,11,17,RD); draw_pixel(g,12,17,RD); draw_pixel(g,13,17,RD)
    draw_pixel(g,11,16,RD); draw_pixel(g,12,16,RD)
    draw_pixel(g,7,9,BL); draw_pixel(g,16,9,BL)
    return g

def gen_hurt4():
    g=gen_healthy()
    draw_rect(g,5,10,5,3,BR); draw_rect(g,13,10,5,3,BR)
    draw_pixel(g,8,11,RD); draw_pixel(g,15,11,RD)
    draw_rect(g,4,8,16,2,BR); draw_rect(g,3,13,18,4,BR)
    for x,y in [(5,11),(6,12),(7,14),(8,15),(9,16),(10,17),(14,13),(15,14),(16,15),(17,14),(18,12),(11,13),(12,13),(13,14),(11,16),(12,16)]:
        draw_pixel(g,x,y,RD)
    for x in (11,12):
        for y in (13,14,15,16): draw_pixel(g,x,y,RD)
    draw_pixel(g,8,16,BL); draw_pixel(g,9,16,BL); draw_pixel(g,14,16,BL); draw_pixel(g,15,16,BL)
    draw_pixel(g,10,17,BL); draw_pixel(g,11,17,BL); draw_pixel(g,12,17,BL); draw_pixel(g,13,17,BL)
    draw_pixel(g,11,16,RD); draw_pixel(g,12,16,RD)
    draw_pixel(g,10,18,RD); draw_pixel(g,11,18,RD); draw_pixel(g,12,18,RD); draw_pixel(g,13,18,RD)
    draw_pixel(g,6,1,T); draw_pixel(g,7,2,T); draw_pixel(g,18,3,T)
    return g

def gen_heart_sprites():
    HW,HH=20,18
    mask=[
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
    interior=[]
    for y in range(HH):
        ri=[]; inside=False
        for x in range(HW):
            if mask[y][x]:
                if not inside: inside=True; ri.append(0)
                else: inside=False; ri.append(0)
            else:
                ri.append(1 if inside else 0)
        interior.append(ri)
    hearts=[]
    for level in range(5):
        cutoff=level*3; g=[[T]*HW for _ in range(HH)]
        for y in range(HH):
            for x in range(HW):
                if mask[y][x]: g[y][x]=183
                elif interior[y][x]:
                    g[y][x]=183 if y>=HH-cutoff else 190
        hearts.append((['full','75','50','25','empty'][level],g))
    return hearts

def grid_to_c_array(g, name):
    h=len(g); w=len(g[0])
    lines=[f"static const unsigned char {name}[{h}][{w}] = {{"]
    for row in g:
        lines.append("    {"+",".join(str(c) for c in row)+"},")
    lines.append("};")
    return "\n".join(lines)

def main():
    faces=[("healthy",gen_healthy()),("hurt1",gen_hurt1()),("hurt2",gen_hurt2()),("hurt3",gen_hurt3()),("hurt4",gen_hurt4())]
    hearts=gen_heart_sprites()
    out=os.path.join(os.path.dirname(__file__),"faces.h")
    with open(out,"w") as f:
        f.write("// Auto-generated face and heart sprites for HUD\n")
        f.write("#ifndef FACES_H\n#define FACES_H\n\n")
        for name,grid in faces:
            f.write(f"// Face: {name} (24x20)\n")
            f.write(grid_to_c_array(grid,f"face_{name}")+"\n\n")
        f.write("static const unsigned char* const face_table[5] = {\n")
        f.write("    (const unsigned char*)face_healthy,\n")
        f.write("    (const unsigned char*)face_hurt1,\n")
        f.write("    (const unsigned char*)face_hurt2,\n")
        f.write("    (const unsigned char*)face_hurt3,\n")
        f.write("    (const unsigned char*)face_hurt4,\n")
        f.write("};\n\n")
        for name,grid in hearts:
            f.write(f"// Heart: {name} (20x18)\n")
            f.write(grid_to_c_array(grid,f"heart_{name}")+"\n\n")
        f.write("static const unsigned char* const heart_table[5] = {\n")
        f.write("    (const unsigned char*)heart_full,\n")
        f.write("    (const unsigned char*)heart_75,\n")
        f.write("    (const unsigned char*)heart_50,\n")
        f.write("    (const unsigned char*)heart_25,\n")
        f.write("    (const unsigned char*)heart_empty,\n")
        f.write("};\n\n")
        f.write("#endif // FACES_H\n")
    print(f"Generated {out}")

if __name__=="__main__": main()
