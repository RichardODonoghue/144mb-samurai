// floor.c — textured floor raycasting
#include "build.h"
#include "sin_table.h"
#include "shade_data.h"

extern unsigned char *g_bits;
extern float player_x, player_y;
extern unsigned char player_angle;
extern unsigned char world_map[1024];
extern unsigned short wall_bottom[SCR_W];
extern const unsigned char floortex_map[7];
extern const unsigned char *const floor_tex_table[3];

void render_floor(void) {
    unsigned char *bits = g_bits;
    if (!bits) return;

    int angle = player_angle;
    float px = player_x, py = player_y;

    int left_idx = (unsigned char)(angle - FOV_HALF);
    int right_idx = (unsigned char)(angle + FOV_HALF);
    float cosL = cos_table[left_idx], sinL = sin_table[left_idx];
    float cosR = cos_table[right_idx], sinR = sin_table[right_idx];

    float colStepX = (cosR - cosL) / SCR_W;
    float colStepY = (sinR - sinL) / SCR_W;

    // Select floor texture based on player cell
    int cellX = (int)px, cellY = (int)py;
    int cell_val = 0;
    if (cellX >= 0 && cellX < MAP_W && cellY >= 0 && cellY < MAP_H)
        cell_val = world_map[cellY * MAP_W + cellX];
    int tex_idx = floortex_map[cell_val & 7];
    const unsigned char *floor_tex = floor_tex_table[tex_idx];

    // Floor palette base
    int pal_base = PAL_FLOOR_BASE;  // 96 = dirt
    if (tex_idx == 1) pal_base = PAL_FLOOR_WOOD;       // 128
    else if (tex_idx == 2) pal_base = PAL_FLOOR_BASE + 16; // 112

    for (int row = 0; row < SCR_H / 2; row++) {
        float rowDist = 100.0f / (row + 1);
        float rowStepX = colStepX * rowDist, rowStepY = colStepY * rowDist;
        float floorX = px + rowDist * cosL, floorY = py + rowDist * sinL;

        int shade = (int)rowDist >> 2;
        if (shade > 7) shade = 7;

        int screenY = row + SCR_H / 2;

        for (int col = 0; col < SCR_W; col++) {
            if (screenY <= wall_bottom[col]) {
                floorX += rowStepX; floorY += rowStepY; continue;
            }

            int tx = ((int)(floorX * F_TEX_W)) & (F_TEX_W - 1);
            int ty = ((int)(floorY * F_TEX_H)) & (F_TEX_H - 1);
            int pixel = floor_tex[ty * F_TEX_W + tx];
            pixel -= shade;
            if (pixel < 0) pixel = 0;
            pixel += pal_base;

            bits[screenY * SCR_W + col] = (unsigned char)pixel;
            floorX += rowStepX; floorY += rowStepY;
        }
    }
}
