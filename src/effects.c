// effects.c — particles, fire palette animation
#include "build.h"

extern unsigned char *g_bits;
extern int frame_counter;
extern float player_x, player_y;
extern unsigned char world_map[1024];
extern int fire_anim_frame;

typedef struct { float x,y,z,vx,vy; int life; int pad[3]; } particle_t;
extern particle_t particles[MAX_PARTICLES];

void animate_fire(void) {
    frame_counter++;
    fire_anim_frame = (frame_counter / ANIM_FIRE_INTERVAL) & 3;
}

void update_particles(void) {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        particle_t *p = &particles[i];
        if (p->life <= 0) continue;
        p->x += p->vx; p->y += p->vy;
        p->z += 0.02f;
        p->life--;
    }
}

void spawn_particle(float x, float y, float vx, float vy) {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (particles[i].life <= 0) {
            particles[i].x = x; particles[i].y = y; particles[i].z = 1.0f;
            particles[i].vx = vx; particles[i].vy = vy;
            particles[i].life = 30;
            return;
        }
    }
}

void draw_particles(void) {
    unsigned char *bits = g_bits;
    if (!bits) return;

    for (int i = 0; i < MAX_PARTICLES; i++) {
        particle_t *p = &particles[i];
        if (p->life <= 0) continue;

        // Simple projection: screen_x = (px - player_x) * scale + SCR_W/2
        // For simplicity, just draw as small dots near fire sources
        int sx = (int)((p->x - player_x) * 20.0f + SCR_W / 2);
        int sy = (int)((p->y + p->z) * 15.0f + 80);
        if (sx >= 0 && sx < SCR_W && sy >= 0 && sy < SCR_H) {
            unsigned char c = 188 + (p->life & 1);  // ember orange / dark red
            if (p->z > 2.0f) c = 189;  // darker further away
            bits[sy * SCR_W + sx] = c;
        }
    }

    // Scan map for fire cells near player and spawn particles occasionally
    int px = (int)player_x, py = (int)player_y;
    for (int dy = -3; dy <= 3; dy++) {
        for (int dx = -3; dx <= 3; dx++) {
            int cx = px + dx, cy = py + dy;
            if (cx < 0 || cx >= MAP_W || cy < 0 || cy >= MAP_H) continue;
            if (world_map[cy * MAP_W + cx] == 6) { // fire building = type 6 (residence in new map, but we use it for fire effect)
                if ((frame_counter & 7) == 0)
                    spawn_particle(cx + 0.5f, cy + 0.5f, ((dx & 1) ? 0.01f : -0.01f), -0.02f);
            }
        }
    }
}
