section .text

; ============================================================
; draw_hud -- Doom-style status bar at screen bottom
; Textured metal panel background, heart health indicator, face
; ============================================================
draw_hud:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    rdi
    push    rsi

    mov     r15, [g_bits]
    test    r15, r15
    jz      .hud_done

    ; ---- Textured panel background: tile tex_hud_panel ----
    lea     rsi, [tex_hud_panel]         ; 32x32 source texture
    mov     r12d, HUD_Y_START            ; y

.panel_row:
    cmp     r12d, HUD_Y_END + 1
    jae     .panel_done
    imul    edi, r12d, SCR_W
    add     rdi, r15                     ; dest row start
    mov     eax, r12d
    and     eax, 31                     ; texture Y = y & 31
    shl     eax, 5                      ; * 32 (texture width)
    xor     ebx, ebx                    ; x = 0

.panel_col:
    cmp     ebx, SCR_W
    jae     .panel_next_row
    mov     ecx, ebx
    and     ecx, 31                     ; texture X = x & 31
    add     ecx, eax                    ; offset = row*32 + col
    movzx   edx, byte [rsi + rcx]       ; texel from hud_panel texture
    ; Map texel (0-7) to HUD palette range for metal look
    ; Low contrast: use dark gunmetal range
    ; texel 0-1 -> very dark, 2-4 -> panel bg, 5-7 -> slightly lighter
    cmp     edx, 2
    jae     .pl2
    mov     edx, 248                     ; dark blue-grey (roof tile)
    jmp     .pl_store
.pl2:
    cmp     edx, 5
    jae     .pl5
    mov     edx, PAL_HUD_PANEL          ; 254 dark gunmetal
    jmp     .pl_store
.pl5:
    mov     edx, 255                     ; slightly lighter border color
.pl_store:
    mov     byte [rdi + rbx], dl
    inc     ebx
    jmp     .panel_col

.panel_next_row:
    inc     r12d
    jmp     .panel_row
.panel_done:

    ; ---- Heart health indicator ----
    movzx   eax, byte [player_health]
    cmp     eax, 80
    jae     .heart_full
    cmp     eax, 60
    jae     .heart_75
    cmp     eax, 40
    jae     .heart_50
    cmp     eax, 20
    jae     .heart_25
    mov     rsi, [heart_table + 32]      ; heart_empty
    jmp     .heart_draw
.heart_full:
    mov     rsi, [heart_table]           ; heart_full
    jmp     .heart_draw
.heart_75:
    mov     rsi, [heart_table + 8]       ; heart_75
    jmp     .heart_draw
.heart_50:
    mov     rsi, [heart_table + 16]      ; heart_50
    jmp     .heart_draw
.heart_25:
    mov     rsi, [heart_table + 24]      ; heart_25

.heart_draw:
    mov     r12d, 0                      ; row
.heart_row:
    cmp     r12d, HUD_HEART_H
    jae     .heart_done
    mov     eax, HUD_HEART_Y
    add     eax, r12d
    imul    edi, eax, SCR_W
    add     edi, HUD_HEART_X
    add     rdi, r15
    mov     ecx, HUD_HEART_W
    rep     movsb
    inc     r12d
    jmp     .heart_row
.heart_done:

    ; ---- Health text: "100/100" next to heart ----
    mov     r8d, HUD_TEXT_X
    mov     r9d, HUD_TEXT_Y

    ; Draw hundreds digit (dummy "1" for 100 — we draw constant format)
    movzx   eax, byte [player_health]
    mov     ecx, 100
    xor     edx, edx
    div     ecx                         ; eax = hundreds
    mov     r14d, eax
    mov     eax, edx
    mov     ecx, 10
    xor     edx, edx
    div     ecx                         ; eax = tens, edx = ones
    mov     r13d, eax
    mov     r12d, edx

    ; Draw hundreds
    cmp     r14d, 0
    je      .no_h
    mov     r10d, r14d
    call    draw_digit
    add     r8d, HUD_FONT_W + 1
.no_h:
    ; Draw tens
    mov     r10d, r13d
    call    draw_digit
    add     r8d, HUD_FONT_W + 1
    ; Draw ones
    mov     r10d, r12d
    call    draw_digit
    add     r8d, HUD_FONT_W + 1
    ; Draw '/'
    mov     r10d, 13                     ; '/' glyph
    call    draw_glyph
    add     r8d, HUD_FONT_W + 1
    ; Draw "100"
    mov     r10d, 1
    call    draw_digit
    add     r8d, HUD_FONT_W + 1
    mov     r10d, 0
    call    draw_digit
    add     r8d, HUD_FONT_W + 1
    mov     r10d, 0
    call    draw_digit

    ; ---- Samurai face ----
    movzx   eax, byte [player_health]
    cmp     eax, 80
    jae     .face_0
    cmp     eax, 60
    jae     .face_1
    cmp     eax, 40
    jae     .face_2
    cmp     eax, 20
    jae     .face_3
    mov     rsi, [face_table + 32]
    jmp     .face_draw
.face_0:
    mov     rsi, [face_table]
    jmp     .face_draw
.face_1:
    mov     rsi, [face_table + 8]
    jmp     .face_draw
.face_2:
    mov     rsi, [face_table + 16]
    jmp     .face_draw
.face_3:
    mov     rsi, [face_table + 24]

.face_draw:
    mov     r12d, 0
.f_row:
    cmp     r12d, HUD_FACE_H
    jae     .hud_done
    mov     eax, HUD_FACE_Y
    add     eax, r12d
    imul    edi, eax, SCR_W
    add     edi, HUD_FACE_X
    add     rdi, r15
    mov     ecx, HUD_FACE_W
    rep     movsb
    inc     r12d
    jmp     .f_row

.hud_done:
    pop     rsi
    pop     rdi
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ============================================================
; draw_digit -- draw a single digit glyph (0-9)
; ============================================================
draw_digit:
    cmp     r10d, 9
    ja      .dig_done
    jmp     draw_glyph
.dig_done:
    ret

; ============================================================
; draw_glyph -- draw a 3x5 font glyph at (X, Y)
; ============================================================
draw_glyph:
    push    rsi
    push    rdi
    push    rbx
    push    r12
    push    r14

    imul    eax, r10d, font_glyph_size
    lea     rsi, [font_data + rax]

    mov     r12d, 0
.gly_row:
    cmp     r12d, HUD_FONT_H
    jae     .gly_done
    mov     eax, r9d
    add     eax, r12d
    cmp     eax, 0
    jl      .gly_next_row
    cmp     eax, SCR_H - 1
    jg      .gly_next_row
    imul    edi, eax, SCR_W
    add     edi, r8d

    mov     ebx, 0
.gly_col:
    cmp     ebx, HUD_FONT_W
    jae     .gly_next_row
    movzx   eax, byte [rsi + rbx]
    cmp     al, 254
    je      .gly_skip
    mov     ecx, r8d
    add     ecx, ebx
    cmp     ecx, 0
    jl      .gly_skip
    cmp     ecx, SCR_W - 1
    jg      .gly_skip
    add     ecx, edi
    mov     byte [r15 + rcx], al
.gly_skip:
    inc     ebx
    jmp     .gly_col
.gly_next_row:
    add     rsi, HUD_FONT_W
    inc     r12d
    jmp     .gly_row
.gly_done:
    pop     r14
    pop     r12
    pop     rbx
    pop     rdi
    pop     rsi
    ret

; ============================================================
; update_hud -- process damage flash timer each frame
; ============================================================
update_hud:
    movzx   eax, byte [damage_flash_timer]
    test    eax, eax
    jz      .hud_upd_done
    dec     al
    mov     [damage_flash_timer], al
    test    al, 1
    jnz     .hud_upd_done
    lea     rdi, [g_bmi + BMICOLORS_OFFSET + 0]
    mov     ecx, 16
.flash_loop:
    movzx   eax, byte [rdi]
    movzx   edx, byte [rdi + 1]
    shr     edx, 1
    shr     eax, 1
    add     eax, 80
    cmp     eax, 255
    jbe     .fl_b
    mov     eax, 255
.fl_b:
    mov     byte [rdi + 2], al
    mov     byte [rdi + 1], dl
    mov     byte [rdi], 0
    add     rdi, 4
    dec     ecx
    jnz     .flash_loop
.hud_upd_done:
    ret

; ============================================================
; apply_damage -- call when player takes damage
; Input: cl = damage amount
; ============================================================
apply_damage:
    movzx   eax, byte [player_health]
    sub     al, cl
    jns     .dam_ok
    xor     eax, eax
.dam_ok:
    mov     [player_health], al
    mov     byte [damage_flash_timer], DAMAGE_FLASH_FRAMES
    ret
