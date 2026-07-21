section .text

; ============================================================
; level_init -- load a level by index, copy map, set start/end
;   ecx = level index (0, 1, ...)
; ============================================================
level_init:
    mov     [current_level], ecx
    cmp     ecx, 1
    je      .load_l1
    ; Level 0 (default / training)
    lea     rsi, [level0_map]
    lea     rdi, [world_map]
    mov     ecx, 256
    rep     movsb
    mov     eax, [level0_start_x]
    mov     [player_start_x], eax
    mov     eax, [level0_start_y]
    mov     [player_start_y], eax
    mov     al, [level0_start_angle]
    mov     [player_start_angle], al
    mov     eax, [level0_end_x]
    mov     [level_end_x], eax
    mov     eax, [level0_end_y]
    mov     [level_end_y], eax
    jmp     .reset_player

.load_l1:
    lea     rsi, [level1_map]
    lea     rdi, [world_map]
    mov     ecx, 256
    rep     movsb
    mov     eax, [level1_start_x]
    mov     [player_start_x], eax
    mov     eax, [level1_start_y]
    mov     [player_start_y], eax
    mov     al, [level1_start_angle]
    mov     [player_start_angle], al
    mov     eax, [level1_end_x]
    mov     [level_end_x], eax
    mov     eax, [level1_end_y]
    mov     [level_end_y], eax

.reset_player:
    mov     eax, [player_start_x]
    mov     [player_x], eax
    mov     eax, [player_start_y]
    mov     [player_y], eax
    mov     al, [player_start_angle]
    mov     [player_angle], al
    mov     dword [player_angle_f], 0
    ret

; ============================================================
; level_check_end -- check if player near end trigger
; ============================================================
level_check_end:
    movss   xmm0, [player_x]
    subss   xmm0, [level_end_x]
    mulss   xmm0, xmm0
    movss   xmm1, [player_y]
    subss   xmm1, [level_end_y]
    mulss   xmm1, xmm1
    addss   xmm0, xmm1
    mov     eax, 0x40100000         ; 2.25f (1.5^2)
    movd    xmm1, eax
    comiss  xmm0, xmm1
    ja      .not_end
    mov     ecx, [current_level]
    inc     ecx
    call    level_init
    cmp     eax, eax                ; ZF=1
    ret
.not_end:
    xor     eax, eax
    inc     eax                      ; ZF=0
    ret
