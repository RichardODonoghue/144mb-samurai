// weapon.c — katana + arms rendering using sprite system
#include "build.h"
#include "sprites.h"

extern unsigned char *g_bits;
extern unsigned char attack_state, attack_timer, block_state;
extern float blade_swing_x, blade_y_mod;
extern const sprite_info_t weapon_sprites[7], arm_sprites[7];
void draw_sprite(unsigned short w, unsigned short h, const unsigned char *px, int dx, int dy);

void draw_weapon(void) {
    if (!g_bits) return;

    int frame = 0;
    if (attack_state) {
        if (attack_state == 1) frame = (attack_timer >= 2) ? 2 : 1;
        else if (attack_state == 2) {
            if (attack_timer < 2) frame = 3;
            else if (attack_timer < 4) frame = 4;
            else frame = 5;
        } else if (attack_state == 3) {
            if (attack_timer < 2) frame = 5;
            else if (attack_timer < 4) frame = 4;
            else frame = 0;
        }
    } else if (block_state) {
        frame = 6;
    }

    const sprite_info_t *ws = &weapon_sprites[frame];
    int dx = WEP_BASE_X + (int)blade_swing_x;
    int dy = WEP_BASE_Y + (int)blade_y_mod;
    draw_sprite(ws->w, ws->h, ws->px, dx, dy);

    const sprite_info_t *as = &arm_sprites[frame];
    int adx = ARM_BASE_X + (int)blade_swing_x;
    int ady = ARM_BASE_Y + (int)blade_y_mod;
    draw_sprite(as->w, as->h, as->px, adx, ady);
}
