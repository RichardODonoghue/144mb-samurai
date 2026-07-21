# AGENTS.md

## Project

144mb-samurai — a first-person samurai hack-and-slash game with raycasting, written as a competition entry for a 1,474,560-byte (post-decompression) game jam. See user-provided constraints below.

## Hard constraints

- **Size ceiling**: decompressed total < 1,474,560 bytes (executable + runtime only)
- **Format**: standalone Windows `.exe` — no web browsers, no browser-based runtimes
- **Language**: primary = assembly (NASM, Intel syntax), secondary = C where strictly needed
- **Dependencies**: avoid libraries and APIs wherever possible; roll your own
- **Originality**: all code/assets must be produced after competition open date

## Build system

- **Build command**: `build.bat` (calls vcvars64 internally, then NASM → link)
- **Toolchain**: NASM → MSVC `link.exe` (C files via `cl.exe` when needed)
- **Environment setup**: `build.bat` handles vcvars64 automatically. If running commands manually:
  `"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"`
- **NASM path** (not on PATH by default): `C:\Users\richard\AppData\Local\bin\NASM\nasm.exe`
- **Link flags**: `/SUBSYSTEM:WINDOWS /ENTRY:main /NODEFAULTLIB /LARGEADDRESSAWARE:NO` — required. Without `/LARGEADDRESSAWARE:NO`, NASM's 32-bit `.data`/`.bss` relocations cause linker errors.
- **Libs**: `kernel32.lib user32.lib gdi32.lib` (no CRT)

## Game overview

- Raycasted first-person view
- Mechanics: sprint, lunge, hack-and-slash, block attacks
- Environments: streets → forests → mountains → emperor's palace
- Story: samurai returns to burned village, hunts tyrant and his army
- Minimalist: no engine, no middleware, no external assets if possible (procedural / baked into binary)

## Workflow for agents

1. **Before writing code**: check AGENTS.md (this file). Verify no existing build scripts or config you would overwrite.
2. **Build**: run the complete build pipeline (assemble → compile → link) before committing. Verify `.exe` output is below size limit.
3. **Size discipline**: every addition must be justified against the 1.47 MB limit. Prefer assembly over C, C over libraries.
4. **No opaque blobs**: no pre-compiled libs unless absolutely necessary and documented.
5. **Commit style**: keep commits small and focused. Never commit generated `.exe` or build artifacts.

## Key files (will exist after setup)

- `build.bat` — single-command build
- `src/` — assembly (`.asm`) and C (`.c` / `.h`) source
- `build/` — build output (gitignored)

## Style conventions

- Assembly: Intel syntax (NASM-compatible)
- C: C99 or C11, no standard library calls beyond what is essential; avoid CRT where possible
- Comments sparse — code should be self-documenting

## Decisions taken (record for future reference)

| Decision | Choice |
|----------|--------|
| Assembler | NASM (Intel syntax) |
| C compiler | MSVC `cl.exe` (from VS 2022 Build Tools) |
| Linker | MSVC `link.exe` |
| Target | x64 Windows |

## Open questions (ask user before assuming)

- Audio approach? (none / PC speaker / raw WAV baked in)
- Input handling: Win32 API or BIOS/raw input?
