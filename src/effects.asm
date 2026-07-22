section .text

; ============================================================
; animate_fire -- cycle fire palette entries every N frames
; ============================================================
animate_fire:
    mov     eax, [frame_counter]
    xor     edx, edx
    mov     ecx, ANIM_FIRE_INTERVAL
    div     ecx
    and     edx, 3                         ; cycle 0..3

    ; Select the right cycle
    lea     rsi, [fire_cycle0]
    cmp     edx, 0
    je      .do_copy
    lea     rsi, [fire_cycle1]
    cmp     edx, 1
    je      .do_copy
    lea     rsi, [fire_cycle2]
    cmp     edx, 2
    je      .do_copy
    lea     rsi, [fire_cycle3]
.do_copy:
    ; Copy 4 dwords into DIB palette at fire X-side entries (144-147)
    lea     rdi, [g_bmi + BMICOLORS_OFFSET + 144 * 4]
    mov     ecx, 4
    rep     movsd

    ; Also update particles/ash at entry 188 (PAL_PARTICLE) with fire ember
    lea     rdi, [g_bmi + BMICOLORS_OFFSET + PAL_PARTICLE * 4]
    lea     rsi, [fire_cycle0 + 8]         ; bright flame ember
    mov     eax, [fire_cycle0 + 12]
    mov     [rdi + 4], eax                 ; next entry = bright fire
    mov     eax, [rsi]
    mov     [rdi], eax                     ; particle entry = flame color
    ret

; ============================================================
; Particle system: 32 particles, 24 bytes each
;   x(4) y(4) vx(4) vy(4) life(4) color(1) size(1) +6 pad
; ============================================================

update_particles:
    inc     dword [frame_counter]

    ; Move + age
    mov     ecx, 32
    lea     rbx, [particles]
.uloop:
    cmp     dword [rbx + 16], 0
    jle     .unext
    movss   xmm0, [rbx]
    addss   xmm0, [rbx + 8]
    movss   [rbx], xmm0
    movss   xmm0, [rbx + 4]
    addss   xmm0, [rbx + 12]
    movss   [rbx + 4], xmm0
    dec     dword [rbx + 16]
    jg      .unext
    mov     dword [rbx + 16], 0
.unext:
    add     rbx, 24
    dec     ecx
    jnz     .uloop

    ; Spawn every 4 frames
    mov     eax, [frame_counter]
    and     eax, 3
    jnz     .done

    ; Scan fire cells within 10 map units
    cvttss2si r12d, dword [player_x]
    cvttss2si r13d, dword [player_y]
    mov     ecx, r13d
    sub     ecx, 5
    cmp     ecx, 0
    jge     .y0
    xor     ecx, ecx
.y0:
    mov     r8d, r13d
    add     r8d, 5
    cmp     r8d, 15
    jle     .y1
    mov     r8d, 15
.y1:

.scy:
    cmp     ecx, r8d
    jg      .done
    mov     eax, r12d
    sub     eax, 5
    cmp     eax, 0
    jge     .x0
    xor     eax, eax
.x0:
    mov     r9d, r12d
    add     r9d, 5
    cmp     r9d, 15
    jle     .x1
    mov     r9d, 15
.x1:

.scx:
    cmp     eax, r9d
    jg      .scny
    imul    r10d, ecx, 16
    add     r10d, eax
    cmp     byte [world_map + r10], 6
    jne     .scnx

    ; Fire cell (eax, ecx) — spawn 4 sparks
    cvtsi2ss xmm5, eax
    mov     r11d, 0x3F000000          ; 0.5f
    movd    xmm6, r11d
    addss   xmm5, xmm6
    cvtsi2ss xmm6, ecx
    mov     r11d, 0x3F000000
    movd    xmm7, r11d
    addss   xmm6, xmm7
    mov     r11d, 2
.espawn:
    mov     r10d, [frame_counter]
    add     r10d, r11d
    imul    r10d, 1103515245
    and     r10d, 15
    sub     r10d, 7
    cvtsi2ss xmm0, r10d
    mov     r15d, 0x3D4CCCCD
    movd    xmm1, r15d
    mulss   xmm0, xmm1
    addss   xmm0, xmm5               ; x

    mov     r10d, [frame_counter]
    sub     r10d, r11d
    imul    r10d, 1664525
    and     r10d, 15
    sub     r10d, 7
    cvtsi2ss xmm7, r10d
    mov     r15d, 0x3D4CCCCD
    movd    xmm1, r15d
    mulss   xmm7, xmm1
    addss   xmm7, xmm6               ; y

    pxor    xmm2, xmm2               ; vx
    mov     r15d, 0xBE4CCCCD         ; -0.2f
    movd    xmm3, r15d               ; vy

    ; Pick color (use PAL_FX_BASE range for fire particles)
    mov     r14d, r11d
    add     r14d, PAL_FX_BASE - 1
    mov     r9b, r14b
    mov     r10b, 5                  ; size

    push    rax
    push    rcx
    push    r11
    mov     r8d, 40                  ; life
    call    spawn_particle
    pop     r11
    pop     rcx
    pop     rax
    dec     r11d
    jnz     .espawn

.scnx:
    inc     eax
    jmp     .scx
.scny:
    inc     ecx
    jmp     .scy
.done:
    ret

; ============================================================
; spawn_particle -- xmm0=x xmm1=y xmm2=vx xmm3=vy r8d=life r9b=color r10b=size
; ============================================================
spawn_particle:
    push    rbx
    lea     rbx, [particles]
    mov     ecx, 32
.find:
    cmp     dword [rbx + 16], 0
    je      .got
    add     rbx, 24
    dec     ecx
    jnz     .find
    pop     rbx
    ret
.got:
    movss   [rbx], xmm0
    movss   [rbx + 4], xmm1
    movss   [rbx + 8], xmm2
    movss   [rbx + 12], xmm3
    mov     [rbx + 16], r8d
    mov     [rbx + 20], r9b
    mov     [rbx + 21], r10b
    pop     rbx
    ret

; ============================================================
; draw_particles -- project and render as crosses
; ============================================================
draw_particles:
    movzx   eax, byte [player_angle]
    movss   xmm10, [cos_table + rax*4]
    movss   xmm11, [sin_table + rax*4]
    movss   xmm14, [player_x]
    movss   xmm15, [player_y]
    mov     r15, [g_bits]
    mov     ecx, 32
    lea     rbx, [particles]

.ploop:
    cmp     dword [rbx + 16], 0
    jle     .pnx

    movss   xmm0, [rbx]
    subss   xmm0, xmm14
    movss   xmm1, [rbx + 4]
    subss   xmm1, xmm15

    movaps  xmm2, xmm0
    mulss   xmm2, xmm10
    movaps  xmm3, xmm1
    mulss   xmm3, xmm11
    addss   xmm2, xmm3
    pxor    xmm3, xmm3
    comiss  xmm3, xmm2
    jae     .pnx

    movaps  xmm3, xmm1
    mulss   xmm3, xmm10
    movaps  xmm4, xmm0
    mulss   xmm4, xmm11
    subss   xmm3, xmm4
    divss   xmm3, xmm2
    mov     eax, 200
    cvtsi2ss xmm4, eax
    mulss   xmm3, xmm4
    mov     eax, 160
    cvtsi2ss xmm4, eax
    addss   xmm3, xmm4
    cvttss2si r8d, xmm3               ; sx
    ; Clamp to safe range
    cmp     r8d, 0
    jge     .sc0
    xor     r8d, r8d
.sc0:
    cmp     r8d, SCR_W-1
    jle     .sc1
    mov     r8d, SCR_W-1
.sc1:

    mov     eax, 8
    cvtsi2ss xmm4, eax
    divss   xmm4, xmm2
    mov     eax, 95
    cvtsi2ss xmm3, eax
    subss   xmm3, xmm4
    cvttss2si r9d, xmm3               ; sy
    ; Clamp to safe range
    cmp     r9d, 0
    jge     .sy0
    xor     r9d, r9d
.sy0:
    cmp     r9d, SCR_H-1
    jle     .sy1
    mov     r9d, SCR_H-1
.sy1:

    movzx   r10d, byte [rbx + 21]     ; size
    movzx   r12d, byte [rbx + 20]     ; color

    ; Draw 3x3 filled square
    mov     r13d, r9d
    sub     r13d, 1
    cmp     r13d, 0
    jge     .py0
    xor     r13d, r13d
.py0:
    mov     r14d, r9d
    add     r14d, 1
    cmp     r14d, SCR_H-1
    jle     .py1
    mov     r14d, SCR_H-1
.py1:
    imul    r11d, r13d, SCR_W

.py_lp:
    cmp     r13d, r14d
    jg      .pnx
    mov     esi, r8d
    sub     esi, 1
    cmp     esi, 0
    jge     .px0
    xor     esi, esi
.px0:
    mov     edi, r8d
    add     edi, 1
    cmp     edi, SCR_W-1
    jle     .px1
    mov     edi, SCR_W-1
.px1:
    mov     eax, r11d
.px_lp:
    cmp     esi, edi
    jg      .px_done
    mov     edx, eax
    add     edx, esi
    mov     byte [r15 + rdx], r12b
    inc     esi
    jmp     .px_lp
.px_done:
    inc     r13d
    add     r11d, SCR_W
    jmp     .py_lp

.pnx:
    add     rbx, 24
    dec     ecx
    jnz     .ploop
    ret
