BITS 64
DEFAULT REL

; ============================================================
; CONSTANTS
; ============================================================

SCR_W           equ 320
SCR_H           equ 200
MAP_W           equ 16
MAP_H           equ 16
FOV_HALF        equ 33
MAX_DEPTH       equ 32

; Win32 constants
IDC_ARROW           equ 7F00h
CS_HREDRAW          equ 2
CS_VREDRAW          equ 1
WS_OVERLAPPEDWINDOW equ 00CF0000h
CW_USEDEFAULT       equ 80000000h
SW_SHOW             equ 5
WM_DESTROY          equ 2
WM_CLOSE            equ 10h
WM_PAINT            equ 0Fh
WM_SIZE             equ 5
WM_KEYDOWN          equ 100h
WM_KEYUP            equ 101h
WM_SYSKEYDOWN       equ 104h
WM_SYSKEYUP         equ 105h
COLOR_WINDOW        equ 5

; Virtual keys
VK_W        equ 57h
VK_A        equ 41h
VK_S        equ 53h
VK_D        equ 44h
VK_SPACE    equ 20h
VK_ESCAPE   equ 1Bh
VK_LBUTTON  equ 01h
VK_RBUTTON  equ 02h
VK_SHIFT    equ 10h
VK_BACK     equ 08h

; BITMAPINFOHEADER offsets
BISIZE           equ 0
BIWIDTH          equ 4
BIHEIGHT         equ 8
BIPLANES         equ 12
BIBITCOUNT       equ 14
BICOMPRESSION    equ 16
BISIZEIMAGE      equ 20
BIXPELSPERMETER  equ 24
BIYPELSPERMETER  equ 28
BICLRUSED        equ 32
BICLRIMPORTANT   equ 36
BMIHEADER_SIZE   equ 40
BMICOLORS_OFFSET equ 40

; Window dimensions
WIN_W   equ 960
WIN_H   equ 600

; Stack frame for game loop
FRAME_SHADOW    equ 00h
FRAME_PM5       equ 20h
FRAME_MSG       equ 28h
FRAME_RECT      equ 58h
FRAME_CURSOR    equ 68h
FRAME_CENTER    equ 70h
FRAME_SIZE      equ 78h
