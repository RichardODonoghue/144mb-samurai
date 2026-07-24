section .text

; ============================================================
; update_combat -- advance attack/block state machines
; Computes blade_swing_x, blade_y_mod each frame
; ============================================================
update_combat:
    push    rbx

    ; ---- Attack state machine ----
    movzx   eax, byte [attack_state]
    test    eax, eax
    jz      .check_block

    ; Compute animation from current timer, THEN increment
    movzx   ecx, byte [attack_timer]

    cmp     al, 1                        ; WINDUP
    jne     .chk_swing

    ; WINDUP: swing_x = timer * 15  (0..60 with 4 frames)
    movzx   eax, cl
    imul    eax, 15
    cvtsi2ss xmm0, eax
    movss   [blade_swing_x], xmm0
    mov     dword [blade_y_mod], 0
    inc     cl
    mov     [attack_timer], cl
    cmp     cl, ATTACK_WINDUP
    jb      .combat_done
    mov     byte [attack_state], 2        ; advance to swing
    mov     byte [attack_timer], 0
    jmp     .combat_done

.chk_swing:
    cmp     al, 2                        ; SWING
    jne     .chk_recover

    ; SWING: swing_x = 60 - timer * 20  (60..-60 over 6 frames)
    movzx   eax, cl
    imul    eax, -20
    add     eax, 60
    cvtsi2ss xmm0, eax
    movss   [blade_swing_x], xmm0
    mov     dword [blade_y_mod], 0
    inc     cl
    mov     [attack_timer], cl
    cmp     cl, ATTACK_SWING
    jb      .combat_done
    mov     byte [attack_state], 3        ; advance to recovery
    mov     byte [attack_timer], 0
    jmp     .combat_done

.chk_recover:
    cmp     al, 3                        ; RECOVER
    jne     .attack_idle

    ; RECOVER: swing_x = -60 + timer * 10  (-60..0 over 6 frames)
    movzx   eax, cl
    imul    eax, 10
    sub     eax, 60
    cvtsi2ss xmm0, eax
    movss   [blade_swing_x], xmm0
    mov     dword [blade_y_mod], 0
    inc     cl
    mov     [attack_timer], cl
    cmp     cl, ATTACK_RECOVER
    jb      .combat_done
.attack_idle:
    mov     byte [attack_state], 0
    mov     byte [attack_timer], 0
    mov     dword [blade_swing_x], 0
    mov     dword [blade_y_mod], 0
    jmp     .combat_done

.check_block:
    ; ---- Block state machine ----
    movzx   eax, byte [block_state]
    test    eax, eax
    jz      .no_block

    movzx   ecx, byte [block_timer]

    cmp     al, 1                        ; RAISING
    jne     .chk_block_hold

    ; RAISING: y_mod = timer * 10, swing_x = timer * 10
    movzx   eax, cl
    imul    eax, 10
    cvtsi2ss xmm0, eax
    movss   [blade_y_mod], xmm0
    movzx   eax, cl
    imul    eax, 10
    cvtsi2ss xmm0, eax
    movss   [blade_swing_x], xmm0
    inc     cl
    mov     [block_timer], cl
    cmp     cl, BLOCK_RAISE_FRAMES
    jb      .combat_done
    mov     byte [block_state], 2        ; holding
    mov     byte [block_timer], 0
    mov     eax, BLOCK_Y_OFFSET
    cvtsi2ss xmm0, eax
    movss   [blade_y_mod], xmm0
    mov     eax, BLOCK_X_OFFSET
    cvtsi2ss xmm0, eax
    movss   [blade_swing_x], xmm0
    jmp     .combat_done

.chk_block_hold:
    cmp     al, 2                        ; HOLDING
    jne     .chk_block_release
    mov     eax, BLOCK_Y_OFFSET
    cvtsi2ss xmm0, eax
    movss   [blade_y_mod], xmm0
    mov     eax, BLOCK_X_OFFSET
    cvtsi2ss xmm0, eax
    movss   [blade_swing_x], xmm0
    jmp     .combat_done

.chk_block_release:
    cmp     al, 3                        ; RELEASING
    jne     .no_block

    movzx   eax, cl
    imul    eax, 8
    mov     ebx, BLOCK_Y_OFFSET
    sub     ebx, eax
    jns     .bry_ok
    xor     ebx, ebx
.bry_ok:
    cvtsi2ss xmm0, ebx
    movss   [blade_y_mod], xmm0
    movzx   eax, cl
    imul    eax, 8
    mov     ebx, BLOCK_X_OFFSET
    sub     ebx, eax
    jns     .brx_ok
    xor     ebx, ebx
.brx_ok:
    cvtsi2ss xmm0, ebx
    movss   [blade_swing_x], xmm0
    inc     cl
    mov     [block_timer], cl
    cmp     cl, 4
    jb      .combat_done
    mov     byte [block_state], 0
    mov     byte [block_timer], 0
    mov     dword [blade_y_mod], 0
    mov     dword [blade_swing_x], 0
    jmp     .combat_done

.no_block:
    mov     dword [blade_swing_x], 0
    mov     dword [blade_y_mod], 0

.combat_done:
    pop     rbx
    ret
