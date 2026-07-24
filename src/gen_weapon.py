"""Generate katana weapon and arm sprites for 144mb-samurai.
Outputs C header: sprites.h
"""

import math, os

T=0; TSUBA=177; BLADE=178; SHINE=179; WRAP=180; SKIN_L=181; SKIN_D=182; BLACK=183
SRC_DIR = os.path.dirname(__file__)

def make_grid(w,h): return [[T]*w for _ in range(h)]
def pset(g,x,y,c):
    x,y=int(round(x)),int(round(y))
    if 0<=x<len(g[0]) and 0<=y<len(g): g[y][x]=c
def draw_line(g,x1,y1,x2,y2,c):
    x1,y1=int(round(x1)),int(round(y1)); x2,y2=int(round(x2)),int(round(y2))
    dx=abs(x2-x1); sx=1 if x1<x2 else -1; dy=-abs(y2-y1); sy=1 if y1<y2 else -1; err=dx+dy
    while True:
        pset(g,x1,y1,c)
        if x1==x2 and y1==y2: break
        e2=2*err
        if e2>=dy: err+=dy; x1+=sx
        if e2<=dx: err+=dx; y1+=sy
def rot(x,y,a):
    c,s=math.cos(a),math.sin(a); return x*c-y*s,x*s+y*c
def _lerp_segments(pts,y):
    for i in range(len(pts)-1):
        y1,y2=pts[i][1],pts[i+1][1]
        if min(y1,y2)<=y<=max(y1,y2):
            if abs(y2-y1)<0.0001: return pts[i][0]
            t=(y-y1)/(y2-y1); return pts[i][0]+t*(pts[i+1][0]-pts[i][0])
    return None
def fill_scanlines(g,left_pts,right_pts,c):
    if len(left_pts)<2 or len(right_pts)<2: return
    min_y=int(math.floor(min(p[1] for p in left_pts+right_pts)))
    max_y=int(math.ceil(max(p[1] for p in left_pts+right_pts)))
    for y in range(min_y,max_y+1):
        lx=_lerp_segments(left_pts,y)
        if lx is None: continue
        rx=_lerp_segments(right_pts,y)
        if rx is None: continue
        if lx>rx: lx,rx=rx,lx
        for x in range(int(math.floor(lx)),int(math.ceil(rx))+1): pset(g,x,y,c)
def fill_spine_strip(g,edge1,edge2,c):
    min_y=int(math.floor(min(p[1] for p in edge1+edge2)))
    max_y=int(math.ceil(max(p[1] for p in edge1+edge2)))
    for y in range(min_y,max_y+1):
        x1=_lerp_segments(edge1,y); x2=_lerp_segments(edge2,y)
        if x1 is not None and x2 is not None:
            if x1>x2: x1,x2=x2,x1
            for x in range(int(math.floor(x1)),int(math.ceil(x2))+1): pset(g,x,y,c)

# Blade geometry
SPINE_BASE=(0,5); SPINE_MID=(1,-65); TIP=(3,-95)
EDGE_MID=(-9,-65); EDGE_BASE=(-10,5)
HANDLE_TOP_Y=5; HANDLE_LENGTH=52
HANDLE_W_TOP=7; HANDLE_W_BOT=6
TSUBA_RX=12; TSUBA_RY=4; POMMEL_LEN=5; POMMEL_W=9

def draw_oval(g,cx,cy,rx,ry,angle,c,fill=True):
    ca,sa=math.cos(angle),math.sin(angle)
    min_x=int(cx-rx-3); max_x=int(cx+rx+3); min_y=int(cy-ry-3); max_y=int(cy+ry+3)
    for y in range(min_y,max_y+1):
        for x in range(min_x,max_x+1):
            dx,dy=x-cx,y-cy; lx=dx*ca+dy*sa; ly=-dx*sa+dy*ca
            if fill:
                if (lx/rx)**2+(ly/ry)**2<=1.0: pset(g,x,y,c)
            else:
                d=(lx/rx)**2+(ly/ry)**2
                if 0.75<=d<=1.35: pset(g,x,y,c)

def draw_katana(g,rot_angle=0.0,cx=75,cy=100):
    def rtp(x,y): rx,ry=rot(x,y,rot_angle); return (rx+cx,ry+cy)
    spine_base=rtp(*SPINE_BASE); spine_mid=rtp(*SPINE_MID); tip=rtp(*TIP)
    edge_mid=rtp(*EDGE_MID); edge_base=rtp(*EDGE_BASE)
    htop=rtp(0,HANDLE_TOP_Y); hbot=rtp(0,HANDLE_TOP_Y+HANDLE_LENGTH)
    fill_scanlines(g,[edge_base,edge_mid,tip],[spine_base,spine_mid,tip],BLADE)
    draw_line(g,*spine_base,*spine_mid,BLACK); draw_line(g,*spine_mid,*tip,BLACK)
    draw_line(g,*edge_base,*edge_mid,BLACK); draw_line(g,*edge_mid,*tip,BLACK)
    sb=(spine_base[0]+(edge_base[0]-spine_base[0])*0.30,spine_base[1]+(edge_base[1]-spine_base[1])*0.30)
    sm=(spine_mid[0]+(edge_mid[0]-spine_mid[0])*0.30,spine_mid[1]+(edge_mid[1]-spine_mid[1])*0.30)
    draw_line(g,*sb,*sm,BLACK)
    steps=60
    for i in range(steps+1):
        t=i/steps
        if t<0.5: s=t*2; ex=edge_base[0]+(edge_mid[0]-edge_base[0])*s; ey=edge_base[1]+(edge_mid[1]-edge_base[1])*s; sx=spine_base[0]+(spine_mid[0]-spine_base[0])*s; sy=spine_base[1]+(spine_mid[1]-spine_base[1])*s
        else: s=(t-0.5)*2; ex=edge_mid[0]+(tip[0]-edge_mid[0])*s; ey=edge_mid[1]+(tip[1]-edge_mid[1])*s; sx=spine_mid[0]+(tip[0]-spine_mid[0])*s; sy=spine_mid[1]+(tip[1]-spine_mid[1])*s
        dx,dy=sx-ex,sy-ey; length=math.sqrt(dx*dx+dy*dy)
        if length>0: nx,ny=dx/length,dy/length
        else: nx,ny=0.0,1.0
        for off in (1,2): pset(g,ex+nx*off,ey+ny*off,SHINE)
    for dy in range(-2,3):
        for dx in range(-2,3):
            if dx*dx+dy*dy<=3: pset(g,tip[0]+dx,tip[1]+dy,SHINE)
    hdx=hbot[0]-htop[0]; hdy=hbot[1]-htop[1]; hlen=math.sqrt(hdx**2+hdy**2)
    hnx,hn=-hdy,hdx
    if hlen>0: hnx,hn=-hdy/hlen,hdx/hlen; hny=hn
    hw_top=HANDLE_W_TOP; hw_bot=HANDLE_W_BOT
    tl=(htop[0]+hnx*hw_top,htop[1]+hn*hw_top); tr=(htop[0]-hnx*hw_top,htop[1]-hn*hw_top)
    bl=(hbot[0]+hnx*hw_bot,hbot[1]+hn*hw_bot); br=(hbot[0]-hnx*hw_bot,hbot[1]-hn*hw_bot)
    fill_scanlines(g,[tl,bl],[tr,br],BLACK)
    for i in range(int(hlen)):
        t=i/max(hlen,1); hx=htop[0]+hdx*t; hy=htop[1]+hdy*t; hw=HANDLE_W_TOP*(1-t)+HANDLE_W_BOT*t
        phase=i%5
        if phase<2: start,end=-int(hw)+1,int(hw)
        elif phase==2: start,end=-int(hw)+2,int(hw)-1
        else: start,end=0,-1
        for j in range(start,end): pset(g,hx+hnx*j,hy+hn*j,WRAP)
    for fy in (1,4):
        fx,fy_rot=rtp(0,fy)
        for j in range(-HANDLE_W_TOP,HANDLE_W_TOP+1): pset(g,int(round(fx+hnx*j)),int(round(fy_rot+hn*j)),BLACK)
        for j in range(-HANDLE_W_TOP+1,HANDLE_W_TOP): pset(g,int(round(fx+hnx*j)),int(round(fy_rot+hn*j)),TSUBA)
    for i in range(POMMEL_LEN+1):
        t=i/max(POMMEL_LEN,1); hx=hbot[0]+hdx/max(HANDLE_LENGTH,1)*i; hy=hbot[1]+hdy/max(HANDLE_LENGTH,1)*i
        pw=POMMEL_W*(1-t)+HANDLE_W_BOT*t
        for j in range(-int(pw),int(pw)+1): pset(g,hx+hnx*j,hy+hn*j,BLACK)
        if i<3:
            for j in range(-int(pw)+1,int(pw)): pset(g,hx+hnx*j,hy+hn*j,WRAP)
    draw_oval(g,cx,cy,TSUBA_RX,TSUBA_RY,rot_angle,TSUBA)
    draw_oval(g,cx,cy,TSUBA_RX+1,TSUBA_RY+1,rot_angle,BLACK,fill=False)
    draw_oval(g,cx,cy,TSUBA_RX*0.45,TSUBA_RY+1.5,rot_angle,BLACK,fill=False)
    draw_oval(g,cx,cy,3,1.5,rot_angle,BLACK)

def draw_arms(g,rot_angle=0.0,cx=65,cy=40):
    w,h=len(g[0]),len(g)
    def rtp(x,y): rx,ry=rot(x,y,rot_angle); return (rx+cx,ry+cy)
    grip=rtp(0,HANDLE_TOP_Y+HANDLE_LENGTH*0.35)
    r_bot1=rtp(45,HANDLE_LENGTH+15); r_bot2=rtp(20,HANDLE_LENGTH+15)
    r_top1=(grip[0]+8,grip[1]-4); r_top2=(grip[0]-2,grip[1]+4)
    l_bot1=rtp(-20,HANDLE_LENGTH+25); l_bot2=rtp(-45,HANDLE_LENGTH+25)
    l_top1=(grip[0]-6,grip[1]-2); l_top2=(grip[0]-14,grip[1]+6)
    fill_spine_strip(g,[r_bot1,r_top1],[r_bot2,r_top2],SKIN_L)
    draw_line(g,*r_bot1,*r_top1,SKIN_D); draw_line(g,*r_bot2,*r_top2,SKIN_D)
    fill_spine_strip(g,[l_bot1,l_top1],[l_bot2,l_top2],SKIN_L)
    draw_line(g,*l_bot1,*l_top1,SKIN_D); draw_line(g,*l_bot2,*l_top2,SKIN_D)
    draw_line(g,r_bot1[0]-8,r_bot1[1],r_bot2[0]+8,r_bot2[1],BLACK)
    draw_line(g,l_bot2[0]-8,l_bot2[1],l_bot1[0]+8,l_bot1[1],BLACK)
    c,s=math.cos(rot_angle),math.sin(rot_angle); hnx=s; hny=-c
    for i in range(-5,7):
        for j in range(-3,5):
            px=grip[0]+int(hnx*i+s*3); py=grip[1]+int(hny*i+j)
            if abs(i)<=3 and abs(j)<=1: continue
            pset(g,px,py,SKIN_D)
    for i in range(-4,5):
        for j in range(-2,3):
            px=grip[0]+int(hnx*i-s*6); py=grip[1]+int(hny*i+5+j)
            pset(g,px,py,SKIN_D)
    for k in range(4):
        fi=-2+k; fx=grip[0]+int(hnx*fi+s*4); fy=grip[1]+int(hny*fi)+1
        pset(g,fx,fy,BLACK); pset(g,fx+1,fy-1,BLACK)

WEP_W,WEP_H=150,190; ARM_W,ARM_H=130,85
WEP_CX,WEP_CY=75,100; ARM_CX,ARM_CY=65,40

WEP_POSES={
    "katana_idle":(-0.30,),"katana_windup_1":(-0.08,),"katana_windup_2":(0.10,),
    "katana_swing_1":(0.45,),"katana_swing_2":(0.80,),"katana_swing_3":(1.05,),
    "katana_block":(-0.85,),
}
ARM_POSES={
    "arms_idle":(-0.30,),"arms_attack_1":(0.10,),"arms_attack_2":(0.45,),
    "arms_attack_3":(0.80,),"arms_block":(-0.85,),
}

def write_sprite_c(g, label, w, h):
    lines=[f"static const unsigned char spr_{label}_px[{w}*{h}] = {{"]
    flat=[]
    for row in g: flat.extend(row)
    for i in range(0,len(flat),64):
        lines.append("    "+",".join(str(c) for c in flat[i:i+64])+",")
    lines.append("};")
    return "\n".join(lines)

def main():
    out=os.path.join(SRC_DIR,"sprites.h")
    with open(out,"w") as f:
        f.write("// Auto-generated katana and arm sprites\n")
        f.write("#ifndef SPRITES_H\n#define SPRITES_H\n\n")
        for name,(angle,) in WEP_POSES.items():
            g=make_grid(WEP_W,WEP_H); draw_katana(g,rot_angle=angle,cx=WEP_CX,cy=WEP_CY)
            f.write(f"// Katana: {name} ({WEP_W}x{WEP_H})\n")
            f.write(f"static const unsigned short spr_{name}_w = {WEP_W};\n")
            f.write(f"static const unsigned short spr_{name}_h = {WEP_H};\n")
            f.write(write_sprite_c(g,name,WEP_W,WEP_H)+"\n\n")
            print(f"  spr_{name} ({WEP_W}x{WEP_H})")
        for name,(angle,) in ARM_POSES.items():
            g=make_grid(ARM_W,ARM_H); draw_arms(g,rot_angle=angle,cx=ARM_CX,cy=ARM_CY)
            f.write(f"// Arms: {name} ({ARM_W}x{ARM_H})\n")
            f.write(f"static const unsigned short spr_{name}_w = {ARM_W};\n")
            f.write(f"static const unsigned short spr_{name}_h = {ARM_H};\n")
            f.write(write_sprite_c(g,name,ARM_W,ARM_H)+"\n\n")
            print(f"  spr_{name} ({ARM_W}x{ARM_H})")
        weapon_order=["katana_idle","katana_windup_1","katana_windup_2","katana_swing_1","katana_swing_2","katana_swing_3","katana_block"]
        arm_order=["arms_idle","arms_attack_1","arms_attack_2","arms_attack_2","arms_attack_3","arms_attack_3","arms_block"]
        f.write("typedef struct { unsigned short w,h; const unsigned char* px; } sprite_info_t;\n")
        f.write("static const sprite_info_t weapon_sprites[7] = {\n")
        for name in weapon_order:
            f.write(f"    {{{WEP_W},{WEP_H},spr_{name}_px}},\n")
        f.write("};\n")
        f.write("static const sprite_info_t arm_sprites[7] = {\n")
        for name in arm_order:
            f.write(f"    {{{ARM_W},{ARM_H},spr_{name}_px}},\n")
        f.write("};\n")
        f.write("#endif // SPRITES_H\n")
    print(f"\nGenerated {out}")

if __name__=="__main__": main()
