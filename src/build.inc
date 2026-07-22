BITS 64
DEFAULT REL

; ============================================================
; CONSTANTS
; ============================================================

SCR_W           equ 320
SCR_H           equ 200
MAP_W           equ 16
MAP_H           equ 16
FOV_HALF        equ 33
MAX_DEPTH       equ 32

; Palette layout
PAL_SKY_START       equ 0
PAL_SKY_COUNT       equ 64
PAL_FLOOR_DIRT      equ 64
PAL_WALL_BASE       equ 80
PAL_WALL_STRIDE     equ 16      ; 16 entries per wall type (8 light + 8 dark)
PAL_WALL_X_MASK     equ 7       ; texel value range 0-7
PAL_FLOOR_WOOD      equ 160
PAL_WEAPON_BASE     equ 176
PAL_WEAPON_GREEN    equ 176
PAL_WEAPON_TSUBA    equ 177
PAL_WEAPON_BLADE    equ 178
PAL_WEAPON_SHINE    equ 179
PAL_WEAPON_WRAP     equ 180
PAL_WEAPON_SKIN_L   equ 181
PAL_WEAPON_SKIN_D   equ 182
PAL_WEAPON_BLACK    equ 183
PAL_FX_BASE         equ 184
PAL_FIRE_ANIM       equ 184  ; 4 fire anim entries
PAL_PARTICLE        equ 188  ; particle color range
PAL_FOG_START       equ 192
PAL_FOG_COUNT       equ 32
PAL_VIGNETTE        equ 224

; Roof and foundation palette (steal 8 entries from vignette ramp)
PAL_ROOF_TILE_1     equ 248
PAL_ROOF_TILE_2     equ 249
PAL_ROOF_RIDGE      equ 250
PAL_ROOF_EAVE       equ 251
PAL_FOUNDATION      equ 252
PAL_EAVE_CURL       equ 253

; Roof system
MAX_ROOF_H          equ 16
ROOF_DIST_LIMIT     equ 24      ; no roof beyond this distance bucket
FOUNDATION_ROWS     equ 3       ; rows of foundation band at wall bottom

; Wall type mapping: cell_value -> wall_type for palette (1..N)
; texture type_index = tex_type_map[cell_value - 1]
; palette base = PAL_WALL_BASE + (cell_value - 1) * PAL_WALL_STRIDE

; Texture dimensions
TEX_W           equ 32
TEX_H           equ 32
TEX_SIZE        equ 1024    ; 32 * 32 bytes
TEX_TEXEL_MASK  equ 7       ; 4-bit texels 0-7
TEX_SIDE_SHIFT  equ 8       ; +8 for Y-side dark sub-palette

; Shading
MAX_DIST_BUCKET equ 63

; Fog
FOG_BEGIN       equ 32      ; distance bucket where fog starts

; Animation
ANIM_FIRE_INTERVAL equ 8    ; frames between fire palette cycles

; Particle
MAX_PARTICLES   equ 32
PARTICLE_SIZE   equ 24

; ---- HUD ----
HUD_Y_START     equ 163
HUD_Y_END       equ 199
HUD_BAR_X       equ 50
HUD_BAR_Y       equ 164
HUD_BAR_W       equ 96
HUD_BAR_H       equ 3
HUD_FACE_X      equ 32
HUD_FACE_Y      equ 164
HUD_FACE_W      equ 24
HUD_FACE_H      equ 20
HUD_TEXT_X      equ 6
HUD_TEXT_Y      equ 184
HUD_HEART_X     equ 6
HUD_HEART_Y     equ 164
HUD_HEART_W     equ 20
HUD_HEART_H     equ 18
HUD_FONT_W      equ 3
HUD_FONT_H      equ 5

MAX_HEALTH      equ 100
DAMAGE_FLASH_FRAMES equ 8

; ---- Combat ----
ATTACK_WINDUP        equ 4      ; frames pulling blade back
ATTACK_SWING         equ 6      ; frames sweeping across
ATTACK_RECOVER       equ 6      ; frames returning to rest
ATTACK_TOTAL         equ 16     ; windup + swing + recover
SWING_X_RANGE        equ 100    ; max X offset during swing arc
BLOCK_RAISE_FRAMES   equ 3      ; frames to raise into block
BLOCK_Y_OFFSET       equ 28     ; rows up from resting position
BLOCK_X_OFFSET       equ 30     ; horizontal shift for blocking

; HUD palette (repurposed unused entries)
PAL_HUD_GREEN   equ 176
PAL_HUD_RED     equ 190
PAL_HUD_WHITE   equ 191
PAL_HUD_BRUISE  equ 250
PAL_HUD_PANEL   equ 254
PAL_HUD_BORDER  equ 255

; Win32 constants
IDC_ARROW           equ 7F00h
CS_HREDRAW          equ 2
CS_VREDRAW          equ 1
WS_OVERLAPPEDWINDOW equ 00CF0000h
CW_USEDEFAULT       equ 80000000h
SW_SHOW             equ 5
WM_DESTROY          equ 2
WM_CLOSE            equ 10h
WM_PAINT            equ 0Fh
WM_SIZE             equ 5
WM_KEYDOWN          equ 100h
WM_KEYUP            equ 101h
WM_SYSKEYDOWN       equ 104h
WM_SYSKEYUP         equ 105h
COLOR_WINDOW        equ 5

; Virtual keys
VK_W        equ 57h
VK_A        equ 41h
VK_S        equ 53h
VK_D        equ 44h
VK_SPACE    equ 20h
VK_ESCAPE   equ 1Bh
VK_LBUTTON  equ 01h
VK_RBUTTON  equ 02h
VK_SHIFT    equ 10h
VK_BACK     equ 08h

; BITMAPINFOHEADER offsets
BISIZE           equ 0
BIWIDTH          equ 4
BIHEIGHT         equ 8
BIPLANES         equ 12
BIBITCOUNT       equ 14
BICOMPRESSION    equ 16
BISIZEIMAGE      equ 20
BIXPELSPERMETER  equ 24
BIYPELSPERMETER  equ 28
BICLRUSED        equ 32
BICLRIMPORTANT   equ 36
BMIHEADER_SIZE   equ 40
BMICOLORS_OFFSET equ 40

; Window dimensions
WIN_W   equ 960
WIN_H   equ 600

; Stack frame for game loop
FRAME_SHADOW    equ 00h
FRAME_PM5       equ 20h
FRAME_MSG       equ 28h
FRAME_RECT      equ 58h
FRAME_CURSOR    equ 68h
FRAME_CENTER    equ 70h
FRAME_SIZE      equ 78h
