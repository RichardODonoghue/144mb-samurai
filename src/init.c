// init.c — palette, DIB, vignette initialization
#include "build.h"
#include "win32_imports.h"
#include "palette_data.h"
#include "shade_data.h"

// Extern globals from main.c
extern HBITMAP g_dib;
extern unsigned char *g_bits;
extern BITMAPINFO g_bmi;
extern HWND g_hwnd;
extern unsigned char vignette_mask[64000];
extern const unsigned char vignette_rle[];
extern const int vignette_rle_count;
extern const int vignette_full_len;

void init_palette(void) {
    DWORD *pal = g_bmi.bmiColors;

    // Sky (0-63): dark purple -> bright purple
    for (int i = 0; i < 64; i++) {
        int v = i * 4 + 4;
        if (v > 255) v = 255;
        pal[i] = v | (v << 16);
    }

    // Building palette (64-95): 32 entries
    for (int i = 0; i < 32; i++) pal[64 + i] = pal_building[i];

    // Floor dirt (96-111): 16 entries
    for (int i = 0; i < 8; i++) { pal[96 + i] = pal_floor_dirt_x[i]; pal[104 + i] = pal_floor_dirt_y[i]; }
    // Floor stone (112-127): 16 entries
    for (int i = 0; i < 8; i++) { pal[112 + i] = pal_floor_stone_x[i]; pal[120 + i] = pal_floor_stone_y[i]; }
    // Floor wood (128-143): 16 entries
    for (int i = 0; i < 8; i++) { pal[128 + i] = pal_floor_wood_x[i]; pal[136 + i] = pal_floor_wood_y[i]; }

    // Pad 144-175 (unused)
    for (int i = 144; i < 176; i++) pal[i] = 0;

    // Weapon/skin (176-183): 8 entries
    for (int i = 0; i < 8; i++) pal[176 + i] = pal_weapon[i];
    pal[PAL_HUD_GREEN] = 0x0000CC00;  // HUD green override

    // Fire animation (184-187): 4 entries
    for (int i = 0; i < 4; i++) pal[184 + i] = fire_cycle0[i];

    // Particles (188-191)
    pal[188] = 0x00FFB450;  // bright ember
    pal[189] = 0x0064280A;  // dark ember
    pal[190] = 0x00CC0000;  // HUD red
    pal[191] = 0x00FFFFFF;  // HUD white

    // Fog (192-223): 32 entries
    for (int i = 0; i < 32; i++) pal[192 + i] = pal_fog[i];

    // Vignette (224-247): 24 entries, procedural purple-black gradient
    for (int i = 0; i < 24; i++) {
        int r = (120 - i) * 120 >> 7;
        int g = r >> 1;
        pal[224 + i] = r | (g << 8) | (r << 16);
    }

    // Roof/foundation/HUD (248-255): 8 hardcoded entries
    pal[248] = 0x0040302A;
    pal[249] = 0x0050403A;
    pal[250] = 0x0040204A;
    pal[251] = 0x00181410;
    pal[252] = 0x00484040;
    pal[253] = 0x0050604A;
    pal[254] = 0x00303038;
    pal[255] = 0x00606068;
}

int init_dib(void) {
    BITMAPINFO *bmi = &g_bmi;
    bmi->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi->bmiHeader.biWidth = SCR_W;
    bmi->bmiHeader.biHeight = -SCR_H;  // top-down
    bmi->bmiHeader.biPlanes = 1;
    bmi->bmiHeader.biBitCount = 8;
    bmi->bmiHeader.biCompression = BI_RGB;
    bmi->bmiHeader.biClrUsed = 256;

    HDC hdc = GetDC(g_hwnd);
    if (!hdc) return 0;
    g_dib = CreateDIBSection(hdc, bmi, DIB_RGB_COLORS, (void**)&g_bits, 0, 0);
    ReleaseDC(g_hwnd, hdc);
    return g_dib != 0;
}

// Decompress vignette RLE into vignette_mask[64000]
unsigned char vignette_mask[64000];

void init_vignette(void) {
    unsigned char *dst = vignette_mask;
    const unsigned char *src = vignette_rle;
    int remaining = vignette_rle_count;
    while (remaining > 0) {
        unsigned char count = *src++;
        unsigned char value = *src++;
        remaining -= 2;
        for (int i = 0; i < count && dst - vignette_mask < 64000; i++)
            *dst++ = value;
    }
}
