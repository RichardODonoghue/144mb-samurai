// level.c — level loading and transitions
#include "build.h"

extern unsigned char world_map[1024];
extern int current_level;
extern float player_x, player_y, player_start_x, player_start_y;
extern unsigned char player_angle, player_start_angle;
extern float player_angle_f;
extern float level_end_x, level_end_y;
extern unsigned char player_paused, player_health;
extern unsigned char damage_flash_timer;
extern int damage_cooldown;

extern const unsigned char level0_map[1024], level1_map[1024];
extern const float level0_start_x, level0_start_y, level1_start_x, level1_start_y;
extern const unsigned char level0_start_angle, level1_start_angle;
extern const float level0_end_x, level0_end_y, level1_end_x, level1_end_y;

void level_init(int index) {
    current_level = index;
    const unsigned char *src;
    float sx, sy, ex, ey;
    unsigned char sa;

    if (index == 1) {
        src = level1_map; sx = level1_start_x; sy = level1_start_y;
        sa = level1_start_angle; ex = level1_end_x; ey = level1_end_y;
    } else {
        src = level0_map; sx = level0_start_x; sy = level0_start_y;
        sa = level0_start_angle; ex = level0_end_x; ey = level0_end_y;
    }

    for (int i = 0; i < 1024; i++) world_map[i] = src[i];

    player_x = sx; player_y = sy;
    player_angle = sa; player_angle_f = 0.0f;
    level_end_x = ex; level_end_y = ey;
    player_paused = 0;
    player_health = MAX_HEALTH;
    damage_flash_timer = 0;
    damage_cooldown = 0;
}

void level_check_end(void) {
    float dx = player_x - level_end_x;
    float dy = player_y - level_end_y;
    float dist2 = dx * dx + dy * dy;
    if (dist2 < 2.25f) {  // 1.5^2
        level_init(current_level + 1);
    }
}
