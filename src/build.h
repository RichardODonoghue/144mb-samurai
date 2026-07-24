// build.h — all constants for 144mb-samurai
#ifndef BUILD_H
#define BUILD_H

#define SCR_W           320
#define SCR_H           200
#define MAP_W           32
#define MAP_H           32
#define FOV_HALF        33
#define MAX_DEPTH       64

// Palette layout
#define PAL_SKY_START       0
#define PAL_SKY_COUNT       64
#define PAL_BUILDING_BASE   64
#define PAL_BUILDING_COUNT  32
#define PAL_FLOOR_BASE      96
#define PAL_FLOOR_WOOD      128
#define PAL_WPN_BASE        176
#define PAL_WPN_GREEN       176
#define PAL_WPN_TSUBA       177
#define PAL_WPN_BLADE       178
#define PAL_WPN_SHINE       179
#define PAL_WPN_WRAP        180
#define PAL_WPN_SKIN_L      181
#define PAL_WPN_SKIN_D      182
#define PAL_WPN_BLACK       183
#define PAL_FX_BASE         184
#define PAL_FIRE_ANIM       184
#define PAL_PARTICLE        188
#define PAL_FOG_START       192
#define PAL_FOG_COUNT       32
#define PAL_VIGNETTE        224

// Roof/foundation
#define PAL_ROOF_TILE_1     248
#define PAL_ROOF_TILE_2     249
#define PAL_ROOF_RIDGE      250
#define PAL_ROOF_EAVE       251
#define PAL_FOUNDATION      252
#define PAL_EAVE_CURL       253
#define PAL_HUD_GREEN       176
#define PAL_HUD_RED         190
#define PAL_HUD_WHITE       191
#define PAL_HUD_BRUISE      250
#define PAL_HUD_PANEL       254
#define PAL_HUD_BORDER      255

// Texture dimensions
#define TEX_W   64
#define TEX_H   64
#define F_TEX_W 32
#define F_TEX_H 32
#define MAX_DIST_BUCKET 63
#define SHADE_BANDS     4
#define FOG_BEGIN       32

// Roof system
#define MAX_ROOF_H       18
#define ROOF_DIST_LIMIT  24
#define FOUNDATION_ROWS  5
#define ANIM_FIRE_INTERVAL 8

// Particles
#define MAX_PARTICLES 32

// HUD
#define HUD_Y_START 163
#define HUD_Y_END   199
#define HUD_FACE_W  24
#define HUD_FACE_H  20
#define HUD_HEART_W 20
#define HUD_HEART_H 18
#define HUD_FONT_W  3
#define HUD_FONT_H  5
#define MAX_HEALTH  100
#define DAMAGE_FLASH_FRAMES 8

// Weapon
#define WEP_BASE_X 105
#define WEP_BASE_Y 25
#define ARM_BASE_X 120
#define ARM_BASE_Y 98

// Combat
#define ATTACK_WINDUP   4
#define ATTACK_SWING    6
#define ATTACK_RECOVER  6
#define BLOCK_RAISE_FRAMES 3
#define BLOCK_Y_OFFSET  28
#define BLOCK_X_OFFSET  30

// Win32 constants
#define IDC_ARROW           0x7F00
#define CS_HREDRAW          2
#define CS_VREDRAW          1
#define WS_OVERLAPPEDWINDOW 0x00CF0000
#define CW_USEDEFAULT       0x80000000
#define SW_SHOW             5
#define WM_DESTROY          2
#define WM_CLOSE            0x10
#define WM_PAINT            0x0F
#define WM_KEYDOWN          0x100
#define WM_KEYUP            0x101
#define WM_SYSKEYDOWN       0x104
#define WM_SYSKEYUP         0x105
#define COLOR_WINDOW        5
#define SRCCOPY             0x00CC0020
#define DIB_RGB_COLORS      0
#define BI_RGB              0
#define PM_REMOVE           1

#define WIN_W 960
#define WIN_H 600

#endif // BUILD_H
