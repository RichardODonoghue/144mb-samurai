%include "src/build.inc"

; ============================================================
; ALL EXTERN DECLARATIONS
; ============================================================
extern GetModuleHandleA
extern LoadCursorA
extern RegisterClassExA
extern CreateWindowExA
extern ShowWindow
extern UpdateWindow
extern DefWindowProcA
extern PostQuitMessage
extern ExitProcess
extern GetDC
extern ReleaseDC
extern CreateDIBSection
extern StretchDIBits
extern PeekMessageA
extern DispatchMessageA
extern GetAsyncKeyState
extern GetCursorPos
extern SetCursorPos
extern ScreenToClient
extern ClientToScreen
extern InvalidateRect
extern GetClientRect
extern BeginPaint
extern EndPaint
extern ShowCursor
extern SetForegroundWindow

; ============================================================
; MODULE INCLUDES
; ============================================================
%include "src/data.asm"
%include "src/init.asm"
%include "src/render.asm"
%include "src/input.asm"
%include "src/wndproc.asm"

; ============================================================
; ENTRY POINT & GAME LOOP
; ============================================================
section .text

global main

game_loop:
    sub     rsp, FRAME_SIZE

.peek:
    lea     rcx, [rsp + FRAME_MSG]
    xor     edx, edx
    xor     r8d, r8d
    xor     r9d, r9d
    mov     dword [rsp + FRAME_PM5], 1   ; PM_REMOVE
    call    PeekMessageA
    test    rax, rax
    jz      .do_frame                     ; no message → render

    cmp     dword [rsp + FRAME_MSG + 8], 12h  ; WM_QUIT
    je      .exit

    lea     rcx, [rsp + FRAME_MSG]
    call    DispatchMessageA
    ; fall through to render after dispatching

.do_frame:
    call    process_input
    call    render_frame
    mov     rcx, [g_hwnd]
    xor     edx, edx
    xor     r8d, r8d
    call    InvalidateRect
    mov     rcx, [g_hwnd]
    call    UpdateWindow
    jmp     .peek

.exit:
    add     rsp, FRAME_SIZE
    xor     ecx, ecx
    call    ExitProcess

main:
    sub     rsp, 0F8h

    xor     ecx, ecx
    call    GetModuleHandleA
    mov     [g_hinst], rax
    mov     r12, rax

    ; Init player state
    mov     eax, [player_start_x]
    mov     [player_x], eax
    mov     eax, [player_start_y]
    mov     [player_y], eax
    mov     al, [player_start_angle]
    mov     [player_angle], al
    mov     dword [player_angle_f], 0        ; float 0.0
    mov     byte [player_paused], 0

    ; Register window class
    lea     rdi, [rsp + 30h]
    mov     dword [rdi], 80
    mov     dword [rdi + 4], CS_HREDRAW | CS_VREDRAW
    lea     rax, [wndproc]
    mov     [rdi + 8], rax
    mov     qword [rdi + 16], 0
    mov     [rdi + 24], r12
    mov     qword [rdi + 32], 0

    xor     ecx, ecx
    mov     edx, IDC_ARROW
    call    LoadCursorA
    mov     [rdi + 40], rax

    mov     qword [rdi + 48], COLOR_WINDOW + 1
    mov     qword [rdi + 56], 0
    lea     rax, [class_name]
    mov     [rdi + 64], rax
    mov     qword [rdi + 72], 0

    mov     rcx, rdi
    call    RegisterClassExA
    test    rax, rax
    jz      .exit

    ; CreateWindowExA
    mov     qword [rsp + 58h], 0
    mov     [rsp + 50h], r12
    mov     qword [rsp + 48h], 0
    mov     qword [rsp + 40h], 0
    mov     dword [rsp + 38h], WIN_H
    mov     dword [rsp + 30h], WIN_W
    mov     dword [rsp + 28h], CW_USEDEFAULT
    mov     dword [rsp + 20h], CW_USEDEFAULT
    mov     r9d, WS_OVERLAPPEDWINDOW
    lea     r8, [window_title]
    lea     rdx, [class_name]
    xor     ecx, ecx
    call    CreateWindowExA
    test    rax, rax
    jz      .exit
    mov     [g_hwnd], rax

    call    init_dib

    ; Hide cursor during gameplay
    mov     ecx, 0          ; FALSE
    call    ShowCursor

    mov     rcx, [g_hwnd]
    mov     edx, SW_SHOW
    call    ShowWindow

    mov     rcx, [g_hwnd]
    call    SetForegroundWindow

    mov     rcx, [g_hwnd]
    call    UpdateWindow

    add     rsp, 0F8h
    jmp     game_loop

.exit:
    xor     ecx, ecx
    call    ExitProcess
