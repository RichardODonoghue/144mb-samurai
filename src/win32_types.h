// win32_types.h — minimal Win32 type definitions (no windows.h needed)
#ifndef WIN32_TYPES_H
#define WIN32_TYPES_H

typedef void *HANDLE;
typedef HANDLE HWND;
typedef HANDLE HINSTANCE;
typedef HANDLE HDC;
typedef HANDLE HBITMAP;
typedef HANDLE HGDIOBJ;
typedef HANDLE HCURSOR;
typedef HANDLE HBRUSH;
typedef HANDLE HICON;
typedef const char *LPCSTR;
typedef unsigned __int64 UINT_PTR;
typedef __int64 LONG_PTR;
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef unsigned short WORD;
typedef unsigned char BYTE;
typedef long LONG;
typedef int BOOL;

typedef struct tagPOINT { LONG x, y; } POINT;
typedef struct tagRECT { LONG left, top, right, bottom; } RECT;
typedef struct tagMSG { HWND hwnd; UINT message; UINT_PTR wParam; LONG_PTR lParam; DWORD time; POINT pt; } MSG;
typedef struct tagPAINTSTRUCT { HDC hdc; BOOL fErase; RECT rcPaint; BOOL fRestore; BOOL fIncUpdate; BYTE rgbReserved[32]; } PAINTSTRUCT;

typedef struct {
    DWORD  biSize; LONG biWidth, biHeight; WORD biPlanes, biBitCount;
    DWORD  biCompression, biSizeImage; LONG biXPelsPerMeter, biYPelsPerMeter;
    DWORD  biClrUsed, biClrImportant;
} BITMAPINFOHEADER;

typedef struct {
    BITMAPINFOHEADER bmiHeader;
    DWORD bmiColors[256];
} BITMAPINFO;

typedef LONG_PTR (__stdcall *WNDPROC)(HWND, UINT, UINT_PTR, LONG_PTR);

typedef struct {
    UINT        cbSize;
    UINT        style;
    WNDPROC     lpfnWndProc;
    int         cbClsExtra;
    int         cbWndExtra;
    HINSTANCE   hInstance;
    HICON       hIcon;
    HCURSOR     hCursor;
    HBRUSH      hbrBackground;
    LPCSTR      lpszMenuName;
    LPCSTR      lpszClassName;
    HICON       hIconSm;
} WNDCLASSEXA;

#endif // WIN32_TYPES_H
