// wndproc.c — window message handler
#include "build.h"
#include "win32_imports.h"

extern HWND g_hwnd;
extern unsigned char *g_bits;
extern BITMAPINFO g_bmi;
extern unsigned char key_states[256];
extern int g_running;

LONG_PTR __stdcall wndproc(HWND hwnd, UINT msg, UINT_PTR wp, LONG_PTR lp) {
    switch (msg) {
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
        if (wp < 256) key_states[wp] = 1;
        if (wp == 0x08) PostQuitMessage(0);  // VK_BACK
        return 0;
    case WM_KEYUP:
    case WM_SYSKEYUP:
        if (wp < 256) key_states[wp] = 0;
        return 0;
    case WM_DESTROY:
    case WM_CLOSE:
        PostQuitMessage(0);
        return 0;
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        if (hdc && g_bits) {
            StretchDIBits(hdc, 0, 0, WIN_W, WIN_H, 0, 0, SCR_W, SCR_H, g_bits, &g_bmi, 0, SRCCOPY);
        }
        EndPaint(hwnd, &ps);
        return 0;
    }
    }
    return DefWindowProcA(hwnd, msg, wp, lp);
}
