# AGENTS.md

## Project

144mb-samurai — a first-person samurai hack-and-slash game with raycasting, written as a competition entry for a 1,474,560-byte (post-decompression) game jam.

## Hard constraints

- **Size ceiling**: decompressed total < 1,474,560 bytes (executable + runtime only)
- **Format**: standalone Windows `.exe` — no web browsers, no browser-based runtimes
- **Language**: C99 (MSVC `cl.exe`), no CRT, no STL
- **Dependencies**: avoid libraries and APIs wherever possible; roll your own
- **Originality**: all code/assets must be produced after competition open date

## Codebase rules

- **All visual assets generated via Python** — no hardcoded geometric shapes. Every sprite, texture, face, heart comes from a Python generator outputting C `.h` headers.
- **One asset, one file** — each sprite is a standalone `.h` array (e.g. `katana_idle` data in `sprites.h`).
- **Compile-time generation** — Python runs at build time to produce `.h` files; C compiler bakes them into the binary.
- **No CRT** — zero CRT bytes linked. `memset`/`memcpy`/float helpers provided in `crt_stubs.c`.

## Build system

- **Build command**: `build.bat` (calls vcvars64 internally, then generates assets → `cl.exe` → link)
- **Pre-build commands** (run in order by `build.bat`):
  - `py -3 src/gen_textures.py` — wall/floor textures, palette data, shade tables → `tex_gen.h`, `palette_data.h`, `shade_data.h`
  - `py -3 src/gen_faces.py` — samurai face sprites (24×20) and heart sprites (20×18) → `faces.h`
  - `py -3 src/gen_weapon.py` — katana weapon sprites + arm sprites → `sprites.h`
- **Toolchain**: MSVC `cl.exe` → `link.exe`
- **Compiler flags**: `/O2 /Oi- /GS- /Gs9999999 /GR- /EHs-c- /TC`
- **Link flags**: `/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup /NODEFAULTLIB /LARGEADDRESSAWARE:NO /OPT:REF /OPT:ICF`
- **Libs**: `kernel32.lib user32.lib gdi32.lib` (no CRT)
- **Environment setup**: `build.bat` handles vcvars64 automatically.

## Source module structure

```
src/
  main.c            — entry point, game loop, window creation
  data.c            — all game state globals, maps, tables, includes all generated .h files
  render.c          — DDA raycasting, wall/roof/foundation drawing, vignette
  floor.c           — textured floor raycasting
  input.c           — WASD movement, mouse look, collision detection
  hud.c             — Doom-style status bar, face, hearts, health text
  weapon.c          — katana + arms sprite rendering, animation frame selection
  sprite.c          — general-purpose draw_sprite() blitter
  effects.c         — particles, fire palette animation
  combat.c          — attack/block state machines
  level.c           — level loading and transitions
  init.c            — palette init, DIB creation, vignette RLE decompress
  wndproc.c         — window message handler (WM_PAINT, WM_KEYDOWN, etc.)
  crt_stubs.c       — minimal memset/memcpy/fabsf replacements, _fltused
  build.h           — all #define constants (screen dims, palette layout, etc.)
  win32_types.h     — minimal Win32 type definitions (no windows.h)
  win32_imports.h   — all __declspec(dllimport) Win32 API declarations
  sin_table.h       — precomputed sin/cos tables (256 entries each)

  gen_textures.py   — generates tex_gen.h, palette_data.h, shade_data.h
  gen_faces.py      — generates faces.h (5 face states + 5 heart levels)
  gen_weapon.py     — generates sprites.h (7 katana frames + 5 arm frames)

Generated headers (build time):
  tex_gen.h         — 64×64 building textures (6 types) + 32×32 floor/roof textures
  palette_data.h    — palette entries for building, floor, weapon, fire, fog
  shade_data.h      — shade table, shade LUT (4 bands × 256), gradients, vignette
  faces.h           — face sprites (24×20 ×5) + heart sprites (20×18 ×5)
  sprites.h         — katana sprites (150×190 ×7) + arm sprites (130×85 ×5)
```

## Data flow

```
input.c                     render.c                    floor.c
──────                      ────────                    ──────
reads:  player_angle,       reads:  player_x,            reads:  player_x,
        player_x, player_y,         player_y,                    player_y,
        world_map                   player_angle,               player_angle,
                                    g_bits, world_map           world_map, wall_bottom
writes: player_x, player_y, writes: g_bits[],           writes: g_bits[]
        player_angle,               wall_bottom[]
        player_angle_f

combat.c                    weapon.c                    sprite.c
───────                     ────────                    ────────
reads:  mouse buttons       reads:  attack_state,       reads:  sprite data,
writes: attack_state,               attack_timer,               g_bits
        attack_timer,               block_state,
        block_state,                weapon_sprites[],
        block_timer,                arm_sprites[]
        blade_swing_x,      writes: g_bits[]
        blade_y_mod

effects.c                   wndproc.c
────────                    ────────
reads:  frame_counter,      reads:  g_bits, g_bmi, g_hwnd
        world_map,          writes: (read-only)
        player_x, player_y,
        g_bits
writes: fire palette,
        g_bits[]
```

## Sprite system

### Format

Each sprite in `sprites.h`:
```c
static const unsigned char spr_katana_idle_px[150*190] = { ... };
static const unsigned short spr_katana_idle_w = 150, spr_katana_idle_h = 190;

typedef struct { unsigned short w, h; const unsigned char* px; } sprite_info_t;
static const sprite_info_t weapon_sprites[7] = { {150, 190, spr_katana_idle_px}, ... };
static const sprite_info_t arm_sprites[7] = { {130, 85, spr_arms_idle_px}, ... };
```

### API

```c
void draw_sprite(unsigned short w, unsigned short h, const unsigned char *px, int dx, int dy);
// Clamps to screen edges. Skips pixel value 0 (transparent).
```

## Palette layout (8-bit indexed, 256 colours)

| Range | Size | Contents |
|-------|------|----------|
| 0-63 | 64 | Sky gradient (dark purple → bright purple) |
| 64-95 | 32 | Building palette: white plaster, red lacquer, timber, wood, roof grey, stone, murals |
| 96-111 | 16 | Floor dirt (8 light + 8 dark) |
| 112-127 | 16 | Floor stone (8 light + 8 dark) |
| 128-143 | 16 | Floor wood (8 light + 8 dark) |
| 144-175 | 32 | Unused (padding) |
| 176-183 | 8 | Weapon/skin (HUD green, tsuba, blade, shine, wrap, skin l/d, black) |
| 184-191 | 8 | Fire animation + particle colours |
| 192-223 | 32 | Fog ramp (purple mist, near→far) |
| 224-247 | 24 | Vignette dark ramp (purple → black) |
| 248-255 | 8 | Roof/foundation/HUD (tile, eave, foundation, panel, border) |

## Building types (map cell values 1-6)

| ID | Name | Style |
|----|------|-------|
| 1 | Machiya | Townhouse — dark lattice, noren curtain, white plaster, doorway |
| 2 | Minka | Farmhouse — vertical wood cladding, horizontal battens |
| 3 | Kura | Storehouse — white plaster, dark timber cross-grid, heavy door |
| 4 | Temple | Shrine — red columns, white plaster, tie beams, bracket clusters |
| 5 | Castle | Shiro — stone base, white plaster upper, timber frame, embrasures |
| 6 | Residence | Samurai home — refined plaster, timber frame, kamon murals |

## Rendering pipeline (per frame)

1. **Gradient clear**: sky per-row gradient + floor per-row gradient
2. **Wall raycasting**: DDA per-column, 64×64 8-bit texture sampling, shade LUT, fog
3. **Roof rendering**: tiled 32×32 roof texture with eave shadow/curl
4. **Foundation band**: tiled 32×8 stone texture at wall bottom
5. **Floor raycasting**: textured floor from wall_bottom to screen bottom
6. **Particle rendering**: fire embers near fire buildings
7. **Weapon overlay**: sprite-based katana + arms via draw_sprite
8. **HUD**: status bar, health bar, face, hearts, health text
9. **Vignette post-processing**: LUT-based edge darkening

## Known issues

- **WASD collision needs refinement** — movement collision works but can be improved for smoother wall sliding
- **Mouse edge handling** — cursor recenters but can leave window on fast movements
- **No enemy sprites/AI** — infrastructure exists, needs implementation
- **No audio** — sound system not yet implemented
- **Binary size ~650KB** — within budget but could be optimized

## Decisions taken

| Decision | Choice |
|----------|--------|
| Language | C99 (MSVC `cl.exe`) |
| Toolchain | MSVC `cl.exe` → `link.exe` |
| Target | x64 Windows |
| Resolution | 320×200 internal, stretched to 960×600 window |
| Colour | 8-bit indexed palette, DIB via `CreateDIBSection` |
| Raycasting | DDA with float math, precomputed sin/cos tables |
| Textures | 64×64 at 8-bit (building), 32×32 at 4-bit (floor) |
| Shading | 4-band LUT (building), texel subtraction (floor) |
| Roof | Tiled 32×32 sprite texture with eave overlay |
| Foundation | Tiled 32×8 stone texture |
| Map | 32×32 byte grid (6 building types) |
| Asset generation | Compile-time via Python → C header arrays |
| Weapon rendering | Sprite-based blitting (7 frames + 5 arm frames) |
| No CRT | Custom memset/memcpy/fabsf, zero CRT bytes |
| Size | ~651KB (44% of 1,474,560 budget) |
