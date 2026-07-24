section .text

; ================================================================
; draw_sprite — general-purpose sprite blitter
;
; Parameters:
;   rcx = ptr to sprite data (dw width, dw height, db pixels...)
;   rdx = dest_x (int, screen X of top-left)
;   r8  = dest_y (int, screen Y of top-left)
;
; Uses: r15 = g_bits framebuffer (must be set by caller)
; Skips pixel value 0 (transparent). Clamps to screen edges.
; ================================================================
draw_sprite:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    rsi
    push    rdi

    mov     rsi, rcx                    ; sprite data pointer
    movzx   r12d, word [rsi]            ; sprite width
    movzx   r13d, word [rsi + 2]        ; sprite height
    add     rsi, 4                      ; skip header → pixel data

    mov     r14d, edx                   ; dest_x
    mov     ebx, r8d                    ; dest_y

    test    r15, r15
    jz      .ds_done

    xor     r10d, r10d                  ; row = 0
.ds_row:
    cmp     r10d, r13d                  ; row >= height?
    jae     .ds_done

    mov     eax, ebx
    add     eax, r10d                   ; screen_y = dest_y + row
    cmp     eax, 0
    jl      .ds_next_row
    cmp     eax, SCR_H - 1
    jg      .ds_done                    ; past bottom of screen

    imul    eax, SCR_W                  ; row_base = screen_y * SCR_W

    xor     r11d, r11d                  ; col = 0
.ds_col:
    cmp     r11d, r12d                  ; col >= width?
    jae     .ds_next_row

    ; Read pixel from sprite
    movzx   edx, byte [rsi]
    inc     rsi

    test    edx, edx
    jz      .ds_skip                    ; transparent (0)

    ; Compute screen position
    mov     ecx, r14d
    add     ecx, r11d                   ; screen_x = dest_x + col
    cmp     ecx, 0
    jl      .ds_skip_next
    cmp     ecx, SCR_W - 1
    jg      .ds_skip_next

    add     ecx, eax                    ; offset = row_base + screen_x
    mov     byte [r15 + rcx], dl

.ds_skip_next:
    inc     r11d
    jmp     .ds_col

.ds_skip:
    inc     r11d
    jmp     .ds_col

.ds_next_row:
    ; Skip remaining pixels in this row if we jumped early
    ; Actually we already increment rsi per pixel, so rsi is ahead.
    ; But if we jumped from .ds_next_row, we need to skip remaining cols:
    mov     eax, r12d
    sub     eax, r11d
    jle     .ds_row_inc
    add     rsi, rax                   ; skip remaining
.ds_row_inc:
    inc     r10d
    jmp     .ds_row

.ds_done:
    pop     rdi
    pop     rsi
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
