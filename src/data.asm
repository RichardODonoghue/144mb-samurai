; ============================================================
; SECTION .DATA
; ============================================================
section .data

    class_name   db 'SamuraiWindowClass', 0
    window_title db '144mb Samurai', 0

    ; Player start
    player_start_x:     dd 4.5
    player_start_y:     dd 4.5
    player_start_angle: db 0

    ; Movement params
    move_speed:     dd 0.04
    rot_speed:      dd 1.5
    mouse_sens:     dd 0.014
    angle_scale:    dd 40.743   ; 256 / (2*PI)

    ; Math constants
    float_one:      dd 1.0
    float_zero:     dd 0.0
    fov_factor:     dd 0.66

    ; Precomputed trig tables (256 entries, 32-bit floats)
    %include "src/sin_table.inc"

    ; World map (16x16, 0=empty, 1=brick, 2=stone, 3=wood)
    world_map:
        db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,2,2,0,0,0,0,0,2,2,0,0,0,1
        db 1,0,0,2,0,0,0,0,0,0,0,2,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,3,3,3,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,3,0,3,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,2,2,0,0,0,2,2,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; ============================================================
; SECTION .BSS
; ============================================================
section .bss

    ; Player state
    player_x:       resd 1
    player_y:       resd 1
    player_angle:   resb 1
    player_angle_f: resd 1      ; float angle accumulator
    player_paused:  resb 1
    prev_escape:    resb 1
    prev_mouse_x:   resd 1
    prev_mouse_y:   resd 1
    mouse_init:     resb 1

    ; Globals
    g_hwnd:         resq 1
    g_hinst:        resq 1
    g_dib:          resq 1
    g_bits:         resq 1

    ; Key state tracking (set by WM_KEYDOWN, cleared by WM_KEYUP)
    key_states:     resb 256

    ; BITMAPINFO (header + 256 palette entries)
    g_bmi:          resb 1064
