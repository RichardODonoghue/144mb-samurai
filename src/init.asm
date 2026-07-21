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
    ; Entry 121: tsuba dark grey  (B=0x32, G=0x32, R=0x32)
    mov     dword [rdi + 4], 00323232h
    ; Entry 122: blade silver      (B=0xC0, G=0xC0, R=0xD0)
    mov     dword [rdi + 8], 00D0C0C0h
    ; Entry 123: blade edge shine  (B=0xF0, G=0xF0, R=0xFF)
    mov     dword [rdi + 12], 00FFF0F0h
    ; Entry 124: tsuka wrap brown  (B=0x0A, G=0x14, R=0x28)
    mov     dword [rdi + 16], 0028140Ah
    ; Entry 125: skin light         (B=0xA0, G=0xB4, R=0xDC)
    mov     dword [rdi + 20], 00DCB4A0h
    ; Entry 126: skin dark          (B=0x73, G=0x8C, R=0xB4)
    mov     dword [rdi + 24], 00B48C73h
    add     rdi, 28                    ; rdi -> entry 127
    ; Entry 127: black padding
    mov     dword [rdi], 0
    ; Entries 128-135: burnt wood walls (type 5, 4 light + 4 dark)
    mov     dword [rdi + 4],  0046321Eh
    mov     dword [rdi + 8],  00372616h
    mov     dword [rdi + 12], 0028190Eh
    mov     dword [rdi + 16], 00190F08h
    mov     dword [rdi + 20], 00322314h
    mov     dword [rdi + 24], 0023160Ch
    mov     dword [rdi + 28], 00160C06h
    mov     dword [rdi + 32], 000C0603h
    ; Entries 136-143: fire walls (type 6, 4 bright + 4 dark)
    mov     dword [rdi + 36], 00FFE63Ch
    mov     dword [rdi + 40], 00FF8C14h
    mov     dword [rdi + 44], 00DC280Ah
    mov     dword [rdi + 48], 00FFB450h
    mov     dword [rdi + 52], 00961405h
    mov     dword [rdi + 56], 00640A02h
    mov     dword [rdi + 60], 003C0501h
    mov     dword [rdi + 64], 001E0200h
    add     rdi, 68                    ; rdi -> entry 144
    ; Fill entries 144-247 with black
    mov     ecx, 104
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
