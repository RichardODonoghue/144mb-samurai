# AGENTS.md

## Project

144mb-samurai — a first-person samurai hack-and-slash game with raycasting, written as a competition entry for a 1,474,560-byte (post-decompression) game jam.

## Hard constraints

- **Size ceiling**: decompressed total < 1,474,560 bytes (executable + runtime only)
- **Format**: standalone Windows `.exe` — no web browsers, no browser-based runtimes
- **Language**: primary = assembly (NASM, Intel syntax), secondary = C where strictly needed
- **Dependencies**: avoid libraries and APIs wherever possible; roll your own
- **Originality**: all code/assets must be produced after competition open date

## Build system

- **Build command**: `build.bat` (calls vcvars64 internally, then NASM → link)
- **Pre-build command**: `py -3 src/gen_textures.py` (generates textures, palette data, shade tables)
- **Face generation**: `py -3 src/gen_faces.py` (generates 24×20 samurai face sprites)
- **Toolchain**: NASM → MSVC `link.exe` (C files via `cl.exe` when needed)
- **Environment setup**: `build.bat` handles vcvars64 automatically. If running commands manually:
  `"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"`
- **NASM path** (not on PATH by default): `C:\Users\richard\AppData\Local\bin\NASM\nasm.exe`
- **Link flags**: `/SUBSYSTEM:WINDOWS /ENTRY:main /NODEFAULTLIB /LARGEADDRESSAWARE:NO` — required. Without `/LARGEADDRESSAWARE:NO`, NASM's 32-bit `.data`/`.bss` relocations cause linker errors.
- **Libs**: `kernel32.lib user32.lib gdi32.lib` (no CRT)

## Source module structure

`src/main.asm` is the single entry point that `%include`s everything. `build.bat` assembles ONLY `src/main.asm`. All Win32 `extern` declarations live in `main.asm`.

### Include order (strict dependency chain)

```
src/main.asm
  ├─ %include "src/build.inc"     ← all equates, no dependencies
  ├─ extern declarations           ← all Win32 API imports
  ├─ %include "src/data.asm"      ← .data + .bss (must come before code)
  │    ├─ %include "src/sin_table.inc"    ← 256-entry float sin/cos tables
  │    ├─ %include "src/tex_gen.inc"      ← 32×32 4-bit textures (auto-generated)
  │    ├─ %include "src/palette_data.inc" ← palette entries (auto-generated)
  │    └─ %include "src/shade_data.inc"   ← shade/gradient/vignette tables (auto-generated)
  ├─ %include "src/init.asm"      ← depends on data.asm
  ├─ %include "src/render.asm"    ← depends on data.asm (calls render_floor, apply_vignette)
  ├─ %include "src/floor.asm"     ← textured floor raycasting
  ├─ %include "src/input.asm"     ← depends on data.asm
  ├─ %include "src/wndproc.asm"   ← depends on data.asm
  ├─ %include "src/level.asm"     ← level loading/transitions
  └─ %include "src/effects.asm"   ← particles + fire palette animation
```

### Module descriptions

| File | Lines | Purpose |
|------|-------|---------|
| `build.inc` | 106 | All `equ` constants: screen dims, palette layout, texture params, shading constants, Win32 constants, virtual keys, BMP offsets, stack frame layout |
| `data.asm` | 149 | `.data` section (strings, maps, constants, sin/cos tables, generated textures/palettes/shade tables) and `.bss` section (player state, globals, particle buffer, vignette mask, wall column buffer, DIB buffer) |
| `sin_table.inc` | 67 | Precomputed `sin_table` and `cos_table` (256 × 32-bit float each) |
| `gen_textures.py` | ~340 | Generates `tex_gen.inc` (32×32 4-bit textures with Perlin noise), `palette_data.inc` (wall/floor/fog palette entries), `shade_data.inc` (shade LUT, gradients, vignette RLE + LUT) |
| `init.asm` | 200 | `init_palette` (fills 256-colour palette), `init_dib` (creates 320×200 8-bit DIB via `CreateDIBSection`), `init_vignette` (RLE decompress into vignette mask) |
| `render.asm` | 720 | `render_frame` — gradient clear, then DDA raycasts all 320 columns with distance shading + fog into `g_bits`; `draw_katana` weapon overlay; `apply_vignette` post-processing |
| `floor.asm` | 240 | `render_floor` — textured floor raycasting from wall_bottom to screen bottom, with distance shading and tile-selectable floor textures (dirt/stone/wood) |
| `input.asm` | 244 | `process_input` — polls WASD/Shift/Escape via key_states[], mouse look via `GetCursorPos`, collision detection against `world_map` |
| `wndproc.asm` | 86 | `wndproc` — handles `WM_DESTROY`/`WM_CLOSE`/`WM_PAINT`, key up/down tracking, stretches DIB to window via `StretchDIBits` |
| `level.asm` | 77 | `level_init` (copy map, set start/end) and `level_check_end` (proximity trigger → next level) |
| `effects.asm` | 270 | `animate_fire` (cycles fire palette entries every 8 frames), `update_particles`, `spawn_particle`, `draw_particles` |
| `main.asm` | 170 | Entry point `main` (window creation, init) + `game_loop` (PeekMessage → dispatch → input → level check → particles → fire anim → render) |

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

effects.asm                  wndproc.asm
────────────                 ───────────
reads:  frame_counter,       reads:  g_bits,
        world_map,                   g_bmi, g_hwnd
        player_x, player_y,  writes: (read-only)
        g_bits
writes: g_bmi[] palette,
        g_bits[]
```

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
| 176-183 | 8 | Weapon/skin/debug (green, tsuba, blade, shine, wrap, skin l/d, black) |
| 184-191 | 8 | Fire animation + particle colours |
| 192-223 | 32 | Fog ramp (purple mist, near→far) |
| 224-255 | 32 | Vignette dark ramp (dark purple → black) |

Wall colour formula: `base = PAL_WALL_BASE(80) + (wallType - 1) * PAL_WALL_STRIDE(16)`, X-side = `base + texel`, Y-side = `base + 8 + texel`. Texels are 4-bit (0-7).

## Rendering pipeline (per frame)

1. **Gradient clear**: sky per-row gradient (0-99) and floor per-row gradient (100-199)
2. **Wall raycasting**: DDA per-column, 4-bit texture sampling, distance-based shade dimming, fog at distance ≥ 32
3. **Floor raycasting**: per-pixel floor texture mapping from wall_bottom to screen bottom, distance shaded, tile-selectable (dirt/stone/wood based on player location)
4. **Particle rendering**: sprite projection for fire particles
5. **Katana weapon overlay**: curved blade + handle + hand in screen space
6. **Vignette post-processing**: LUT-based edge darkening (outer ~15% of screen)

## Known issues

- **WASD movement not working** — `GetAsyncKeyState` detection succeeds in input.asm (mouse look works), but the collision/position-update path has an unresolved bug.
- **Mouse hits screen edge** — relative tracking works but cursor can leave the window.
- **No enemy sprites/AI** — infrastructure exists but no sprite rendering yet.
- **No audio** — no sound system in place.
- **Vignette mask is 64KB in .bss** — could be computed on-the-fly or RLE-decompressed to save BSS space.

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
| Size | 22,528 bytes (1.5% of 1,474,560 budget) |

## Open questions

- Audio approach? (none / PC speaker / raw WAV baked in)
- Enemy sprite rendering?
- UI / HUD?
