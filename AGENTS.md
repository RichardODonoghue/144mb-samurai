# AGENTS.md

## Project

144mb-samurai — a first-person samurai hack-and-slash game with raycasting, written as a competition entry for a 1,474,560-byte (post-decompression) game jam.

## Hard constraints

- **Size ceiling**: decompressed total < 1,474,560 bytes (executable + runtime only)
- **Format**: standalone Windows `.exe` — no web browsers, no browser-based runtimes
- **Language**: primary = assembly (NASM, Intel syntax), secondary = C where strictly needed
- **Dependencies**: avoid libraries and APIs wherever possible; roll your own
- **Originality**: all code/assets must be produced after competition open date

## Codebase rules

- **All visual assets must be generated via Python tools** — no hardcoded geometric shapes in assembly. Every sprite, texture, face, heart, etc. must come from a Python generator script that outputs `.inc` data.
- **One asset, one file** — each sprite is a standalone `.inc` file (e.g. `katana_idle.inc`). This makes assets individually inspectable and maintainable.
- **Sprites use index 0 for transparency** — the `draw_sprite` blitter skips pixels with value 0.

## Build system

- **Build command**: `build.bat` (calls vcvars64 internally, then generates assets → NASM → link)
- **Pre-build commands** (run in order by `build.bat`):
  - `py -3 src/gen_textures.py` — wall/floor textures, palette data, shade tables
  - `py -3 src/gen_faces.py` — samurai face sprites (24×20) and heart sprites (20×18)
  - `py -3 src/gen_weapon.py` — katana weapon sprites + arm sprites
- **Toolchain**: NASM → MSVC `link.exe` (C files via `cl.exe` when needed)
- **Environment setup**: `build.bat` handles vcvars64 automatically. If running commands manually:
  `"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"`
- **NASM path** (not on PATH by default): `C:\Users\richard\AppData\Local\bin\NASM\nasm.exe`
- **Link flags**: `/SUBSYSTEM:WINDOWS /ENTRY:main /NODEFAULTLIB /LARGEADDRESSAWARE:NO` — required. Without `/LARGEADDRESSAWARE:NO`, NASM's 32-bit `.data`/`.bss` relocations cause linker errors.
- **Libs**: `kernel32.lib user32.lib gdi32.lib` (no CRT)
- **NASM warning suppression**: `-w-label-redef-late` — needed because multi-pass optimization can shift label offsets when instruction sizes change.

## Source module structure

`src/main.asm` is the single entry point that `%include`s everything. `build.bat` assembles ONLY `src/main.asm`. All Win32 `extern` declarations live in `main.asm`.

### Include order (strict dependency chain)

```
src/main.asm
  ├─ %include "src/build.inc"     ← all equates, no dependencies
  ├─ extern declarations           ← all Win32 API imports
  ├─ %include "src/data.asm"      ← .data + .bss (must come before code)
  │    ├─ %include "src/sin_table.inc"        ← 256-entry float sin/cos tables
  │    ├─ %include "src/tex_gen.inc"          ← 32×32 4-bit textures (auto-generated)
  │    ├─ %include "src/palette_data.inc"     ← palette entries (auto-generated)
  │    ├─ %include "src/shade_data.inc"       ← shade/gradient/vignette tables (auto-generated)
  │    ├─ %include "src/face_data.inc"        ← face + heart sprites (auto-generated)
  │    ├─ %include "src/sprites/katana_*.inc" ← weapon sprites (auto-generated)
  │    ├─ %include "src/sprites/arms_*.inc"   ← arm sprites (auto-generated)
  │    └─ %include "src/sprites/_sprite_table.inc" ← sprite lookup tables
  ├─ %include "src/init.asm"      ← depends on data.asm
  ├─ %include "src/render.asm"    ← depends on data.asm (calls render_floor, draw_weapon, apply_vignette)
  ├─ %include "src/floor.asm"     ← textured floor raycasting
  ├─ %include "src/hud.asm"       ← HUD rendering
  ├─ %include "src/input.asm"     ← depends on data.asm
  ├─ %include "src/wndproc.asm"   ← depends on data.asm
  ├─ %include "src/level.asm"     ← level loading/transitions
  ├─ %include "src/effects.asm"   ← particles + fire palette animation
  ├─ %include "src/sprite.asm"    ← general-purpose sprite blitter (draw_sprite)
  ├─ %include "src/weapon.asm"    ← weapon rendering (draw_weapon, replaces old draw_katana)
  └─ %include "src/combat.asm"    ← attack/block state machines
```

### Module descriptions

| File | Purpose |
|------|---------|
| `build.inc` | All `equ` constants: screen dims, palette layout, texture params, shading constants, weapon sprite positioning, Win32 constants, virtual keys, BMP offsets, stack frame layout |
| `data.asm` | `.data` section (strings, maps, constants, trig tables, all generated `.inc` data) and `.bss` section (player state, globals, combat state, particle buffer, vignette mask, wall column buffer, DIB buffer) |
| `sin_table.inc` | Precomputed `sin_table` and `cos_table` (256 × 32-bit float each) |
| `gen_textures.py` | Generates `tex_gen.inc` (32×32 4-bit wall/floor textures with Perlin noise), `palette_data.inc` (wall/floor/fog/weapon palette entries), `shade_data.inc` (shade LUT, gradients, vignette RLE + LUT) |
| `gen_faces.py` | Generates `face_data.inc` (5 samurai face damage states at 24×20, 5 heart fill levels at 20×18) |
| `gen_weapon.py` | Generates 7 katana weapon sprites (160×190) + 5 arm sprites (140×85) + `_sprite_table.inc` lookup table. Blade is bezier-curved with metallic gradient, edge shine, hamon pattern. Handle has diamond-wrap Ito pattern. Tsuba is oval with rim. Arms are layered separately for compositing. |
| `init.asm` | `init_palette` (fills 256-colour palette), `init_dib` (creates 320×200 8-bit DIB via `CreateDIBSection`), `init_vignette` (RLE decompress into vignette mask) |
| `render.asm` | `render_frame` — gradient clear, DDA raycasts all 320 columns with distance shading + fog + roof + foundation into `g_bits`; calls `draw_weapon`; `apply_vignette` post-processing |
| `floor.asm` | `render_floor` — textured floor raycasting from wall_bottom to screen bottom, distance shaded, tile-selectable (dirt/stone/wood) |
| `hud.asm` | `draw_hud` + `update_hud` — HUD panel, face, hearts, health text, damage flash |
| `input.asm` | `process_input` — polls WASD/Shift/Escape via key_states[], mouse look via `GetCursorPos`, collision detection against `world_map` |
| `wndproc.asm` | `wndproc` — handles `WM_DESTROY`/`WM_CLOSE`/`WM_PAINT`, key up/down tracking, stretches DIB to window via `StretchDIBits` |
| `level.asm` | `level_init` (copy map, set start/end) and `level_check_end` (proximity trigger → next level) |
| `effects.asm` | `animate_fire` (cycles fire palette entries every 8 frames), `update_particles`, `spawn_particle`, `draw_particles` |
| `sprite.asm` | `draw_sprite` — general-purpose sprite blitter. Reads dw width, dw height header, then blits pixel data to framebuffer, skipping transparent pixels (value 0). Clamps to screen edges. |
| `weapon.asm` | `draw_weapon` — selects weapon + arm sprite frames based on combat state (attack_state, attack_timer, block_state), positions them with `blade_swing_x`/`blade_y_mod` offsets, calls `draw_sprite` for weapon layer then arm layer. |
| `combat.asm` | `update_combat` — attack/block state machines that drive `blade_swing_x` and `blade_y_mod` floats for sprite positioning. |
| `main.asm` | Entry point `main` (window creation, init) + `game_loop` (PeekMessage → dispatch → input → level check → particles → fire anim → hud → combat → render) |

### Data flow

```
input.asm                     render.asm                  floor.asm
─────────                     ──────────                  ─────────
reads:  player_angle,         reads:  player_x,            reads:  player_x,
        player_x, player_y,           player_y,                    player_y,
        world_map                     player_angle,               player_angle,
                                      g_bits, world_map           world_map, wall_bottom
writes: player_x, player_y,   writes: g_bits[],           writes: g_bits[]
        player_angle,                 wall_bottom[]
        player_angle_f

combat.asm                   weapon.asm                  sprite.asm
───────────                  ───────────                 ──────────
reads:  mouse buttons        reads:  attack_state,       reads:  sprite data,
writes: attack_state,                attack_timer,               g_bits
        attack_timer,                block_state,
        block_state,                 blade_swing_x,
        block_timer,                 blade_y_mod,
        blade_swing_x,              weapon_sprites[],
        blade_y_mod                  arm_sprites[]
                            writes: g_bits[]

effects.asm                  wndproc.asm
────────────                 ───────────
reads:  frame_counter,       reads:  g_bits,
        world_map,                   g_bmi, g_hwnd
        player_x, player_y,  writes: (read-only)
        g_bits
writes: g_bmi[] palette,
        g_bits[]
```

## Sprite system

### Format

Every sprite `.inc` file contains:

```asm
spr_name:
    dw  <width>       ; pixel width (word)
    dw  <height>      ; pixel height (word)
    db  ...           ; width * height bytes of palette indices
```

Pixel value 0 = transparent (skipped by `draw_sprite`).

### API

```asm
; draw_sprite(sprite_ptr: rcx, dest_x: edx, dest_y: r8d)
; r15 must hold the framebuffer base (g_bits).
; Clamps to screen edges. Skips pixel value 0.
```

### Weapon + arms compositing

Weapon sprites (blade + tsuba + handle) and arm sprites (forearms + hands) are separate layers. `draw_weapon` blits the weapon layer first, then the arm layer on top. Both use the same frame index but point to different lookup tables (`weapon_sprites[]` and `arm_sprites[]`).

The screen position is computed as:
```
weapon_x = WEP_BASE_X + int(blade_swing_x)
weapon_y = WEP_BASE_Y + int(blade_y_mod)
arm_x    = ARM_BASE_X + int(blade_swing_x)
arm_y    = ARM_BASE_Y + int(blade_y_mod)
```

### Frame selection

| Combat state | weapon_sprites index | arm_sprites index |
|-------------|---------------------|-------------------|
| IDLE (both 0) | 0 (katana_idle) | 0 (arms_idle) |
| ATTACK WINDUP (timer 0-1) | 1 (windup_1) | 1 (arms_attack_1) |
| ATTACK WINDUP (timer 2-3) | 2 (windup_2) | 1 (arms_attack_1) |
| ATTACK SWING (timer 0-1) | 3 (swing_1) | 2 (arms_attack_2) |
| ATTACK SWING (timer 2-3) | 4 (swing_2) | 2 (arms_attack_2) |
| ATTACK SWING (timer 4-5) | 5 (swing_3) | 3 (arms_attack_3) |
| ATTACK RECOVER (timer 0-1) | 5 (swing_3) | 3 (arms_attack_3) |
| ATTACK RECOVER (timer 2-3) | 4 (swing_2) | 3 (arms_attack_3) |
| ATTACK RECOVER (timer 4-5) | 0 (idle) | 3 (arms_attack_3) |
| BLOCK (any) | 6 (katana_block) | 4 (arms_block) |

## Palette layout (8-bit indexed, 256 colours)

| Range | Size | Contents |
|-------|------|----------|
| 0-63 | 64 | Sky gradient (dark purple → bright purple) |
| 64-79 | 16 | Floor dirt/stone (8 light + 8 dark) |
| 80-95 | 16 | Brick walls (8 light + 8 dark) |
| 96-111 | 16 | Stone walls (8 light + 8 dark) |
| 112-127 | 16 | Wood shop walls (8 light + 8 dark) |
| 128-143 | 16 | Burnt wood walls (8 light + 8 dark) |
| 144-159 | 16 | Fire walls (8 light + 8 dark) |
| 160-175 | 16 | Floor wood planks (8 light + 8 dark) |
| 176-183 | 8 | Weapon/skin (tsuba=177, blade=178, shine=179, wrap=180, skin_l=181, skin_d=182, black=183). Entry 176 = HUD green overlay. |
| 184-191 | 8 | Fire animation + particle colours |
| 192-223 | 32 | Fog ramp (purple mist, near→far) |
| 224-255 | 32 | Vignette dark ramp (dark purple → black) |

Wall colour formula: `base = PAL_WALL_BASE(80) + (wallType - 1) * PAL_WALL_STRIDE(16)`, X-side = `base + texel`, Y-side = `base + 8 + texel`. Texels are 4-bit (0-7).

Sprite colour formula: weapon sprites use palette 177-183 directly as pixel values. Arm sprites use 181-183. Value 0 means transparent.

## Rendering pipeline (per frame)

1. **Gradient clear**: sky per-row gradient (0-99) and floor per-row gradient (100-199)
2. **Wall raycasting**: DDA per-column, 4-bit texture sampling, distance-based shade dimming, fog at distance ≥ 32
3. **Roof rendering**: Japanese curved tile roof above non-stone, non-fire buildings, with eave curl and foundation band
4. **Floor raycasting**: per-pixel floor texture mapping from wall_bottom to screen bottom, distance shaded, tile-selectable (dirt/stone/wood based on player location)
5. **Particle rendering**: sprite projection for fire particles
6. **Weapon overlay**: sprite-based katana + arms composited via `draw_weapon` → `draw_sprite` (replaces old hardcoded geometric drawing)
7. **Vignette post-processing**: LUT-based edge darkening (outer ~15% of screen)

## Known issues

- **WASD movement not working** — `GetAsyncKeyState` detection succeeds in input.asm (mouse look works), but the collision/position-update path has an unresolved bug.
- **Mouse hits screen edge** — relative tracking works but cursor can leave the window.
- **No enemy sprites/AI** — infrastructure exists but no sprite rendering yet.
- **No audio** — no sound system in place.
- **Vignette mask is 64KB in .bss** — could be computed on-the-fly or RLE-decompressed to save BSS space.
- **Sprite generation quality WIP** — current procedural katana generator produces basic shapes; pixel-art details (hamon, wrap pattern, proper hand anatomy) are approximate and can be refined.

## Decisions taken

| Decision | Choice |
|----------|--------|
| Assembler | NASM (Intel syntax) |
| C compiler | MSVC `cl.exe` (from VS 2022 Build Tools) |
| Linker | MSVC `link.exe` |
| Target | x64 Windows |
| Resolution | 320×200 internal, stretched to 960×600 window |
| Colour | 8-bit indexed palette, DIB via `CreateDIBSection` |
| Raycasting | DDA with SSE2 floats, sin/cos precomputed tables |
| Textures | 32×32 at 4-bit (8 shades), Perl noise procedural gen |
| Shading | Distance-based texel dimming (shade_table LUT) + fog |
| Floor | Full textured floor casting, 3 tile types |
| Map | 16×16 byte grid (0=empty, 1=brick, 2=stone, 3=wood, 5=burnt, 6=fire) |
| Asset generation | All visual assets via Python generators → individual `.inc` files |
| Weapon rendering | Sprite-based blitting (not hardcoded geometry) |
| Weapon compositing | Separate weapon + arm sprite layers, combined at render time |
| Animation | Per-frame sprites selected by combat state machine |
| Weapon positioning | Base screen position + blade_swing_x / blade_y_mod float offsets |
| Size | ~302KB (20.5% of 1,474,560 budget) |

## Open questions

- Audio approach? (none / PC speaker / raw WAV baked in)
- Enemy sprite rendering?
- UI / HUD wiring?
