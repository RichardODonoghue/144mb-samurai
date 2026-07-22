; ============================================================
; SECTION .DATA
; ============================================================
section .data

    class_name   db 'SamuraiWindowClass', 0
    window_title db '144mb Samurai', 0

    ; Player start (defaults, overwritten by level_init)
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

    ; ---- Level 0: Training dojo (original) ----
    level0_map:
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
    level0_start_x:     dd 4.5
    level0_start_y:     dd 4.5
    level0_start_angle: db 0
    level0_end_x:       dd 14.0
    level0_end_y:       dd 14.0

    ; ---- Level 1: Burned village ----
    ; 0=empty 1=brick 2=stone 3=wood 5=burntwood 6=fire
    level1_map:
        db 1,1,1,1,6,6,1,1,1,1,1,1,1,1,1,1
        db 1,0,0,0,6,0,0,0,0,0,0,0,0,0,0,1
        db 1,0,0,5,6,0,0,5,5,0,0,5,5,0,0,1
        db 1,0,0,5,0,0,0,5,0,0,0,5,0,0,0,1
        db 1,0,0,0,0,5,0,0,0,0,0,5,0,0,0,1
        db 1,0,0,0,0,5,0,0,6,6,0,0,0,0,0,1
        db 1,5,5,0,0,0,0,0,6,6,0,0,0,2,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,5,2,0,1
        db 1,0,0,6,0,0,0,5,0,0,0,0,5,0,0,1
        db 1,0,0,6,0,0,0,5,0,0,5,0,0,0,0,1
        db 1,0,0,0,0,5,5,0,0,0,5,0,0,5,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,5,0,1
        db 1,0,0,2,0,0,0,5,5,0,0,0,0,0,0,1
        db 1,0,0,2,0,0,0,5,0,0,0,0,0,0,0,1
        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    level1_start_x:     dd 2.5
    level1_start_y:     dd 14.5
    level1_start_angle: db 192
    level1_end_x:       dd 14.0
    level1_end_y:       dd 2.0

    ; ---- 32x32 wall/floor textures (1024 bytes each, 4-bit texels 0-7) ----
    ; Type->texture index map: 1->0, 2->1, 3->2, 4->0, 5->3, 6->4
    tex_type_map: db 0, 1, 2, 0, 3, 4
    %include "src/tex_gen.inc"

    ; Floor texture map: cell value (under player) -> floor texture index
    ; 0=empty (dirt), 1=brick (stone floor), 2=stone, 3=wood
    ; 5=burnt (dirt), 6=fire (dirt)
    floortex_map: db 0, 2, 2, 1, 0, 0, 0  ; 0=dirt, 1=wood, 2=stone
    floor_tex_table: dq tex_floor_dirt, tex_floor_stone, tex_floor_wood

    ; ---- Auto-generated palette data ----
    %include "src/palette_data.inc"

    ; ---- Auto-generated shade/gradient/vignette tables ----
    %include "src/shade_data.inc"

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

    ; Active world map (copied from level on load)
    world_map:      resb 256

    ; Level state
    current_level:  resd 1
    level_end_x:    resd 1
    level_end_y:    resd 1

    ; Frame counter for animations
    frame_counter:  resd 1

    ; Fire animation state
    fire_anim_frame: resd 1

    ; Particle system: 32 particles × 24 bytes
    particles:      resb 768

    ; Vignette spatial mask (decompressed from RLE at init, 320x200 bytes)
    vignette_mask:  resb 64000

    ; Wall column buffer: drawEnd per column for floor casting
    wall_bottom:    resw 320     ; 640 bytes, 2 bytes per column

    ; BITMAPINFO (header + 256 palette entries)
    g_bmi:          resb 1064
