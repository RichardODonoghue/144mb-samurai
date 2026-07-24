// hud.c — Doom-style status bar with face, hearts, health text
#include "build.h"
#include "faces.h"
#include "tex_gen.h"
#include "sin_table.h"

extern unsigned char *g_bits;
extern unsigned char player_health;
extern unsigned char damage_flash_timer;
extern int damage_cooldown;
extern int frame_counter;
extern const unsigned char font_data[14][15];
extern const unsigned char tex_hud_panel[32*32];

// Forward declare draw_sprite for face/heart
void draw_sprite(unsigned short w, unsigned short h, const unsigned char *px, int dx, int dy);

void update_hud(void) {
    if (damage_flash_timer > 0) damage_flash_timer--;
    if (damage_cooldown > 0) damage_cooldown--;
}

void draw_hud(void) {
    unsigned char *bits = g_bits;
    if (!bits) return;

    // Panel background (tile tex_hud_panel)
    for (int y = HUD_Y_START; y <= HUD_Y_END; y++) {
        for (int x = 0; x < SCR_W; x++) {
            int tx = x & 31, ty = y & 31;
            unsigned char c = tex_hud_panel[ty * 32 + tx];
            bits[y * SCR_W + x] = c;
        }
    }

    // Damage flash effect: pulsing red overlay
    if (damage_flash_timer > 0) {
        int intensity = (damage_flash_timer * 255) / DAMAGE_FLASH_FRAMES;
        for (int y = HUD_Y_START; y <= HUD_Y_END; y++) {
            for (int x = 0; x < SCR_W; x++) {
                unsigned char c = bits[y * SCR_W + x];
                if (c >= 254) continue; // skip panel/border colors
                // Blend toward red - simplified as brightness reduction
                if ((x + y + frame_counter) & 1) {
                    bits[y * SCR_W + x] = PAL_HUD_RED;
                }
            }
        }
    }

    // Health bar background
    for (int y = 0; y < 3; y++) {
        for (int x = 50; x < 50 + 96; x++) {
            bits[(164 + y) * SCR_W + x] = PAL_HUD_RED;
        }
    }

    // Health bar fill (green)
    int fill_w = (player_health * 96) / MAX_HEALTH;
    for (int y = 0; y < 3; y++) {
        for (int x = 50; x < 50 + fill_w; x++) {
            bits[(164 + y) * SCR_W + x] = PAL_HUD_GREEN;
        }
    }

    // Heart
    int heart_idx = 4 - (player_health * 5) / MAX_HEALTH;
    if (heart_idx < 0) heart_idx = 0;
    if (heart_idx > 4) heart_idx = 4;
    const unsigned char *heart = (const unsigned char*)heart_table[heart_idx];
    draw_sprite(HUD_HEART_W, HUD_HEART_H, heart, 6, 164);

    // Face
    int face_idx = 4 - (player_health * 5) / MAX_HEALTH;
    if (face_idx < 0) face_idx = 0;
    if (face_idx > 4) face_idx = 4;
    const unsigned char *face = (const unsigned char*)face_table[face_idx];
    draw_sprite(HUD_FACE_W, HUD_FACE_H, face, 32, 164);

    // Health text (e.g., "100HP")
    char text[16] = {0};
    int hp = player_health;
    int len = 0;
    if (hp >= 100) { text[len++] = 1; text[len++] = 0; text[len++] = 0; } // '100'
    else if (hp >= 10) { text[len++] = hp / 10; text[len++] = hp % 10; }
    else { text[len++] = hp; }
    text[len++] = 10; // 'H'
    text[len++] = 11; // 'P'

    for (int i = 0; i < len; i++) {
        int glyph = text[i];
        if (glyph >= 14) glyph = 13; // '/'
        for (int fy = 0; fy < 5; fy++) {
            for (int fx = 0; fx < 3; fx++) {
                unsigned char c = font_data[glyph][fy * 3 + fx];
                if (c != 254) {
                    int sx = 6 + i * 4 + fx;
                    int sy = 184 + fy;
                    if (sx < SCR_W && sy < SCR_H)
                        bits[sy * SCR_W + sx] = c;
                }
            }
        }
    }
}
