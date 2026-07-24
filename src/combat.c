// combat.c — attack/block state machines
#include "build.h"
#include "win32_imports.h"

extern unsigned char attack_state, attack_timer, block_state, block_timer;
extern unsigned char prev_lmb, prev_rmb;
extern float blade_swing_x, blade_y_mod;

void update_combat(void) {
    // Mouse button states (GetAsyncKeyState for mouse buttons)
    short lmb = GetAsyncKeyState(1);
    short rmb = GetAsyncKeyState(2);
    unsigned char lmb_now = (lmb & 0x8000) ? 1 : 0;
    unsigned char rmb_now = (rmb & 0x8000) ? 1 : 0;

    // Attack state machine
    if (attack_state) {
        switch (attack_state) {
        case 1: // WINDUP
            blade_swing_x = (float)(attack_timer * 15);
            blade_y_mod = 0.0f;
            attack_timer++;
            if (attack_timer >= ATTACK_WINDUP) { attack_state = 2; attack_timer = 0; }
            goto combat_done;
        case 2: // SWING
            blade_swing_x = (float)(60 - attack_timer * 20);
            blade_y_mod = 0.0f;
            attack_timer++;
            if (attack_timer >= ATTACK_SWING) { attack_state = 3; attack_timer = 0; }
            goto combat_done;
        case 3: // RECOVER
            blade_swing_x = (float)(-60 + attack_timer * 10);
            blade_y_mod = 0.0f;
            attack_timer++;
            if (attack_timer >= ATTACK_RECOVER) {
                attack_state = 0; attack_timer = 0;
                blade_swing_x = 0.0f; blade_y_mod = 0.0f;
            }
            goto combat_done;
        }
    }

    // Block state machine
    if (block_state) {
        switch (block_state) {
        case 1: // RAISING
            blade_y_mod = (float)(block_timer * 10);
            blade_swing_x = (float)(block_timer * 10);
            block_timer++;
            if (block_timer >= BLOCK_RAISE_FRAMES) {
                block_state = 2; block_timer = 0;
                blade_y_mod = (float)BLOCK_Y_OFFSET;
                blade_swing_x = (float)BLOCK_X_OFFSET;
            }
            goto combat_done;
        case 2: // HOLDING
            blade_y_mod = (float)BLOCK_Y_OFFSET;
            blade_swing_x = (float)BLOCK_X_OFFSET;
            goto combat_done;
        case 3: // RELEASING
            blade_y_mod = (float)(BLOCK_Y_OFFSET - block_timer * 8);
            if (blade_y_mod < 0) blade_y_mod = 0;
            blade_swing_x = (float)(BLOCK_X_OFFSET - block_timer * 8);
            if (blade_swing_x < 0) blade_swing_x = 0;
            block_timer++;
            if (block_timer >= 4) {
                block_state = 0; block_timer = 0;
                blade_y_mod = 0.0f; blade_swing_x = 0.0f;
            }
            goto combat_done;
        }
    }

    // Check for new attacks/blocks
    if (lmb_now && !prev_lmb) {
        attack_state = 1; attack_timer = 0;
    } else if (rmb_now && !prev_rmb) {
        block_state = 1; block_timer = 0;
    }

combat_done:
    prev_lmb = lmb_now; prev_rmb = rmb_now;
}
