// sprite.c — general-purpose sprite blitter
#include "build.h"

extern unsigned char *g_bits;

void draw_sprite(unsigned short w, unsigned short h, const unsigned char *px, int dx, int dy) {
    if (!g_bits || !px) return;
    for (int y = 0; y < h; y++) {
        int sy = dy + y;
        if (sy < 0 || sy >= SCR_H) { px += w; continue; }
        unsigned char *dst = g_bits + sy * SCR_W + dx;
        for (int x = 0; x < w; x++) {
            unsigned char p = *px++;
            if (p && x + dx >= 0 && x + dx < SCR_W) dst[x] = p;
        }
    }
}
