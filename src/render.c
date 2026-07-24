// render.c — DDA raycasting, wall/roof/foundation drawing, vignette
#include "build.h"
#include "shade_data.h"
#include "sin_table.h"
#include "tex_gen.h"

extern unsigned char *g_bits;
extern float player_x, player_y;
extern unsigned char player_angle, world_map[1024];
extern const unsigned char *const building_tex_table[6];
extern unsigned short wall_bottom[SCR_W];

extern void render_floor(void);
extern void draw_particles(void);
extern void draw_weapon(void);
extern void draw_hud(void);
void apply_vignette(void);

static float fabsf_local(float x) {
    union { float f; unsigned int u; } u = { x };
    u.u &= 0x7FFFFFFF;
    return u.f;
}

void render_frame(void) {
    unsigned char *bits = g_bits;
    if (!bits) return;

    // Gradient clear: sky
    for (int y = 0; y < SCR_H / 2; y++) {
        unsigned char c = sky_gradient[y];
        for (int x = 0; x < SCR_W; x++) bits[y * SCR_W + x] = c;
    }
    // Gradient clear: floor
    for (int y = SCR_H / 2; y < SCR_H; y++) {
        unsigned char c = floor_gradient[y - SCR_H / 2];
        for (int x = 0; x < SCR_W; x++) bits[y * SCR_W + x] = c;
    }

    int angle = player_angle;
    float px = player_x, py = player_y;

    // Ray directions
    int left_idx = (unsigned char)(angle - FOV_HALF);
    int right_idx = (unsigned char)(angle + FOV_HALF);
    float cosL = cos_table[left_idx], sinL = sin_table[left_idx];
    float cosR = cos_table[right_idx], sinR = sin_table[right_idx];

    float stepX = (cosR - cosL) / SCR_W;
    float stepY = (sinR - sinL) / SCR_W;

    float rayDirX = cosL, rayDirY = sinL;

    for (int col = 0; col < SCR_W; col++) {
        // --- DDA Setup ---
        int mapX = (int)px, mapY = (int)py;
        float deltaX = fabsf_local(1.0f / rayDirX);
        float deltaY = fabsf_local(1.0f / rayDirY);

        int stepDirX, stepDirY;
        float sideDistX, sideDistY;

        if (rayDirX < 0) { stepDirX = -1; sideDistX = (px - mapX) * deltaX; }
        else             { stepDirX =  1; sideDistX = (mapX + 1.0f - px) * deltaX; }
        if (rayDirY < 0) { stepDirY = -1; sideDistY = (py - mapY) * deltaY; }
        else             { stepDirY =  1; sideDistY = (mapY + 1.0f - py) * deltaY; }

        // --- DDA Loop ---
        int side = 0, hit = 0, wall_type = 0;
        for (int step = 0; step < MAX_DEPTH; step++) {
            if (sideDistX < sideDistY) {
                sideDistX += deltaX; mapX += stepDirX; side = 0;
            } else {
                sideDistY += deltaY; mapY += stepDirY; side = 1;
            }
            if (mapX < 0 || mapX >= MAP_W || mapY < 0 || mapY >= MAP_H) break;
            wall_type = world_map[mapY * MAP_W + mapX];
            if (wall_type) { hit = 1; break; }
        }

        if (!hit) { wall_bottom[col] = 0; rayDirX += stepX; rayDirY += stepY; continue; }

        // --- Perpendicular distance ---
        float perpWallDist;
        if (side == 0)
            perpWallDist = (mapX - px + (1 - stepDirX) * 0.5f) / rayDirX;
        else
            perpWallDist = (mapY - py + (1 - stepDirY) * 0.5f) / rayDirY;

        // Distance bucket
        int distBucket = (int)perpWallDist;
        if (distBucket < 0) distBucket = 0;
        if (distBucket > MAX_DIST_BUCKET) distBucket = MAX_DIST_BUCKET;

        // Line height
        int lineHeight = (int)(SCR_H / perpWallDist);
        int drawStart = -lineHeight / 2 + SCR_H / 2;
        if (drawStart < 0) drawStart = 0;
        int drawEnd = lineHeight / 2 + SCR_H / 2;
        if (drawEnd >= SCR_H) drawEnd = SCR_H - 1;
        wall_bottom[col] = (unsigned short)drawEnd;

        // Texture sampling
        float wallX_float;
        if (side == 0) wallX_float = py + perpWallDist * rayDirY;
        else           wallX_float = px + perpWallDist * rayDirX;
        wallX_float -= (int)wallX_float;
        int texX = (int)(wallX_float * TEX_W) & (TEX_W - 1);

        // Texture pointer
        const unsigned char *tex = building_tex_table[wall_type - 1];

        // Texture step (16.16 fixed point)
        int texStep = (TEX_H << 16) / lineHeight;
        int texPos = 0;
        int savedDrawStart = drawStart;

        for (int y = drawStart; y <= drawEnd; y++) {
            int texY = (texPos >> 16) & (TEX_H - 1);
            int idx = texY * TEX_W + texX;
            unsigned char pixel = tex[idx];

            // Fog
            if (distBucket >= FOG_BEGIN) {
                pixel = PAL_FOG_START + ((distBucket - FOG_BEGIN) >> 1);
            } else {
                // Shade LUT
                int band = distBucket >> 4;
                if (band > 3) band = 3;
                pixel = shade_lut[band][pixel];
            }

            bits[y * SCR_W + col] = pixel;
            texPos += texStep;
        }

        // --- Roof rendering ---
        if (distBucket <= ROOF_DIST_LIMIT) {
            int roofH = (roof_profile[texX & 31] * roof_type_height[wall_type - 1]) / MAX_ROOF_H;
            if (roofH > 0) {
                int roofStart = savedDrawStart - roofH;
                for (int y = roofStart; y < savedDrawStart; y++) {
                    if (y < 0) continue;
                    unsigned char pixel;
                    int rowFromTop = savedDrawStart - y;
                    if (rowFromTop < 2) {
                        pixel = PAL_ROOF_EAVE;
                    } else if ((texX & 63) < 8) {
                        pixel = PAL_EAVE_CURL;
                    } else if ((texX & 63) >= 56) {
                        pixel = PAL_EAVE_CURL;
                    } else {
                        int roof_tx = (texX & 63) & 31;
                        int roof_ty = rowFromTop & 31;
                        pixel = tex_roof[roof_ty][roof_tx];
                    }
                    bits[y * SCR_W + col] = pixel;
                }
            }
        }

        // --- Foundation rendering ---
        if (drawEnd >= SCR_H / 2) {
            int startY = drawEnd - FOUNDATION_ROWS + 1;
            if (startY < 0) startY = 0;
            for (int y = startY; y <= drawEnd; y++) {
                int fy = (drawEnd - y) & 7;
                int fx = (texX & 63) & 31;
                bits[y * SCR_W + col] = tex_foundation[fy][fx];
            }
        }

        rayDirX += stepX; rayDirY += stepY;
    }

    render_floor();
    draw_particles();
    draw_weapon();
    draw_hud();
    apply_vignette();
}

void apply_vignette(void) {
    extern unsigned char vignette_mask[64000];
    unsigned char *bits = g_bits;
    if (!bits) return;
    for (int i = 0; i < SCR_W * SCR_H; i++) {
        if (vignette_mask[i]) {
            bits[i] = vignette_lut[bits[i]];
        }
    }
}
