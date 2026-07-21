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
    jne     .skip_move

    ; Movement speed = base * delta_time * sprint_multiplier
    movss   xmm0, [move_speed]

    ; Sprint: hold Shift for 2x speed
    mov     ecx, VK_SHIFT
    call    GetAsyncKeyState
    test    ax, ax
    jns     .no_sprint
    addss   xmm0, xmm0
.no_sprint:

    ; Delta time (~1/70 sec at vsync)
    mov     dword [rsp], 0x3C75C28F
    mulss   xmm0, [rsp]

    ; Lookup direction from player angle
    movzx   eax, byte [player_angle]
    movss   xmm1, [cos_table + rax*4]
    movss   xmm2, [sin_table + rax*4]

    ; Default: no movement
    xorps   xmm3, xmm3
    xorps   xmm4, xmm4

    ; W key
    mov     ecx, VK_W
    call    GetAsyncKeyState
    test    ax, ax
    jns     .not_w
    movaps  xmm3, xmm1
    movaps  xmm4, xmm2
.not_w:

    ; S key
    mov     ecx, VK_S
    call    GetAsyncKeyState
    test    ax, ax
    jns     .not_s
    subss   xmm3, xmm1
    subss   xmm4, xmm2
.not_s:

    ; D key (strafe right)
    mov     ecx, VK_D
    call    GetAsyncKeyState
    test    ax, ax
    jns     .not_d
    addss   xmm3, xmm2
    subss   xmm4, xmm1
.not_d:

    ; A key (strafe left)
    mov     ecx, VK_A
    call    GetAsyncKeyState
    test    ax, ax
    jns     .not_a
    subss   xmm3, xmm2
    addss   xmm4, xmm1
.not_a:

    ; Scale by speed and time delta
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
    cmp     eax, MAP_W - 1
    jge     .skip_x
    cmp     ecx, 0
    jl      .skip_x
    cmp     ecx, MAP_H - 1
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
    cmp     eax, MAP_W - 1
    jge     .skip_y
    cmp     ecx, 0
    jl      .skip_y
    cmp     ecx, MAP_H - 1
    jge     .skip_y
    imul    edx, ecx, MAP_W
    add     edx, eax
    cmp     byte [world_map + rdx], 0
    jne     .skip_y

    movss   [player_y], xmm6
.skip_y:

    ; Mouse look: relative delta from previous position
    lea     rcx, [rsp + 20h]
    call    GetCursorPos

    mov     eax, [rsp + 20h]    ; screen x
    mov     ecx, eax            ; cur_x
    sub     eax, [prev_mouse_x] ; delta_x
    mov     [rsp + 40h], eax    ; save delta immediately

    ; First frame init
    cmp     byte [mouse_init], 0
    jne     .mouse_ok
    mov     byte [mouse_init], 1
    mov     dword [rsp + 40h], 0  ; no delta on first frame
.mouse_ok:
    mov     [prev_mouse_x], ecx ; update prev_x
    mov     eax, [rsp + 24h]
    mov     [prev_mouse_y], eax ; update prev_y

    ; Apply rotation from mouse delta
    cvtsi2ss xmm0, dword [rsp + 40h]
    mulss   xmm0, [mouse_sens]
    addss   xmm0, [player_angle_f]
    movss   [player_angle_f], xmm0
    cvttss2si eax, xmm0
    mov     [player_angle], al

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
