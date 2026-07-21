section .text

; ============================================================
; process_input -- poll keys / mouse, update player state
; ============================================================
process_input:
    push    rbx
    push    rdi
    sub     rsp, 48h

    ; Check pause toggle (edge-triggered)
    mov     ecx, VK_ESCAPE
    call    GetAsyncKeyState
    test    ax, ax
    jns     .esc_up
    cmp     byte [prev_escape], 0
    jne     .not_paused
    xor     byte [player_paused], 1
    mov     byte [prev_escape], 1
    jmp     .not_paused
.esc_up:
    mov     byte [prev_escape], 0
.not_paused:
    cmp     byte [player_paused], 0
    jne     .paused

    ; Lookup direction from player angle
    movzx   eax, byte [player_angle]
    movss   xmm1, [cos_table + rax*4]
    movss   xmm2, [sin_table + rax*4]

    ; Save direction and speed (API calls clobber xmm0-xmm5)
    movss   [rsp + 20h], xmm1
    movss   [rsp + 24h], xmm2
    movss   xmm0, [move_speed]
    movss   [rsp + 28h], xmm0

    ; Default: no movement
    xorps   xmm3, xmm3
    xorps   xmm4, xmm4

    ; W key
    cmp     byte [key_states + VK_W], 0
    je      .not_w
    movss   xmm1, [rsp + 20h]
    movss   xmm2, [rsp + 24h]
    movaps  xmm3, xmm1
    movaps  xmm4, xmm2
.not_w:

    ; S key
    cmp     byte [key_states + VK_S], 0
    je      .not_s
    movss   xmm1, [rsp + 20h]
    movss   xmm2, [rsp + 24h]
    subss   xmm3, xmm1
    subss   xmm4, xmm2
.not_s:

    ; D key (strafe right)
    cmp     byte [key_states + VK_D], 0
    je      .not_d
    movss   xmm1, [rsp + 20h]
    movss   xmm2, [rsp + 24h]
    subss   xmm3, xmm2
    addss   xmm4, xmm1
.not_d:

    ; A key (strafe left)
    cmp     byte [key_states + VK_A], 0
    je      .not_a
    movss   xmm1, [rsp + 20h]
    movss   xmm2, [rsp + 24h]
    addss   xmm3, xmm2
    subss   xmm4, xmm1
.not_a:

    ; Compute speed AFTER all key polling (avoids XMM clobber)
    movss   xmm0, [rsp + 28h]        ; move_speed

    ; Sprint check
    cmp     byte [key_states + VK_SHIFT], 0
    je      .no_sprint
    movss   xmm0, [rsp + 28h]        ; reload move_speed
    addss   xmm0, xmm0               ; 2x
    jmp     .speed_done
.no_sprint:
    movss   xmm0, [rsp + 28h]        ; reload move_speed
.speed_done:

    ; Delta time
    mov     dword [rsp], 0x3C75C28F   ; ~0.015
    mulss   xmm0, [rsp]

    ; Scale movement by speed
    mulss   xmm3, xmm0
    mulss   xmm4, xmm0

    ; Apply movement (with collision check)
    ; Check new X position
    movss   xmm5, [player_x]
    addss   xmm5, xmm3
    ; Collision: check if new position is in a wall
    cvttss2si eax, xmm5
    movss   xmm6, [player_y]
    cvttss2si ecx, xmm6

    ; bounds check + map check
    cmp     eax, 0
    jl      .skip_x
    cmp     eax, MAP_W
    jge     .skip_x
    cmp     ecx, 0
    jl      .skip_x
    cmp     ecx, MAP_H
    jge     .skip_x
    imul    edx, ecx, MAP_W
    add     edx, eax
    cmp     byte [world_map + rdx], 0
    jne     .skip_x

    ; Move X is valid
    movss   [player_x], xmm5
.skip_x:

    ; Check new Y position
    movss   xmm5, [player_x]             ; reload (it may have changed)
    movss   xmm6, [player_y]
    addss   xmm6, xmm4
    cvttss2si eax, xmm5
    cvttss2si ecx, xmm6

    cmp     eax, 0
    jl      .skip_y
    cmp     eax, MAP_W
    jge     .skip_y
    cmp     ecx, 0
    jl      .skip_y
    cmp     ecx, MAP_H
    jge     .skip_y
    imul    edx, ecx, MAP_W
    add     edx, eax
    cmp     byte [world_map + rdx], 0
    jne     .skip_y

    movss   [player_y], xmm6
.skip_y:

    ; Mouse look: relative delta from previous position
    lea     rcx, [rsp + 30h]
    call    GetCursorPos

    mov     eax, [rsp + 30h]    ; screen x
    mov     ecx, eax            ; cur_x
    sub     eax, [prev_mouse_x] ; delta_x
    ; Dead zone: ignore deltas below 5 pixels
    cmp     eax, 5
    jge     .cap_check
    cmp     eax, -5
    jle     .cap_check
    xor     eax, eax
    jmp     .delta_done
.cap_check:
    ; Cap delta to [-15, +15] per frame
    cmp     eax, 15
    jle     .clamp_low
    mov     eax, 15
    jmp     .delta_done
.clamp_low:
    cmp     eax, -15
    jge     .delta_done
    mov     eax, -15
.delta_done:
    mov     [rsp + 38h], eax    ; save delta

    ; First frame init
    cmp     byte [mouse_init], 0
    jne     .mouse_ok
    mov     byte [mouse_init], 1
    mov     dword [rsp + 38h], 0  ; no delta on first frame
.mouse_ok:
    ; Apply rotation from mouse delta
    cvtsi2ss xmm0, dword [rsp + 38h]
    mulss   xmm0, [mouse_sens]
    addss   xmm0, [player_angle_f]
    movss   [player_angle_f], xmm0
    cvttss2si eax, xmm0
    mov     [player_angle], al

    jmp     .recenter

.paused:
    ; Still get cursor pos for recenter when paused
    lea     rcx, [rsp + 30h]
    call    GetCursorPos

.recenter:
    ; Lock cursor to window center
    mov     rcx, [g_hwnd]
    lea     rdx, [rsp + 20h]        ; RECT
    call    GetClientRect
    mov     eax, [rsp + 20h + 8]    ; right
    sub     eax, [rsp + 20h + 0]    ; right - left
    sar     eax, 1
    add     eax, [rsp + 20h + 0]    ; + left
    mov     [rsp + 30h], eax        ; pt.x
    mov     eax, [rsp + 20h + 12]   ; bottom
    sub     eax, [rsp + 20h + 4]    ; bottom - top
    sar     eax, 1
    add     eax, [rsp + 20h + 4]    ; + top
    mov     [rsp + 34h], eax        ; pt.y
    mov     rcx, [g_hwnd]
    lea     rdx, [rsp + 30h]        ; POINT
    call    ClientToScreen
    mov     ecx, [rsp + 30h]
    mov     edx, [rsp + 34h]
    call    SetCursorPos
    mov     eax, [rsp + 30h]
    mov     [prev_mouse_x], eax
    mov     eax, [rsp + 34h]
    mov     [prev_mouse_y], eax

.skip_move:
    ; Check mouse buttons (for future attack/block)
    ; Left button
    mov     ecx, VK_LBUTTON
    call    GetAsyncKeyState
    test    ax, ax
    jns     .not_lclick
    ; attack action (placeholder)
.not_lclick:

    ; Right button
    mov     ecx, VK_RBUTTON
    call    GetAsyncKeyState
    test    ax, ax
    jns     .not_rclick
    ; block action (placeholder)
.not_rclick:

    add     rsp, 48h
    pop     rdi
    pop     rbx
    ret
