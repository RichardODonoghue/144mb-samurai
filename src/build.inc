BITS 64
DEFAULT REL

; ============================================================
; CONSTANTS
; ============================================================

SCR_W           equ 320
SCR_H           equ 200
MAP_W           equ 32
MAP_H           equ 32
FOV_HALF        equ 33
MAX_DEPTH       equ 64

; Palette layout
PAL_SKY_START       equ 0
PAL_SKY_COUNT       equ 64
PAL_BUILDING_BASE   equ 64      ; 64-95: 32 entries shared building palette
PAL_BUILDING_COUNT  equ 32
PAL_FLOOR_BASE      equ 96      ; 96-127: 32 entries floor palette
PAL_FLOOR_WOOD      equ 128     ; 128-143: wood floor (8 light + 8 dark)
PAL_WPN_BASE        equ 176
PAL_WPN_GREEN       equ 176
PAL_WPN_TSUBA       equ 177
PAL_WPN_BLADE       equ 178
PAL_WPN_SHINE       equ 179
PAL_WPN_WRAP        equ 180
PAL_WPN_SKIN_L      equ 181
PAL_WPN_SKIN_D      equ 182
PAL_WPN_BLACK       equ 183
PAL_FX_BASE         equ 184
PAL_FIRE_ANIM       equ 184
PAL_PARTICLE        equ 188
PAL_FOG_START       equ 192
PAL_FOG_COUNT       equ 32
PAL_VIGNETTE        equ 224

; Roof and foundation
PAL_ROOF_TILE_1     equ 248
PAL_ROOF_TILE_2     equ 249
PAL_ROOF_RIDGE      equ 250
PAL_ROOF_EAVE       equ 251
PAL_FOUNDATION      equ 252
PAL_EAVE_CURL       equ 253

; HUD
PAL_HUD_GREEN   equ 176
PAL_HUD_RED     equ 190
PAL_HUD_WHITE   equ 191
PAL_HUD_BRUISE  equ 250
PAL_HUD_PANEL   equ 254
PAL_HUD_BORDER  equ 255

; Building palette sub-ranges (within 64-95)
WHITE_0     equ 64     ; white plaster: bright, mid, warm, shadow
WHITE_1     equ 65
WHITE_2     equ 66
WHITE_3     equ 67
RED_0       equ 68     ; red lacquer: bright, mid, dark, deep
RED_1       equ 69
RED_2       equ 70
RED_3       equ 71
TIMBER_0    equ 72     ; dark timber: lightest, framing, post, black-brown
TIMBER_1    equ 73
TIMBER_2    equ 74
TIMBER_3    equ 75
TANWOOD_0   equ 76     ; natural tan wood: light, mid, dark, grain
TANWOOD_1   equ 77
TANWOOD_2   equ 78
TANWOOD_3   equ 79
WARMWOOD_0  equ 80     ; warm brown wood: light, mid, dark, deep
WARMWOOD_1  equ 81
WARMWOOD_2  equ 82
WARMWOOD_3  equ 83
ROOF_0      equ 84     ; grey roof tiles: light, mid, dark, shadow
ROOF_1      equ 85
ROOF_2      equ 86
ROOF_3      equ 87
STONE_0     equ 88     ; stone/foundation: light, mid, dark, mortar
STONE_1     equ 89
STONE_2     equ 90
STONE_3     equ 91
MURAL_0     equ 92     ; mural accents: blue-green, gold, deep red, moss
MURAL_1     equ 93
MURAL_2     equ 94
MURAL_3     equ 95

; Texture dimensions
TEX_W           equ 64
TEX_H           equ 64
TEX_SIZE        equ 4096        ; 64 * 64 bytes

; Shading (8-bit direct palette → shade LUT lookup)
MAX_DIST_BUCKET equ 63
SHADE_BANDS     equ 4           ; 4 distance bands, each 256-byte LUT
SHADE_LUT_SIZE  equ 1024        ; 4 * 256 bytes
FOG_BEGIN       equ 32

; Roof system
MAX_ROOF_H          equ 18
ROOF_DIST_LIMIT     equ 24
FOUNDATION_ROWS     equ 5

; Animation
ANIM_FIRE_INTERVAL equ 8

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

; ---- Weapon sprite system ----
SPRITE_TRANSPARENT  equ 0
WEP_BASE_X          equ 105
WEP_BASE_Y          equ 25
ARM_BASE_X          equ 120
ARM_BASE_Y          equ 98

; ---- Combat ----
ATTACK_WINDUP        equ 4
ATTACK_SWING         equ 6
ATTACK_RECOVER       equ 6
ATTACK_TOTAL         equ 16
BLOCK_RAISE_FRAMES   equ 3
BLOCK_Y_OFFSET       equ 28
BLOCK_X_OFFSET       equ 30

; Win32
IDC_ARROW           equ 7F00h
CS_HREDRAW          equ 2
CS_VREDRAW          equ 1
WS_OVERLAPPEDWINDOW equ 00CF0000h
CW_USEDEFAULT       equ 80000000h
SW_SHOW             equ 5
WM_DESTROY          equ 2
WM_CLOSE            equ 10h
WM_PAINT            equ 0Fh
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
VK_LBUTTON  equ 01h
VK_RBUTTON  equ 02h
VK_SHIFT    equ 10h
VK_BACK     equ 08h

; BITMAPINFOHEADER
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

; Window
WIN_W   equ 960
WIN_H   equ 600

; Stack frame
FRAME_SHADOW    equ 00h
FRAME_PM5       equ 20h
FRAME_MSG       equ 28h
FRAME_RECT      equ 58h
FRAME_CURSOR    equ 68h
FRAME_CENTER    equ 70h
FRAME_SIZE      equ 78h
