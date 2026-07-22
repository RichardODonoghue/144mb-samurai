section .text

; ============================================================
; render_floor -- textured floor casting
; Renders floor from wall_bottom[y] to SCR_H-1 per column
; Uses precomputed rowDistance LUT generated at init
; ============================================================
render_floor:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    push    rdi
    push    rsi
    sub     rsp, 38h

    ; Load player state
    movzx   eax, byte [player_angle]
    movss   xmm14, [player_x]
    movss   xmm15, [player_y]

    ; Compute left/right ray angles
    mov     ecx, eax
    sub     cl, FOV_HALF
    mov     edx, eax
    add     dl, FOV_HALF
    movzx   ecx, cl
    movzx   edx, dl

    ; leftDir and rightDir
    movss   xmm0, [cos_table + rcx*4]   ; leftDirX
    movss   xmm1, [sin_table + rcx*4]   ; leftDirY
    movss   xmm2, [cos_table + rdx*4]   ; rightDirX
    movss   xmm3, [sin_table + rdx*4]   ; rightDirY

    ; colStep = (rightDir - leftDir) / SCR_W
    movss   xmm4, xmm2
    subss   xmm4, xmm0
    movss   xmm5, xmm3
    subss   xmm5, xmm1
    mov     eax, SCR_W
    cvtsi2ss xmm6, eax
    divss   xmm4, xmm6                  ; colStepX
    divss   xmm5, xmm6                  ; colStepY

    ; Select floor texture based on player position
    cvttss2si eax, xmm14               ; int player_cell_x
    cvttss2si edx, xmm15               ; int player_cell_y
    cmp     eax, 0
    jl      .use_dirt
    cmp     eax, MAP_W - 1
    jg      .use_dirt
    cmp     edx, 0
    jl      .use_dirt
    cmp     edx, MAP_H - 1
    jg      .use_dirt
    imul    ecx, edx, MAP_W
    add     ecx, eax
    movzx   eax, byte [world_map + rcx]
    cmp     eax, 6
    jbe     .t_ok
.use_dirt:
    xor     eax, eax
.t_ok:
    movzx   ecx, byte [floortex_map + rax]  ; 0=dirt, 1=wood, 2=stone
    shl     ecx, 3                          ; *8 for qword table
    mov     r10, [floor_tex_table + rcx]    ; r10 = floor texture pointer

    ; Floor palette base: dirt=64, wood=160, stone=64 (dirt shares)
    cmp     eax, 3                          ; wood shop?
    je      .wood_floor
    cmp     eax, 2                          ; stone?
    je      .stone_floor
    mov     r14d, PAL_FLOOR_DIRT            ; dirt palette
    jmp     .pal_done
.wood_floor:
    mov     r14d, PAL_FLOOR_WOOD
    jmp     .pal_done
.stone_floor:
    mov     r14d, PAL_FLOOR_DIRT            ; stone shares dirt palette range
.pal_done:

    mov     r15, [g_bits]                   ; framebuffer
    lea     rbp, [wall_bottom]              ; per-column wall end

    ; Row loop: y = SCR_H/2 to SCR_H-1
    xor     r12d, r12d                      ; y_offset = 0 (y = 100 + y_offset)
    lea     rsi, [floor_gradient]           ; floor gradient LUT

.row_loop:
    cmp     r12d, SCR_H / 2
    jae     .floor_done

    ; rowDistance = 10.0 / (y - 100 + 0.001), precomputed in LUT or compute
    ; Use simple formula: rowDist = 100.0 / (r12d + 1)  (approximate, integer friendly)
    ; Actually use a LUT for rowDist as float
    mov     eax, r12d
    add     eax, 1
    mov     dword [rsp], 100
    cvtsi2ss xmm8, dword [rsp]             ; 100.0f
    cvtsi2ss xmm9, eax                     ; (y_offset + 1)
    divss   xmm8, xmm9                     ; rowDist

    ; Precompute row step: rowStepX = rowDist * colStepX, rowStepY = rowDist * colStepY
    movaps  xmm6, xmm4
    mulss   xmm6, xmm8
    movaps  xmm7, xmm5
    mulss   xmm7, xmm8

    ; floorX = playerX + rowDist * leftDirX
    movaps  xmm10, xmm0
    mulss   xmm10, xmm8
    addss   xmm10, xmm14
    ; floorY = playerY + rowDist * leftDirY
    movaps  xmm11, xmm1
    mulss   xmm11, xmm8
    addss   xmm11, xmm15

    ; Shade level from distance: shade = rowDist / 5.0 = rowDist * 0.2
    ; Approximate with fixed LUT or simple integer shift
    ; Use: shade = min(7, rowDist / 4) for quick distance shade
    cvttss2si r8d, xmm8                    ; int rowDist
    shr     r8d, 2                         ; rowDist / 4
    cmp     r8d, TEX_TEXEL_MASK
    jle     .sd_ok
    mov     r8d, TEX_TEXEL_MASK
.sd_ok:
    mov     r13d, r8d                      ; floor_shade in r13d

    ; Row y = 100 + y_offset
    mov     edi, r12d
    add     edi, SCR_H / 2                  ; edi = screen y

    ; Column loop
    xor     ebx, ebx                        ; column x
.col_loop:
    cmp     ebx, SCR_W
    jae     .row_next

    ; Check if this pixel is covered by a wall
    movzx   eax, word [rbp + rbx*2]        ; wall_bottom[col]
    cmp     edi, eax                       ; y vs wall_bottom
    jbe     .col_skip                      ; skip if y <= wall_bottom (wall covers)

    ; Compute tex coords
    ; texX = ((int)(floorX * 32)) & 31
    mov     eax, TEX_W
    cvtsi2ss xmm12, eax
    movaps  xmm0, xmm10
    mulss   xmm0, xmm12
    cvttss2si eax, xmm0
    and     eax, TEX_W - 1
    mov     r9d, eax                        ; texX

    ; texY = ((int)(floorY * 32)) & 31
    movaps  xmm0, xmm11
    mulss   xmm0, xmm12
    cvttss2si eax, xmm0
    and     eax, TEX_H - 1
    shl     eax, 5                          ; texY * TEX_W
    add     eax, r9d                        ; + texX

    ; Sample floor texture
    movzx   eax, byte [r10 + rax]           ; texel 0-7

    ; Apply distance shade
    sub     eax, r13d
    jns     .fs_ok
    xor     eax, eax
.fs_ok:

    ; Apply Y-side darkening for floor (chequer effect based on map cell)
    add     eax, r14d                       ; base palette

    ; Write pixel
    imul    ecx, edi, SCR_W
    add     ecx, ebx
    mov     byte [r15 + rcx], al

.col_skip:
    ; Advance floorX += rowStepX, floorY += rowStepY
    addss   xmm10, xmm6
    addss   xmm11, xmm7
    inc     ebx
    jmp     .col_loop

.row_next:
    inc     r12d
    jmp     .row_loop

.floor_done:
    add     rsp, 38h
    pop     rsi
    pop     rdi
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
