// main.c — entry point, window creation, game loop
#include "build.h"
#include "win32_imports.h"

// Game state globals
HINSTANCE g_hinst;
HWND g_hwnd;
HBITMAP g_dib;
unsigned char *g_bits;
BITMAPINFO g_bmi;
int g_running = 1;

// Forward declarations
void init_palette(void);
int init_dib(void);
void render_frame(void);
void render_floor(void);
void draw_particles(void);
void draw_weapon(void);
void draw_hud(void);
void apply_vignette(void);
void process_input(void);
void level_check_end(void);
void update_particles(void);
void animate_fire(void);
void update_hud(void);
void update_combat(void);
void level_init(int index);
LONG_PTR __stdcall wndproc(HWND hwnd, UINT msg, UINT_PTR wp, LONG_PTR lp);

// Imported data
extern const char class_name[];
extern const char window_title[];
extern float player_x, player_y;
extern unsigned char player_angle;
extern float player_angle_f;
extern unsigned char player_paused;
extern unsigned char player_health;
extern unsigned char damage_flash_timer;
extern int damage_cooldown;
extern int current_level;
extern int frame_counter;
extern unsigned char key_states[256];
extern unsigned char world_map[1024];
extern float player_start_x, player_start_y;
extern unsigned char player_start_angle;
extern float level_end_x, level_end_y;

void __stdcall mainCRTStartup(void) {
    // Init player
    player_x = 16.5f;
    player_y = 30.0f;
    player_angle = 192;   // face north
    player_angle_f = 0.0f;
    player_paused = 0;
    player_health = MAX_HEALTH;
    damage_flash_timer = 0;
    damage_cooldown = 0;
    frame_counter = 0;
    current_level = 0;

    for (int i = 0; i < 256; i++) key_states[i] = 0;
    for (int i = 0; i < 1024; i++) world_map[i] = 0;

    g_hinst = GetModuleHandleA(0);
    if (!g_hinst) ExitProcess(1);

    level_init(0);

    // Register window class
    WNDCLASSEXA wc = {0};
    wc.cbSize = sizeof(wc);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = wndproc;
    wc.hInstance = g_hinst;
    wc.hCursor = LoadCursorA(0, (LPCSTR)(LONG_PTR)IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(LONG_PTR)(COLOR_WINDOW + 1);
    wc.lpszClassName = class_name;

    if (!RegisterClassExA(&wc)) ExitProcess(1);

    // Create window
    g_hwnd = CreateWindowExA(0, class_name, window_title, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, WIN_W, WIN_H,
        0, 0, g_hinst, 0);
    if (!g_hwnd) ExitProcess(1);

    if (!init_dib()) ExitProcess(1);
    init_palette();

    ShowCursor(0);
    ShowWindow(g_hwnd, SW_SHOW);
    SetForegroundWindow(g_hwnd);
    UpdateWindow(g_hwnd);

    // Game loop
    MSG msg;
    while (g_running) {
        while (PeekMessageA(&msg, 0, 0, 0, PM_REMOVE)) {
            if (msg.message == 0x12 /* WM_QUIT */) { g_running = 0; break; }
            DispatchMessageA(&msg);
        }
        if (!g_running) break;

        process_input();
        level_check_end();
        update_particles();
        animate_fire();
        update_hud();
        update_combat();
        render_frame();

        InvalidateRect(g_hwnd, 0, 0);
        UpdateWindow(g_hwnd);
        Sleep(8);  // cap ~120fps
    }
    ExitProcess(0);
}
