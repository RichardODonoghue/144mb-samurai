section .text

; ============================================================
; init_palette -- fill BITMAPINFO colour table
; ============================================================
init_palette:
    lea     rdi, [g_bmi + BMICOLORS_OFFSET]

    xor     ecx, ecx
.sky:
    movzx   eax, cl
    shl     eax, 1
    add     eax, 30
    cmp     eax, 255
    jbe     .s1
    mov     eax, 255
.s1:
    mov     byte [rdi], al
    mov     byte [rdi + 2], al
    mov     byte [rdi + 1], 0
    mov     byte [rdi + 3], 0
    add     rdi, 4
    inc     ecx
    cmp     ecx, 96
    jb      .sky

    ; Brick (type 1)
    mov     dword [rdi],      004028A0h
    mov     dword [rdi + 4],  004830B0h
    mov     dword [rdi + 8],  005038C0h
    mov     dword [rdi + 12], 006040D0h
    mov     dword [rdi + 16], 007048E0h
    mov     dword [rdi + 20], 008050F0h
    mov     dword [rdi + 24], 009058FFh
    mov     dword [rdi + 28], 00B060FFh
    add     rdi, 32

    ; Stone (type 2)
    mov     dword [rdi],      00505050h
    mov     dword [rdi + 4],  00606060h
    mov     dword [rdi + 8],  00707070h
    mov     dword [rdi + 12], 00808080h
    mov     dword [rdi + 16], 00909090h
    mov     dword [rdi + 20], 00A0A0A0h
    mov     dword [rdi + 24], 00B0B0B0h
    mov     dword [rdi + 28], 00C0C0C0h
    add     rdi, 32

    ; Wood (type 3)
    mov     dword [rdi],      002D1A50h
    mov     dword [rdi + 4],  003D2860h
    mov     dword [rdi + 8],  004D3670h
    mov     dword [rdi + 12], 005D4480h
    mov     dword [rdi + 16], 006D5290h
    mov     dword [rdi + 20], 007D60A0h
    mov     dword [rdi + 24], 008D6EB0h
    mov     dword [rdi + 28], 009D7CC0h
    add     rdi, 32

    ; Entry 120: green marker (B=0, G=255, R=0)
    mov     dword [rdi], 0000FF00h
    add     rdi, 4
    ; Fill remaining with black
    mov     ecx, 127
    xor     eax, eax
    rep     stosd

    ret

; ============================================================
; init_dib -- create 320x200 8-bit DIB section
; ============================================================
init_dib:
    sub     rsp, 38h

    lea     rdi, [g_bmi]
    mov     dword [rdi + BISIZE], 40
    mov     dword [rdi + BIWIDTH], SCR_W
    mov     dword [rdi + BIHEIGHT], -SCR_H
    mov     word  [rdi + BIPLANES], 1
    mov     word  [rdi + BIBITCOUNT], 8
    mov     dword [rdi + BICOMPRESSION], 0
    mov     dword [rdi + BISIZEIMAGE], 0
    mov     dword [rdi + BIXPELSPERMETER], 0
    mov     dword [rdi + BIYPELSPERMETER], 0
    mov     dword [rdi + BICLRUSED], 256
    mov     dword [rdi + BICLRIMPORTANT], 0

    mov     rcx, [g_hwnd]
    call    GetDC
    mov     [rsp + 30h], rax

    mov     rcx, rax
    lea     rdx, [g_bmi]
    mov     r8d, 0
    lea     r9, [g_bits]
    mov     qword [rsp + 20h], 0
    mov     qword [rsp + 28h], 0
    call    CreateDIBSection
    mov     [g_dib], rax

    mov     rcx, [g_hwnd]
    mov     rdx, [rsp + 30h]
    call    ReleaseDC

    call    init_palette

    add     rsp, 38h
    ret
