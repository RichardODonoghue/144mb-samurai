section .text

; ============================================================
; init_palette -- fill BITMAPINFO colour table
; ============================================================
init_palette:
    lea     rdi, [g_bmi + BMICOLORS_OFFSET]

    ; --- Sky gradient: 64 entries, dark purple -> bright purple ---
    xor     ecx, ecx
.sky:
    movzx   eax, cl
    shl     eax, 2               ; sky ramp: 0..252
    add     eax, 4
    cmp     eax, 255
    jbe     .s1
    mov     eax, 255
.s1:
    mov     byte [rdi], al       ; Blue
    mov     byte [rdi + 2], al   ; Red
    mov     byte [rdi + 1], 0    ; Green
    mov     byte [rdi + 3], 0    ; Reserved
    add     rdi, 4
    inc     ecx
    cmp     ecx, PAL_SKY_COUNT
    jb      .sky

    ; --- Floor dirt palette (64-79): 8 light + 8 dark ---
    lea     rsi, [pal_floor_dirt_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_floor_dirt_y]
    mov     ecx, 8
    rep     movsd

    ; --- Brick walls (80-95) ---
    lea     rsi, [pal_brick_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_brick_y]
    mov     ecx, 8
    rep     movsd

    ; --- Stone walls (96-111) ---
    lea     rsi, [pal_stone_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_stone_y]
    mov     ecx, 8
    rep     movsd

    ; --- Wood shop walls (112-127) ---
    lea     rsi, [pal_wood_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_wood_y]
    mov     ecx, 8
    rep     movsd

    ; --- Burnt wood walls (128-143) ---
    lea     rsi, [pal_burnt_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_burnt_y]
    mov     ecx, 8
    rep     movsd

    ; --- Fire walls (144-159) ---
    lea     rsi, [pal_fire_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_fire_y]
    mov     ecx, 8
    rep     movsd

    ; --- Floor wood palette (160-175): 8 light + 8 dark ---
    lea     rsi, [pal_floor_wood_x]
    mov     ecx, 8
    rep     movsd
    lea     rsi, [pal_floor_wood_y]
    mov     ecx, 8
    rep     movsd

    ; --- Weapon/skin palette (176-183): 8 entries ---
    lea     rsi, [pal_weapon]
    mov     ecx, 8
    rep     movsd
    ; Overwrite entry 176 (weapon green) with HUD green
    mov     dword [g_bmi + BMICOLORS_OFFSET + PAL_HUD_GREEN * 4], 0000CC00h

    ; --- Fire animation entries (184-187) ---
    lea     rsi, [fire_cycle0]
    mov     ecx, 4
    rep     movsd

    ; --- Particle/ash entries (188-191) ---
    mov     dword [rdi],      00FFB450h   ; 188: bright fire ember
    mov     dword [rdi + 4],  0064280Ah   ; 189: dark red ember
    mov     dword [rdi + 8],  00CC0000h   ; 190: HUD red (blood) — R=204
    mov     dword [rdi + 12], 00FFFFFFh   ; 191: HUD white
    add     rdi, 16

    ; --- Fog ramp (192-223): 32 entries ---
    lea     rsi, [pal_fog]
    mov     ecx, 32
    rep     movsd

    ; --- Vignette dark ramp (224-247): 24 entries ---
    ; Progressive darkening for vignette: purple-black gradient
    xor     ecx, ecx
.vig:
    movzx   eax, cl
    mov     edx, 120
    sub     edx, eax
    imul    edx, 120
    shr     edx, 7
    mov     ebx, edx               ; R = scaled
    shr     edx, 1                 ; G = half
    mov     byte [rdi], bl         ; B = scaled
    mov     byte [rdi + 1], dl     ; G
    mov     byte [rdi + 2], bl     ; R
    mov     byte [rdi + 3], 0
    add     rdi, 4
    inc     ecx
    cmp     ecx, 24
    jb      .vig

    ; --- Roof and foundation palette (248-255): 8 entries ---
    mov     dword [rdi],      0040302Ah   ; 248: dark blue-grey tile
    mov     dword [rdi + 4],  0050403Ah   ; 249: lighter tile
    mov     dword [rdi + 8],  0040204Ah   ; 250: HUD bruise (dark purple)
    mov     dword [rdi + 12], 00181410h   ; 251: eave shadow (near black)
    mov     dword [rdi + 16], 00484040h   ; 252: foundation dark stone
    mov     dword [rdi + 20], 0050604Ah   ; 253: eave curl highlight
    mov     dword [rdi + 24], 00303038h   ; 254: HUD panel (dark gunmetal)
    mov     dword [rdi + 28], 00606068h   ; 255: HUD border (medium grey)

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
    call    init_vignette

    add     rsp, 38h
    ret

; ============================================================
; init_vignette -- decompress RLE vignette into vignette_mask
; ============================================================
init_vignette:
    lea     rsi, [vignette_rle]
    lea     rdi, [vignette_mask]
    ; End of RLE data = vignette_rle + vignette_rle_len
    mov     r10d, [vignette_rle_len]
    lea     r10, [rsi + r10]           ; end of RLE data pointer
    mov     r8d, [vignette_full_len]   ; target bytes to produce
    xor     r9d, r9d                    ; bytes emitted
    xor     eax, eax
.vloop:
    ; Need at least 2 bytes for next entry
    lea     r11, [rsi + 2]
    cmp     r11, r10
    ja      .vig_done                   ; past end of data
    cmp     r9d, r8d
    jae     .vig_done                   ; emitted enough
    movzx   ecx, byte [rsi]             ; count
    movzx   eax, byte [rsi + 1]         ; value
    add     rsi, 2
    ; Clamp to remaining bytes
    mov     r11d, r8d
    sub     r11d, r9d
    cmp     ecx, r11d
    jbe     .vc_ok
    mov     ecx, r11d
.vc_ok:
    rep     stosb
    add     r9d, ecx
    jmp     .vloop
.vig_done:
    ret
