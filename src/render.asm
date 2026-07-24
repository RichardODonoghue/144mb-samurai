section .text

; ============================================================
; render_frame -- raycast into g_bits framebuffer
; Uses SSE2 floats, precomputed sin/cos tables
; ============================================================
render_frame:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    push    rdi
    push    rsi
    push    rbp
    sub     rsp, 38h

    ; ---- Gradient clear: sky per-row gradient (y=0..99) ----
    lea     rsi, [sky_gradient]
    mov     rdi, [g_bits]
    test    rdi, rdi
    jz      .done
    xor     edx, edx               ; y = 0
.sky_clear:
    cmp     edx, SCR_H / 2
    jae     .floor_clear
    mov     al, [rsi + rdx]
    mov     ecx, SCR_W
    rep     stosb
    inc     edx
    jmp     .sky_clear

    ; ---- Gradient clear: floor per-row gradient (y=100..199) ----
.floor_clear:
    cmp     edx, SCR_H
    jae     .clear_done
    mov     eax, edx
    sub     eax, SCR_H / 2
    mov     al, [floor_gradient + rax]
    mov     ecx, SCR_W
    rep     stosb
    inc     edx
    jmp     .floor_clear
.clear_done:

    ; ---- Load player state ----
    movzx   eax, byte [player_angle]
    movss   xmm14, [player_x]
    movss   xmm15, [player_y]

    ; Compute left/right ray angles
    mov     ecx, eax
    sub     cl, FOV_HALF               ; left  = player - FOV/2
    mov     edx, eax
    add     dl, FOV_HALF               ; right = player + FOV/2

    ; Look up directions from sin/cos tables
    movzx   ecx, cl
    movss   xmm0, [cos_table + rcx*4]  ; cosLeft
    movss   xmm1, [sin_table + rcx*4]  ; sinLeft
    movzx   edx, dl
    movss   xmm2, [cos_table + rdx*4]  ; cosRight
    movss   xmm3, [sin_table + rdx*4]  ; sinRight

    ; Compute per-column step: (rightDir - leftDir) / SCR_W
    movss   xmm4, xmm2
    subss   xmm4, xmm0                 ; cosRight - cosLeft
    movss   xmm5, xmm3
    subss   xmm5, xmm1                 ; sinRight - sinLeft
    mov     eax, SCR_W
    cvtsi2ss xmm6, eax                 ; xmm6 = (float)SCR_W
    movss   xmm7, [float_one]
    divss   xmm7, xmm6                 ; 1.0 / SCR_W
    mulss   xmm4, xmm7                 ; stepX
    mulss   xmm5, xmm7                 ; stepY

    ; Current ray direction starts at leftmost
    movaps  xmm6, xmm0                 ; rayDirX
    movaps  xmm7, xmm1                 ; rayDirY

    xor     r12d, r12d                 ; column = 0
    mov     r15, [g_bits]              ; framebuffer base
    lea     rbp, [wall_bottom]         ; per-column wall end buffer

.col_loop:
    cmp     r12d, SCR_W
    jae     .post_draw

    ; Save rayDir for this column
    movaps  xmm10, xmm6                ; rayDirX
    movaps  xmm11, xmm7                ; rayDirY

    ; --- DDA Setup ---
    cvttss2si eax, xmm14               ; eax = mapX
    cvttss2si edx, xmm15               ; edx = mapY

    ; deltaDist = fabs(1/rayDir)
    movss   xmm8, [float_one]
    divss   xmm8, xmm10                ; deltaDistX = 1/rayDirX
    movss   xmm9, [float_one]
    divss   xmm9, xmm11                ; deltaDistY = 1/rayDirY

    ; Absolute values
    movd    r8d, xmm8
    movd    r9d, xmm9
    and     r8d, 7FFFFFFFh
    and     r9d, 7FFFFFFFh
    movd    xmm8, r8d                  ; deltaDistX = abs
    movd    xmm9, r9d                  ; deltaDistY = abs

    ; Step direction and initial sideDist
    pxor    xmm12, xmm12
    comiss  xmm10, xmm12
    jb      .sx_neg
    mov     r13d, 1                     ; stepX = 1
    cvtsi2ss xmm0, eax
    addss   xmm0, [float_one]
    subss   xmm0, xmm14
    mulss   xmm0, xmm8
    movaps  xmm2, xmm0                 ; sideDistX
    jmp     .sy_calc
.sx_neg:
    mov     r13d, -1                    ; stepX = -1
    movss   xmm0, xmm14
    cvtsi2ss xmm1, eax
    subss   xmm0, xmm1
    mulss   xmm0, xmm8
    movaps  xmm2, xmm0                 ; sideDistX

.sy_calc:
    pxor    xmm12, xmm12
    comiss  xmm11, xmm12
    jb      .sy_neg
    mov     r14d, 1                     ; stepY = 1
    cvtsi2ss xmm0, edx
    addss   xmm0, [float_one]
    subss   xmm0, xmm15
    mulss   xmm0, xmm9
    movaps  xmm3, xmm0                 ; sideDistY
    jmp     .dda_start
.sy_neg:
    mov     r14d, -1                    ; stepY = -1
    movss   xmm0, xmm15
    cvtsi2ss xmm1, edx
    subss   xmm0, xmm1
    mulss   xmm0, xmm9
    movaps  xmm3, xmm0                 ; sideDistY

    ; --- DDA Loop ---
.dda_start:
    xor     ebx, ebx                   ; side flag
    xor     ecx, ecx                   ; step counter

.dda_loop:
    inc     ecx
    cmp     ecx, MAX_DEPTH
    jae     .no_hit

    comiss  xmm2, xmm3                ; compare sideDist
    jb      .step_x
.step_y:
    addss   xmm3, xmm9
    add     edx, r14d
    mov     ebx, 1
    jmp     .check
.step_x:
    addss   xmm2, xmm8
    add     eax, r13d
    xor     ebx, ebx

.check:
    cmp     eax, 0
    jl      .no_hit
    cmp     eax, MAP_W
    jge     .no_hit
    cmp     edx, 0
    jl      .no_hit
    cmp     edx, MAP_H
    jge     .no_hit

    imul    edi, edx, MAP_W
    add     edi, eax
    movzx   edi, byte [world_map + rdi]
    test    edi, edi
    jz      .dda_loop

    ; Save wall type on stack (r13 used for stepX in perp calc below)
    mov     [rsp + 16], edi

    ; --- Wall hit: calculate perpWallDist ---
    test    ebx, ebx
    jnz     .perp_y
.perp_x:
    cvtsi2ss xmm0, eax
    subss   xmm0, xmm14
    mov     eax, 1
    sub     eax, r13d                   ; uses stepX
    cvtsi2ss xmm1, eax
    mov     dword [rsp], 0x3F000000   ; 0.5f
    mulss   xmm1, [rsp]
    addss   xmm0, xmm1
    divss   xmm0, xmm10               ; perpWallDist
    jmp     .wall_draw
.perp_y:
    cvtsi2ss xmm0, edx
    subss   xmm0, xmm15
    mov     edx, 1
    sub     edx, r14d                   ; uses stepY
    cvtsi2ss xmm1, edx
    mov     dword [rsp], 0x3F000000
    mulss   xmm1, [rsp]
    addss   xmm0, xmm1
    divss   xmm0, xmm11               ; perpWallDist

    ; --- Compute distance bucket for shading ---
.wall_draw:
    mov     r13d, [rsp + 16]            ; wall_type (now safe, perp calc done)

    ; xmm0 = perpWallDist
    cvttss2si r9d, xmm0               ; int distance
    cmp     r9d, MAX_DIST_BUCKET
    jle     .db_ok
    mov     r9d, MAX_DIST_BUCKET
.db_ok:
    mov     [rsp + 4], r9d             ; save distance bucket (for fog check)
    movzx   r8d, byte [shade_table + r9d]  ; shade_offset 0-7

    ; --- Compute lineHeight, drawStart, drawEnd ---
    mov     dword [rsp], SCR_H
    cvtsi2ss xmm1, dword [rsp]
    divss   xmm1, xmm0                ; lineHeight
    cvttss2si eax, xmm1
    mov     [rsp + 8], eax             ; save lineHeight for step calc

    ; drawStart = -lineHeight/2 + SCR_H/2
    mov     edx, eax
    neg     edx
    sar     edx, 1
    add     edx, SCR_H / 2
    cmp     edx, 0
    jge     .ds_ok
    xor     edx, edx
.ds_ok:
    mov     esi, edx                    ; drawStart in esi

    ; drawEnd = lineHeight/2 + SCR_H/2
    mov     edx, eax
    sar     edx, 1
    add     edx, SCR_H / 2
    cmp     edx, SCR_H - 1
    jle     .de_ok
    mov     edx, SCR_H - 1
.de_ok:
    mov     edi, edx                    ; drawEnd in edi
    mov     word [rbp + r12*2], dx     ; store for floor casting

    ; Save side flag
    mov     r14d, ebx

    ; wallX = fractional hit position
    test    ebx, ebx
    jnz     .wx_y
    movaps  xmm1, xmm0
    mulss   xmm1, xmm11
    addss   xmm1, xmm15
    jmp     .wx_done
.wx_y:
    movaps  xmm1, xmm0
    mulss   xmm1, xmm10
    addss   xmm1, xmm14
.wx_done:
    cvttss2si eax, xmm1
    cvtsi2ss xmm2, eax
    subss   xmm1, xmm2
    mov     eax, TEX_W
    cvtsi2ss xmm2, eax
    mulss   xmm1, xmm2
    cvttss2si r11d, xmm1               ; texX (0..31)
    and     r11d, TEX_W - 1

    ; Base palette = PAL_WALL_BASE + (type-1) * PAL_WALL_STRIDE
    mov     r9d, r13d
    dec     r9d
    imul    r9d, r9d, PAL_WALL_STRIDE
    add     r9d, PAL_WALL_BASE

    ; Select texture pointer by wall type
    mov     eax, r13d
    movzx   r10d, byte [tex_type_map + rax - 1]
    imul    r10d, TEX_SIZE
    lea     r10, [tex_brick + r10]

    ; Texture step (16.16 fixed): TEX_H<<16 / lineHeight
    mov     eax, TEX_H << 16
    xor     edx, edx
    div     dword [rsp + 8]            ; lineHeight
    mov     ebx, eax                   ; step in ebx

    ; texPos accumulator
    xor     edx, edx
    mov     [rsp + 12], esi            ; save drawStart for roof rendering

.draw_col:
    cmp     esi, edi                   ; drawStart vs drawEnd
    jg      .post_wall
    mov     eax, edx
    shr     eax, 16                    ; texY
    and     eax, TEX_H - 1
    shl     eax, 5                     ; texY * TEX_W
    add     eax, r11d                  ; + texX
    movzx   eax, byte [r10 + rax]      ; texel (0-7)

    ; Apply distance shade: texel = max(0, texel - shade_offset)
    sub     eax, r8d
    jns     .ts_ok
    xor     eax, eax
.ts_ok:

    ; Fog: if distance bucket >= FOG_BEGIN, force to fog color
    cmp     dword [rsp + 4], FOG_BEGIN
    jb      .no_fog
    mov     eax, [rsp + 4]
    sub     eax, FOG_BEGIN
    shr     eax, 1                     ; 0..15 fog level
    add     eax, PAL_FOG_START
    jmp     .store_pixel
.no_fog:

    ; Add base palette
    add     eax, r9d

    ; Y-side darkening
    test    r14d, r14d
    jz      .store_pixel
    add     eax, TEX_SIDE_SHIFT

.store_pixel:
    imul    ecx, esi, SCR_W
    add     ecx, r12d
    mov     byte [r15 + rcx], al
    add     edx, ebx                   ; texPos += step
    inc     esi
    jmp     .draw_col

.post_wall:
    ; ================================================================
    ; ROOF RENDERING: Japanese curved tile roof above building walls
    ; Uses tiled tex_roof texture (32x32, direct palette indices)
    ; ================================================================
    cmp     r13d, 2                    ; stone (castle wall) = no roof
    je      .foundation
    cmp     r13d, 6                    ; fire = no roof
    je      .foundation

    ; Skip roof for distant walls (looks wrong if roof is huge vs wall)
    cmp     dword [rsp + 4], ROOF_DIST_LIMIT
    ja      .foundation

    ; Compute roof height: roof_profile[wallX] * roof_type_height[type-1] / MAX_ROOF_H
    movzx   eax, byte [roof_profile + r11d]   ; base profile height (0..~20)
    movzx   ecx, byte [roof_type_height + r13d - 1]
    mul     ecx
    mov     ecx, MAX_ROOF_H
    xor     edx, edx
    div     ecx                               ; eax = roofH in rows
    test    eax, eax
    jz      .foundation

    mov     r8d, eax                          ; roofH (rows)

    ; Roof start = drawStart - roofH
    mov     ecx, [rsp + 12]                   ; drawStart
    sub     ecx, r8d                          ; roofStart

.roof_row:
    cmp     ecx, [rsp + 12]                   ; reached drawStart?
    jae     .foundation
    cmp     ecx, 0
    jl      .roof_skip_row                    ; off-screen above

    imul    edx, ecx, SCR_W
    add     edx, r12d                         ; pixel offset = y*SCR_W + col

    ; Distance from roof bottom = drawStart - currentY
    mov     eax, [rsp + 12]
    sub     eax, ecx

    ; Bottom 2 rows = eave shadow
    cmp     eax, 2
    jae     .roof_tile
    mov     al, PAL_ROOF_EAVE
    jmp     .roof_store

.roof_tile:
    ; Eave curl highlight at extreme edges
    cmp     r11d, 4
    jae     .chk_curl_r
    mov     al, PAL_EAVE_CURL                ; left curled eave corner
    jmp     .roof_store
.chk_curl_r:
    cmp     r11d, 28
    jb      .roof_sample
    mov     al, PAL_EAVE_CURL                ; right curled eave corner
    jmp     .roof_store

.roof_sample:
    ; Tile tex_roof: tex_x = wallX & 31, tex_y = (drawStart - row) & 31
    mov     eax, [rsp + 12]                  ; drawStart
    sub     eax, ecx                         ; row from roof top
    and     eax, 31                          ; tex_y
    shl     eax, 5                           ; tex_y * 32
    add     eax, r11d                        ; + tex_x (wallX)
    movzx   eax, byte [tex_roof + rax]       ; read tile pixel

.roof_store:
    mov     byte [r15 + rdx], al

.roof_skip_row:
    inc     ecx
    jmp     .roof_row

.foundation:
    ; ================================================================
    ; FOUNDATION BAND: tiled stone texture at bottom of building walls
    ; Uses tex_foundation (32x8, direct palette indices)
    ; ================================================================
    cmp     r13d, 2                    ; stone walls = no foundation band
    je      .next_col
    cmp     r13d, 6                    ; fire walls = no foundation
    je      .next_col
    cmp     edi, SCR_H / 2             ; only if wall extends below horizon
    jl      .next_col

    ; Foundation: overwrite bottom FOUNDATION_ROWS of the wall
    mov     ecx, edi
    sub     ecx, FOUNDATION_ROWS - 1       ; start near bottom
    cmp     ecx, 0
    jge     .found_adj
    xor     ecx, ecx
.found_adj:
.found_row:
    cmp     ecx, edi                    ; up to drawEnd inclusive
    jg      .next_col
    cmp     ecx, 0
    jl      .found_next
    imul    edx, ecx, SCR_W
    add     edx, r12d                   ; pixel offset = y*SCR_W + col

    ; Tile tex_foundation: tex_x = wallX & 31, tex_y = (drawEnd - row) & 7
    mov     eax, edi                    ; drawEnd
    sub     eax, ecx                    ; rows from bottom
    and     eax, 7                      ; tex_y (0..7)
    shl     eax, 5                      ; tex_y * 32
    add     eax, r11d                   ; + tex_x (wallX, 0..31)
    movzx   eax, byte [tex_foundation + rax]
    mov     byte [r15 + rdx], al

.found_next:
    inc     ecx
    jmp     .found_row

.next_col:
    addss   xmm6, xmm4                 ; rayDirX += stepX
    addss   xmm7, xmm5                 ; rayDirY += stepY
    inc     r12d
    jmp     .col_loop

.no_hit:
    ; No wall hit: store 0 as drawEnd (floor renders from SCR_H/2)
    mov     word [rbp + r12*2], 0
    jmp     .next_col

    ; ---- Post-draw: floor, particles, weapon, HUD, vignette ----
.post_draw:
    call    render_floor
    call    draw_particles
    call    draw_weapon
    call    draw_hud
    call    apply_vignette

.done:
    add     rsp, 38h
    pop     rbp
    pop     rsi
    pop     rdi
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ================================================================
; apply_vignette -- post-process vignette using precomputed LUT
; ================================================================
apply_vignette:
    lea     rsi, [vignette_mask]
    mov     rdi, [g_bits]
    test    rdi, rdi
    jz      .vig_done
    lea     rbx, [vignette_lut]
    mov     ecx, SCR_W * SCR_H
.vig_loop:
    movzx   eax, byte [rsi]        ; vignette mask value (0=no, 1=apply)
    test    al, al
    jz      .vig_next
    movzx   eax, byte [rdi]        ; current pixel
    mov     al, [rbx + rax]        ; lookup dimmed version
    mov     [rdi], al
.vig_next:
    inc     rsi
    inc     rdi
    dec     ecx
    jnz     .vig_loop
.vig_done:
    ret
