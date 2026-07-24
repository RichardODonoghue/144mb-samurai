// win32_imports.h — all Win32 API declarations
#ifndef WIN32_IMPORTS_H
#define WIN32_IMPORTS_H
#include "win32_types.h"

typedef unsigned short ATOM;
typedef HANDLE HMENU;

__declspec(dllimport) HANDLE __stdcall GetModuleHandleA(LPCSTR);
__declspec(dllimport) HCURSOR __stdcall LoadCursorA(HINSTANCE, LPCSTR);
__declspec(dllimport) ATOM __stdcall RegisterClassExA(const WNDCLASSEXA*);
__declspec(dllimport) HWND __stdcall CreateWindowExA(DWORD, LPCSTR, LPCSTR, DWORD, int, int, int, int, HWND, HMENU, HINSTANCE, void*);
__declspec(dllimport) BOOL __stdcall ShowWindow(HWND, int);
__declspec(dllimport) BOOL __stdcall UpdateWindow(HWND);
__declspec(dllimport) LONG_PTR __stdcall DefWindowProcA(HWND, UINT, UINT_PTR, LONG_PTR);
__declspec(dllimport) void __stdcall PostQuitMessage(int);
__declspec(dllimport) void __stdcall ExitProcess(UINT);
__declspec(dllimport) HDC __stdcall GetDC(HWND);
__declspec(dllimport) int __stdcall ReleaseDC(HWND, HDC);
__declspec(dllimport) HBITMAP __stdcall CreateDIBSection(HDC, const BITMAPINFO*, UINT, void**, HANDLE, DWORD);
__declspec(dllimport) BOOL __stdcall StretchDIBits(HDC, int, int, int, int, int, int, int, int, const void*, const BITMAPINFO*, UINT, DWORD);
__declspec(dllimport) BOOL __stdcall PeekMessageA(MSG*, HWND, UINT, UINT, UINT);
__declspec(dllimport) LONG_PTR __stdcall DispatchMessageA(const MSG*);
__declspec(dllimport) short __stdcall GetAsyncKeyState(int);
__declspec(dllimport) BOOL __stdcall GetCursorPos(POINT*);
__declspec(dllimport) BOOL __stdcall SetCursorPos(int, int);
__declspec(dllimport) BOOL __stdcall ScreenToClient(HWND, POINT*);
__declspec(dllimport) BOOL __stdcall ClientToScreen(HWND, POINT*);
__declspec(dllimport) BOOL __stdcall InvalidateRect(HWND, const RECT*, BOOL);
__declspec(dllimport) BOOL __stdcall GetClientRect(HWND, RECT*);
__declspec(dllimport) HDC __stdcall BeginPaint(HWND, PAINTSTRUCT*);
__declspec(dllimport) BOOL __stdcall EndPaint(HWND, const PAINTSTRUCT*);
__declspec(dllimport) int __stdcall ShowCursor(BOOL);
__declspec(dllimport) BOOL __stdcall SetForegroundWindow(HWND);
__declspec(dllimport) void __stdcall Sleep(DWORD);

#endif // WIN32_IMPORTS_H
