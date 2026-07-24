@echo off
setlocal

echo Setting up MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
if errorlevel 1 (
    echo ERROR: vcvars64.bat failed
    exit /b 1
)

echo.
echo Generating assets...
py -3 src/gen_textures.py
if errorlevel 1 (echo Texture generation failed & exit /b 1)

py -3 src/gen_faces.py
if errorlevel 1 (echo Face generation failed & exit /b 1)

py -3 src/gen_weapon.py
if errorlevel 1 (echo Weapon generation failed & exit /b 1)

if not exist build mkdir build

echo.
echo Compiling...
cl /nologo /O2 /Oi- /GS- /Gs9999999 /GR- /EHs-c- /TC ^
   src/main.c src/data.c src/render.c src/floor.c src/input.c ^
   src/hud.c src/weapon.c src/sprite.c src/effects.c src/combat.c ^
   src/level.c src/init.c src/wndproc.c src/crt_stubs.c ^
   /link /SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup /NODEFAULTLIB /LARGEADDRESSAWARE:NO ^
         /OPT:REF /OPT:ICF ^
         kernel32.lib user32.lib gdi32.lib ^
         /OUT:build/game.exe

if errorlevel 1 (
    echo.
    echo Compilation FAILED
    exit /b 1
)

echo.
echo =====================================
echo Build complete: build\game.exe
for %%F in (build\game.exe) do echo Size: %%~zF bytes
