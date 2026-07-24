// input.c — keyboard/mouse input, movement, collision
#include "build.h"
#include "win32_imports.h"
#include "sin_table.h"

extern unsigned char key_states[256];
extern float player_x, player_y, player_angle_f;
extern unsigned char player_angle;
extern unsigned char world_map[1024];
extern int prev_mouse_x, prev_mouse_y, mouse_init;
extern float mouse_sens;
extern unsigned char prev_escape;

static float fabsf_local(float x) {
    union { float f; unsigned int u; } u = { x };
    u.u &= 0x7FFFFFFF;
    return u.f;
}

void process_input(void) {
    // Escape toggle
    if (GetAsyncKeyState(0x1B) & 0x8000) {
        if (!prev_escape) { }
        prev_escape = 1;
    } else {
        prev_escape = 0;
    }

    // WASD movement — aligned with raycasting: angle 0 = east (right on map)
    // 256-circle: 0=right, 64=down, 128=left, 192=up
    float moveX = 0.0f, moveY = 0.0f;
    {
        short w = GetAsyncKeyState('W');
        short s = GetAsyncKeyState('S');
        short a = GetAsyncKeyState('A');
        short d = GetAsyncKeyState('D');
        int wf = (w & 0x8000) ? 1 : 0;
        int sf = (s & 0x8000) ? 1 : 0;
        int af = (a & 0x8000) ? 1 : 0;
        int df = (d & 0x8000) ? 1 : 0;

        int ang = player_angle;
        if (wf) { moveX += cos_table[ang]; moveY += sin_table[ang]; }
        if (sf) { moveX -= cos_table[ang]; moveY -= sin_table[ang]; }
        if (af) { moveX += cos_table[(ang + 192) & 255]; moveY += sin_table[(ang + 192) & 255]; }
        if (df) { moveX += cos_table[(ang + 64) & 255];  moveY += sin_table[(ang + 64) & 255]; }
    }

    // Scale by move speed (no normalization needed — each key adds one unit)
    if (moveX != 0.0f || moveY != 0.0f) {
        moveX *= 0.04f;
        moveY *= 0.04f;
    }

    // Sliding collision: try X then Y independently
    float newX = player_x + moveX;
    float newY = player_y + moveY;

    // Save old position for collision checks
    float oldX = player_x;
    float oldY = player_y;

    // Check X movement
    if (newX >= 0 && newX < MAP_W) {
        int checkY = (int)oldY;
        if (checkY >= 0 && checkY < MAP_H) {
            if (!world_map[checkY * MAP_W + (int)newX]) {
                player_x = newX;
            }
        }
    }

    // Check Y movement (using possibly updated X for wall sliding)
    if (newY >= 0 && newY < MAP_H) {
        int checkX = (int)player_x;
        if (checkX >= 0 && checkX < MAP_W) {
            if (!world_map[(int)newY * MAP_W + checkX]) {
                player_y = newY;
            }
        }
    }

    // Mouse look
    POINT cursor;
    GetCursorPos(&cursor);
    if (!mouse_init) {
        prev_mouse_x = cursor.x;
        prev_mouse_y = cursor.y;
        mouse_init = 1;
    }
    int dx = cursor.x - prev_mouse_x;
    if (dx != 0) {
        player_angle_f += dx * mouse_sens;
        while (player_angle_f < 0.0f) player_angle_f += 256.0f;
        while (player_angle_f >= 256.0f) player_angle_f -= 256.0f;
        player_angle = (unsigned char)(int)player_angle_f;
        SetCursorPos(prev_mouse_x, prev_mouse_y);
    }
}
