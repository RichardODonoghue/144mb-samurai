section .text

; ================================================================
; draw_weapon — render katana + arms using sprite system
; Replaces old hardcoded geometric drawing.
; Reads combat state to select sprite frames.
; ================================================================
draw_weapon:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 28h

    mov     r15, [g_bits]               ; framebuffer base
    test    r15, r15
    jz      .dw_done

    ; ---- Select weapon sprite frame ----
    movzx   eax, byte [attack_state]
    test    eax, eax
    jnz     .dw_attack

    ; ---- Block state ----
    movzx   eax, byte [block_state]
    test    eax, eax
    jnz     .dw_block_active

    ; Idle: frame 0
    xor     r12d, r12d                  ; weapon_frame = 0
    jmp     .dw_draw

.dw_attack:
    cmp     al, 1                        ; WINDUP
    jne     .dw_chk_swing
    movzx   ecx, byte [attack_timer]
    shr     ecx, 1                       ; timer / 2 → 0 or 1
    cmp     ecx, 1
    mov     eax, 1                       ; windup_1
    cmovg   eax, ecx                     ; windup_2 if timer>=2
    mov     r12d, eax
    jmp     .dw_draw

.dw_chk_swing:
    cmp     al, 2                        ; SWING
    jne     .dw_chk_recover
    movzx   ecx, byte [attack_timer]
    cmp     ecx, 2
    jl      .swing_early
    cmp     ecx, 4
    jl      .swing_mid
    mov     r12d, 5                      ; swing_3
    jmp     .dw_draw
.swing_early:
    mov     r12d, 3                      ; swing_1
    jmp     .dw_draw
.swing_mid:
    mov     r12d, 4                      ; swing_2
    jmp     .dw_draw

.dw_chk_recover:
    cmp     al, 3                        ; RECOVER
    jne     .dw_no_attack
    movzx   ecx, byte [attack_timer]
    cmp     ecx, 2
    jl      .rec_early
    cmp     ecx, 4
    jl      .rec_mid
    mov     r12d, 0                      ; back to idle
    jmp     .dw_draw
.rec_early:
    mov     r12d, 5                      ; swing_3
    jmp     .dw_draw
.rec_mid:
    mov     r12d, 4                      ; swing_2
    jmp     .dw_draw

.dw_no_attack:
    xor     r12d, r12d
    jmp     .dw_draw

.dw_block_active:
    mov     r12d, 6                      ; block frame

.dw_draw:
    ; r12d = weapon frame index (0..6)

    ; ---- Compute screen position ----
    cvttss2si r13d, [blade_swing_x]     ; integer X offset
    cvttss2si r14d, [blade_y_mod]       ; integer Y offset

    mov     ebx, r12d                   ; save weapon frame

    ; Weapon sprite pointer from table
    lea     rax, [weapon_sprites]
    mov     rcx, [rax + rbx * 8]        ; sprite_ptr = weapon_sprites[frame]

    ; Weapon screen position
    mov     edx, WEP_BASE_X
    add     edx, r13d                   ; + blade_swing_x
    mov     r8d, WEP_BASE_Y
    add     r8d, r14d                   ; + blade_y_mod
    call    draw_sprite

    ; ---- Draw arms (separate layer) ----
    lea     rax, [arm_sprites]
    mov     rcx, [rax + rbx * 8]        ; same index, arm_sprites table

    mov     edx, ARM_BASE_X
    add     edx, r13d
    mov     r8d, ARM_BASE_Y
    add     r8d, r14d
    call    draw_sprite

.dw_done:
    add     rsp, 28h
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
