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
    ; Checkerboard tile pattern: (col + row) & 1
    lea     eax, [ecx + r12d]
    and     eax, 1
    add     eax, PAL_ROOF_TILE_1              ; 248 or 249

    ; Eave curl highlight: near wallX edges (0-3 or 28-31)
    cmp     r11d, 4
    jae     .chk_curl_r
    mov     eax, PAL_EAVE_CURL                ; left curled eave corner
    jmp     .roof_store
.chk_curl_r:
    cmp     r11d, 28
    jb      .roof_store
    mov     eax, PAL_EAVE_CURL                ; right curled eave corner

.roof_store:
    mov     byte [r15 + rdx], al

.roof_skip_row:
    inc     ecx
    jmp     .roof_row

.foundation:
    ; ================================================================
    ; FOUNDATION BAND: dark stone band at bottom of building walls
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
    add     edx, r12d
    mov     byte [r15 + rdx], PAL_FOUNDATION
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

    ; ---- Post-draw: floor, particles, weapon, vignette ----
.post_draw:
    call    render_floor
    call    draw_particles
    call    draw_katana
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
; draw_katana -- curved katana weapon overlay
; (extracted from old render_frame end section)
; ================================================================
draw_katana:
    ; Load animation globals
    movss   xmm12, [blade_swing_x]   ; X offset
    cvttss2si r12d, [blade_y_mod]    ; integer Y offset
    cvttss2si r13d, xmm12            ; integer X offset

    ; Blade: Y=22..125, spine 135→185, edge 143→210, dy=103
    mov     eax, 22
    cvtsi2ss xmm0, eax               ; y_start
    mov     ecx, 22                  ; y int
    mov     eax, 103
    cvtsi2ss xmm1, eax               ; dy
    movss   xmm10, [float_one]
    divss   xmm10, xmm1              ; inv_dy
    mov     eax, 50
    cvtsi2ss xmm2, eax               ; dxl=185-135
    mov     eax, 67
    cvtsi2ss xmm3, eax               ; dxr=210-143
    mov     eax, 135
    cvtsi2ss xmm4, eax               ; xl_base
    mov     eax, 143
    cvtsi2ss xmm5, eax               ; xr_base
    mov     eax, -28
    cvtsi2ss xmm6, eax               ; spine_curve
    mov     eax, -8
    cvtsi2ss xmm7, eax               ; edge_curve
    mov     eax, -22
    cvtsi2ss xmm8, eax
    addss   xmm8, xmm0               ; y_offset=0

    ; ---- Apply combat animation offsets (blade only) ----
    movss   xmm12, [blade_swing_x]   ; X offset for swing/block
    movss   xmm13, [blade_y_mod]     ; Y offset for block
    movss   xmm14, [blade_width_mod] ; width mult (0=uninit → ignore)

    ; Check if width_mod is valid (not zero)
    pxor    xmm15, xmm15
    comiss  xmm14, xmm15
    jbe     .no_width_mod
    mulss   xmm2, xmm14              ; dxl *= width_mod
    mulss   xmm3, xmm14              ; dxr *= width_mod
.no_width_mod:
    addss   xmm4, xmm12              ; xl_base += swing_x
    addss   xmm5, xmm12              ; xr_base += swing_x
    addss   xmm0, xmm13              ; y_start += y_mod

    ; Recompute y_offset with shifted y_start
    mov     eax, -22
    cvtsi2ss xmm8, eax
    addss   xmm8, xmm0               ; y_offset = y_start-22

.blade_loop:
    cmp     ecx, 125
    jg      .blade_done
    movaps  xmm9, xmm8
    mulss   xmm9, xmm10              ; t
    movaps  xmm12, xmm9
    mulss   xmm12, xmm9              ; t*t
    movaps  xmm11, xmm9
    subss   xmm11, xmm12             ; curve_f = t-t^2
    ; spine_x
    movaps  xmm13, xmm9
    mulss   xmm13, xmm2
    addss   xmm13, xmm4
    movaps  xmm14, xmm11
    mulss   xmm14, xmm6
    addss   xmm13, xmm14
    cvttss2si r8d, xmm13
    ; edge_x
    movaps  xmm14, xmm9
    mulss   xmm14, xmm3
    addss   xmm14, xmm5
    movaps  xmm15, xmm11
    mulss   xmm15, xmm7
    addss   xmm14, xmm15
    cvttss2si r9d, xmm14
    cmp     r8d, 0
    jge     .bxl
    xor     r8d, r8d
.bxl:
    cmp     r9d, SCR_W - 1
    jle     .bxr
    mov     r9d, SCR_W - 1
.bxr:
    imul    r10d, ecx, SCR_W
    mov     eax, r8d
.bifill:
    cmp     eax, r9d
    jg      .biedge
    mov     edx, r10d
    add     edx, eax
    mov     byte [r15 + rdx], PAL_WEAPON_BLADE
    inc     eax
    jmp     .bifill
.biedge:
    mov     eax, r9d
    sub     eax, 1
    cmp     eax, r8d
    jl      .bnext
    add     eax, r10d
    mov     byte [r15 + rax], PAL_WEAPON_SHINE
    mov     eax, r9d
    sub     eax, 2
    cmp     eax, r8d
    jl      .bnext
    add     eax, r10d
    mov     byte [r15 + rax], PAL_WEAPON_SHINE
.bnext:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .blade_loop

.blade_done:
    ; Tsuba angled: Y=125→128, X=185→178 (L), X=210→218 (R)
    mov     ecx, 125
    mov     eax, 125
    cvtsi2ss xmm0, eax
    mov     eax, 3
    cvtsi2ss xmm1, eax               ; dy=3
    mov     eax, -7
    cvtsi2ss xmm2, eax
    divss   xmm2, xmm1               ; slopeL = -7/3
    mov     eax, 8
    cvtsi2ss xmm3, eax
    divss   xmm3, xmm1               ; slopeR = 8/3
    mov     eax, 185
    cvtsi2ss xmm4, eax
    mov     eax, 210
    cvtsi2ss xmm5, eax
    mov     eax, -125
    cvtsi2ss xmm8, eax
    addss   xmm8, xmm0
.tsuba_loop:
    cmp     ecx, 128
    jg      .tsuba_done
    movaps  xmm9, xmm8
    mulss   xmm9, xmm2
    addss   xmm9, xmm4
    cvttss2si r8d, xmm9
    movaps  xmm9, xmm8
    mulss   xmm9, xmm3
    addss   xmm9, xmm5
    cvttss2si r9d, xmm9
    add     r8d, r13d                ; X shift
    add     r9d, r13d
    cmp     r8d, 0
    jge     .tx
    xor     r8d, r8d
.tx:
    cmp     r9d, SCR_W - 1
    jle     .ty
    mov     r9d, SCR_W - 1
.ty:
    lea     edx, [ecx + r12d]       ; Y shift
    imul    r10d, edx, SCR_W
    mov     eax, r8d
.tsfill:
    cmp     eax, r9d
    jg      .tsnxt
    mov     edx, r10d
    add     edx, eax
    mov     byte [r15 + rdx], PAL_WEAPON_TSUBA
    inc     eax
    jmp     .tsfill
.tsnxt:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .tsuba_loop

.tsuba_done:
    ; Handle Y=128..170  XL=180→186  XR=210→215
    mov     ecx, 128
    mov     eax, 128
    cvtsi2ss xmm0, eax
    mov     eax, 42
    cvtsi2ss xmm1, eax
    mov     eax, 6
    cvtsi2ss xmm2, eax
    divss   xmm2, xmm1
    mov     eax, 5
    cvtsi2ss xmm3, eax
    divss   xmm3, xmm1
    mov     eax, 180
    cvtsi2ss xmm4, eax
    mov     eax, 210
    cvtsi2ss xmm5, eax
    mov     eax, -128
    cvtsi2ss xmm8, eax
    addss   xmm8, xmm0
.hloop:
    cmp     ecx, 170
    jg      .hdl_done
    movaps  xmm9, xmm8
    mulss   xmm9, xmm2
    addss   xmm9, xmm4
    cvttss2si r8d, xmm9
    movaps  xmm9, xmm8
    mulss   xmm9, xmm3
    addss   xmm9, xmm5
    cvttss2si r9d, xmm9
    add     r8d, r13d                ; X shift
    add     r9d, r13d
    cmp     r8d, 0
    jge     .hxl
    xor     r8d, r8d
.hxl:
    cmp     r9d, SCR_W - 1
    jle     .hxr
    mov     r9d, SCR_W - 1
.hxr:
    lea     edx, [ecx + r12d]       ; Y shift
    imul    r10d, edx, SCR_W
    mov     eax, r8d
.hdl_fill:
    cmp     eax, r9d
    jg      .hdl_next
    mov     edx, r10d
    add     edx, eax
    test    ecx, 2
    jz      .hcol
    mov     byte [r15 + rdx], PAL_WEAPON_TSUBA
    jmp     .hcol_ok
.hcol:
    mov     byte [r15 + rdx], PAL_WEAPON_WRAP
.hcol_ok:
    inc     eax
    jmp     .hdl_fill
.hdl_next:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .hloop

.hdl_done:
    ; Right arm Y=115..135  XL=210→192  XR=315→308
    mov     ecx, 115
    mov     eax, 115
    cvtsi2ss xmm0, eax
    mov     eax, 20
    cvtsi2ss xmm1, eax
    mov     eax, -18
    cvtsi2ss xmm2, eax
    divss   xmm2, xmm1
    mov     eax, -7
    cvtsi2ss xmm3, eax
    divss   xmm3, xmm1
    mov     eax, 210
    cvtsi2ss xmm4, eax
    mov     eax, 315
    cvtsi2ss xmm5, eax
    mov     eax, -115
    cvtsi2ss xmm8, eax
    addss   xmm8, xmm0
.arm_loop:
    cmp     ecx, 135
    jg      .arm_done
    movaps  xmm9, xmm8
    mulss   xmm9, xmm2
    addss   xmm9, xmm4
    cvttss2si r8d, xmm9
    movaps  xmm9, xmm8
    mulss   xmm9, xmm3
    addss   xmm9, xmm5
    cvttss2si r9d, xmm9
    add     r8d, r13d                ; X shift
    add     r9d, r13d
    cmp     r8d, 0
    jge     .axl
    xor     r8d, r8d
.axl:
    cmp     r9d, SCR_W - 1
    jle     .axr
    mov     r9d, SCR_W - 1
.axr:
    lea     edx, [ecx + r12d]       ; Y shift
    imul    r10d, edx, SCR_W
    mov     eax, r8d
.afill:
    cmp     eax, r9d
    jg      .anext
    mov     edx, r10d
    add     edx, eax
    mov     byte [r15 + rdx], PAL_WEAPON_SKIN_L
    inc     eax
    jmp     .afill
.anext:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .arm_loop

.arm_done:
    ; Hand on handle Y=136..150  X=178..216
    mov     ecx, 136
.hand_loop:
    cmp     ecx, 150
    jg      .hand_done
    lea     edx, [ecx + r12d]       ; Y shift
    imul    r10d, edx, SCR_W
    mov     eax, 178
.fistfill:
    cmp     eax, 216
    jg      .handnext
    mov     edx, r10d
    add     edx, eax
    add     edx, r13d               ; X shift
    mov     r11d, ecx
    sub     r11d, 136
    cmp     r11d, 2
    jl      .fist_body
    cmp     r11d, 12
    jg      .fist_body
    test    r11d, 1
    jz      .fin_gap
    cmp     eax, 190
    jl      .fist_body
    cmp     eax, 208
    jg      .fist_body
    mov     byte [r15 + rdx], PAL_WEAPON_SKIN_L
    jmp     .fistcol_ok
.fin_gap:
    cmp     eax, 189
    jne     .fistcol_ok
    mov     byte [r15 + rdx], PAL_WEAPON_TSUBA
    jmp     .fistcol_ok
.fist_body:
    mov     byte [r15 + rdx], PAL_WEAPON_SKIN_D
.fistcol_ok:
    inc     eax
    jmp     .fistfill
.handnext:
    inc     ecx
    jmp     .hand_loop

.hand_done:
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
