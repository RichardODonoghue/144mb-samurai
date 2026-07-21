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
    sub     rsp, 38h

    ; ---- Clear framebuffer ----
    mov     rdi, [g_bits]
    test    rdi, rdi
    jz      .done
    mov     ecx, (SCR_W * SCR_H) / 2
    mov     al, 8                       ; dark sky
    rep     stosb
    mov     ecx, (SCR_W * SCR_H) / 2
    mov     al, 128                     ; dark floor
    rep     stosb

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

.col_loop:
    cmp     r12d, SCR_W
    jae     .done

    ; Save rayDir for this column
    movaps  xmm10, xmm6                ; rayDirX
    movaps  xmm11, xmm7                ; rayDirY

    ; --- DDA Setup ---
    ; mapX = floor(posX), mapY = floor(posY)
    cvttss2si eax, xmm14               ; eax = mapX
    cvttss2si edx, xmm15               ; edx = mapY

    ; deltaDist = fabs(1/rayDir)
    movss   xmm8, [float_one]
    divss   xmm8, xmm10                ; deltaDistX = 1/rayDirX
    movss   xmm9, [float_one]
    divss   xmm9, xmm11                ; deltaDistY = 1/rayDirY

    ; Absolute values using temp registers
    movd    r8d, xmm8
    movd    r9d, xmm9
    and     r8d, 7FFFFFFFh
    and     r9d, 7FFFFFFFh
    movd    xmm8, r8d                  ; deltaDistX = abs
    movd    xmm9, r9d                  ; deltaDistY = abs

    ; Step direction and initial sideDist
    ; X direction
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

    ; Y direction
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
    mov     ecx, 0                     ; step counter

.dda_loop:
    inc     ecx
    cmp     ecx, MAX_DEPTH
    jae     .next_col

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
    jl      .next_col
    cmp     eax, MAP_W
    jge     .next_col
    cmp     edx, 0
    jl      .next_col
    cmp     edx, MAP_H
    jge     .next_col

    imul    edi, edx, MAP_W
    add     edi, eax
    movzx   edi, byte [world_map + rdi]
    test    edi, edi
    jz      .dda_loop

    ; Save wall type for colour lookup
    mov     r8d, edi

    ; --- Wall hit: calculate perpWallDist ---
    test    ebx, ebx
    jnz     .perp_y
.perp_x:
    cvtsi2ss xmm0, eax
    subss   xmm0, xmm14
    mov     eax, 1
    sub     eax, r13d
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
    sub     edx, r14d
    cvtsi2ss xmm1, edx
    mov     dword [rsp], 0x3F000000
    mulss   xmm1, [rsp]
    addss   xmm0, xmm1
    divss   xmm0, xmm11               ; perpWallDist

    ; --- Draw wall slice ---
.wall_draw:
    mov     dword [rsp], SCR_H
    cvtsi2ss xmm1, dword [rsp]
    divss   xmm1, xmm0                ; lineHeight = SCR_H / perpWallDist
    cvttss2si ebp, xmm1

    ; drawStart
    mov     eax, ebp
    neg     eax
    sar     eax, 1
    add     eax, SCR_H / 2
    cmp     eax, 0
    jge     .ds_ok
    xor     eax, eax
.ds_ok:
    mov     esi, eax

    ; drawEnd
    mov     eax, ebp
    sar     eax, 1
    add     eax, SCR_H / 2
    cmp     eax, SCR_H - 1
    jle     .de_ok
    mov     eax, SCR_H - 1
.de_ok:
    mov     edi, eax

    ; wall colour: base = 96 + (type-1)*8, Y-side += 4 darker
    mov     r9d, r8d
    dec     r9d                         ; type - 1
    imul    r9d, r9d, 8                 ; (type-1) * 8
    add     r9d, 96                     ; base palette index
    test    ebx, ebx
    jz      .draw_col
    add     r9d, 4                      ; Y-side: darker shade

.draw_col:
    cmp     esi, edi
    jg      .next_col
    imul    r10d, esi, SCR_W
    add     r10d, r12d
    mov     byte [r15 + r10], r9b
    inc     esi
    jmp     .draw_col

.next_col:
    addss   xmm6, xmm4                 ; rayDirX += stepX
    addss   xmm7, xmm5                 ; rayDirY += stepY
    inc     r12d
    jmp     .col_loop

.done:
    ; ---- Draw green marker at player start position ----
    movzx   eax, byte [player_angle]
    movss   xmm8, [cos_table + rax*4]
    movss   xmm9, [sin_table + rax*4]
    ; dx = start_x - player_x, dy = start_y - player_y
    movss   xmm0, [player_start_x]
    subss   xmm0, xmm14                 ; xmm0 = dx
    movss   xmm1, [player_start_y]
    subss   xmm1, xmm15                 ; xmm1 = dy
    ; forward = dx*cos + dy*sin
    movaps  xmm10, xmm0
    mulss   xmm10, xmm8
    movaps  xmm11, xmm1
    mulss   xmm11, xmm9
    addss   xmm10, xmm11
    pxor    xmm12, xmm12
    comiss  xmm12, xmm10
    jae     .no_marker                  ; skip if behind player
    ; Clamp forward to minimum 0.01
    mov     eax, 0x3C23D70A             ; 0.01f
    movd    xmm12, eax
    comiss  xmm12, xmm10
    jbe     .fw_ok
    movaps  xmm10, xmm12
.fw_ok:
    ; side = dy*cos - dx*sin
    movaps  xmm11, xmm1
    mulss   xmm11, xmm8
    movaps  xmm12, xmm0
    mulss   xmm12, xmm9
    subss   xmm11, xmm12
    ; screen_x = 160 + side/forward * 160
    divss   xmm11, xmm10
    mov     eax, 160
    cvtsi2ss xmm12, eax
    mulss   xmm11, xmm12
    addss   xmm11, xmm12
    cvttss2si r10d, xmm11
    ; Clamp screen_x to [0, SCR_W-1]
    cmp     r10d, 0
    jge     .sx1
    xor     r10d, r10d
.sx1:
    cmp     r10d, SCR_W - 1
    jle     .sx2
    mov     r10d, SCR_W - 1
.sx2:
    ; screen_y = 100 + 4/forward
    mov     eax, 4
    cvtsi2ss xmm11, eax
    divss   xmm11, xmm10
    mov     eax, 100
    cvtsi2ss xmm12, eax
    addss   xmm11, xmm12
    cvttss2si r11d, xmm11
    ; Clamp screen_y to [0, SCR_H-1]
    cmp     r11d, 0
    jge     .sy1
    xor     r11d, r11d
.sy1:
    cmp     r11d, SCR_H - 1
    jle     .sy2
    mov     r11d, SCR_H - 1
.sy2:
    ; Bounds-clamp + draw 3x3 green square
    lea     eax, [r10d - 1]
    cmp     eax, 0
    jge     .gx1
    xor     eax, eax
.gx1:
    mov     r8d, eax
    lea     eax, [r10d + 1]
    cmp     eax, SCR_W - 1
    jle     .gx2
    mov     eax, SCR_W - 1
.gx2:
    mov     r9d, eax
    lea     eax, [r11d - 1]
    cmp     eax, 0
    jge     .gy1
    xor     eax, eax
.gy1:
    mov     r10d, eax
    lea     eax, [r11d + 1]
    cmp     eax, SCR_H - 1
    jle     .gy2
    mov     eax, SCR_H - 1
.gy2:
    mov     r11d, eax
    mov     ecx, r10d
.gy_loop:
    cmp     ecx, r11d
    jg      .no_marker
    imul    edx, ecx, SCR_W
    mov     eax, r8d
.gx_loop:
    cmp     eax, r9d
    jg      .gnext_y
    mov     esi, edx
    add     esi, eax
    mov     byte [r15 + rsi], 120
    inc     eax
    jmp     .gx_loop
.gnext_y:
    inc     ecx
    jmp     .gy_loop
.no_marker:

    ; ================================================================
    ; Curved katana — thinner, hilt perpendicular to blade base
    ; ================================================================
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
    mov     byte [r15 + rdx], 122
    inc     eax
    jmp     .bifill
.biedge:
    mov     eax, r9d
    sub     eax, 1
    cmp     eax, r8d
    jl      .bnext
    add     eax, r10d
    mov     byte [r15 + rax], 123
    mov     eax, r9d
    sub     eax, 2
    cmp     eax, r8d
    jl      .bnext
    add     eax, r10d
    mov     byte [r15 + rax], 123
.bnext:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .blade_loop

.blade_done:
    ; Tsuba angled to match blade base: Y=125→128, X=185→178 (L), X=210→218 (R)
    mov     ecx, 125
    mov     eax, 125
    cvtsi2ss xmm0, eax
    mov     eax, 3
    cvtsi2ss xmm1, eax               ; dy=3
    mov     eax, -7
    cvtsi2ss xmm2, eax
    divss   xmm2, xmm1               ; slopeL = (178-185)/3 = -7/3
    mov     eax, 8
    cvtsi2ss xmm3, eax
    divss   xmm3, xmm1               ; slopeR = (218-210)/3 = 8/3
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
    cmp     r8d, 0
    jge     .tx
    xor     r8d, r8d
.tx:
    cmp     r9d, SCR_W - 1
    jle     .ty
    mov     r9d, SCR_W - 1
.ty:
    imul    r10d, ecx, SCR_W
    mov     eax, r8d
.tsfill:
    cmp     eax, r9d
    jg      .tsnxt
    mov     edx, r10d
    add     edx, eax
    mov     byte [r15 + rdx], 121
    inc     eax
    jmp     .tsfill
.tsnxt:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .tsuba_loop

.tsuba_done:
    ; Handle Y=128..170  XL=180→186  XR=210→215  (25→29px wide)
    mov     ecx, 128
    mov     eax, 128
    cvtsi2ss xmm0, eax
    mov     eax, 42
    cvtsi2ss xmm1, eax
    mov     eax, 6
    cvtsi2ss xmm2, eax
    divss   xmm2, xmm1               ; slopeL = 6/42
    mov     eax, 5
    cvtsi2ss xmm3, eax
    divss   xmm3, xmm1               ; slopeR = 5/42
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
    cmp     r8d, 0
    jge     .hxl
    xor     r8d, r8d
.hxl:
    cmp     r9d, SCR_W - 1
    jle     .hxr
    mov     r9d, SCR_W - 1
.hxr:
    imul    r10d, ecx, SCR_W
    mov     eax, r8d
.hdl_fill:
    cmp     eax, r9d
    jg      .hdl_next
    mov     edx, r10d
    add     edx, eax
    test    ecx, 2
    jz      .hcol
    mov     byte [r15 + rdx], 121
    jmp     .hcol_ok
.hcol:
    mov     byte [r15 + rdx], 124
.hcol_ok:
    inc     eax
    jmp     .hdl_fill
.hdl_next:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .hloop

.hdl_done:
    ; ---- Right arm (from screen edge behind handle) ----
    ; Y=115..135  XL=210→192  XR=315→308  (skin 125)
    mov     ecx, 115
    mov     eax, 115
    cvtsi2ss xmm0, eax
    mov     eax, 20
    cvtsi2ss xmm1, eax               ; dy
    mov     eax, -18
    cvtsi2ss xmm2, eax
    divss   xmm2, xmm1               ; slopeL
    mov     eax, -7
    cvtsi2ss xmm3, eax
    divss   xmm3, xmm1               ; slopeR
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
    cmp     r8d, 0
    jge     .axl
    xor     r8d, r8d
.axl:
    cmp     r9d, SCR_W - 1
    jle     .axr
    mov     r9d, SCR_W - 1
.axr:
    imul    r10d, ecx, SCR_W
    mov     eax, r8d
.afill:
    cmp     eax, r9d
    jg      .anext
    mov     edx, r10d
    add     edx, eax
    mov     byte [r15 + rdx], 125
    inc     eax
    jmp     .afill
.anext:
    addss   xmm8, [float_one]
    inc     ecx
    jmp     .arm_loop

.arm_done:
    ; ---- Hand on handle Y=136..150  X=178..216 ----
    mov     ecx, 136
.hand_loop:
    cmp     ecx, 150
    jg      .hand_done
    imul    r10d, ecx, SCR_W
    mov     eax, 178
.fistfill:
    cmp     eax, 216
    jg      .handnext
    mov     edx, r10d
    add     edx, eax
    mov     r11d, ecx
    sub     r11d, 136
    ; Top 2 rows: full fist cap
    cmp     r11d, 2
    jl      .fist_body
    ; Bottom 2 rows: fist base
    cmp     r11d, 12
    jg      .fist_body
    ; Middle 8 rows: fingers with gap
    test    r11d, 1
    jz      .fin_gap
    cmp     eax, 190
    jl      .fist_body
    cmp     eax, 208
    jg      .fist_body
    mov     byte [r15 + rdx], 125
    jmp     .fistcol_ok
.fin_gap:
    cmp     eax, 189
    jne     .fistcol_ok
    mov     byte [r15 + rdx], 121
    jmp     .fistcol_ok
.fist_body:
    mov     byte [r15 + rdx], 126
.fistcol_ok:
    inc     eax
    jmp     .fistfill
.handnext:
    inc     ecx
    jmp     .hand_loop

.hand_done:

    add     rsp, 38h
    pop     rsi
    pop     rdi
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
