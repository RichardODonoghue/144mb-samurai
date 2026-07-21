@echo off
setlocal

echo Setting up MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
if errorlevel 1 (
    echo ERROR: vcvars64.bat failed
    exit /b 1
)

set "NASM=C:\Users\richard\AppData\Local\bin\NASM\nasm.exe"

if not exist build mkdir build

echo Assembling...
"%NASM%" -f win64 src\main.asm -o build\main.obj
if errorlevel 1 (
    echo NASM assembly failed
    exit /b 1
)

echo Linking...
link /SUBSYSTEM:WINDOWS /ENTRY:main /NODEFAULTLIB /LARGEADDRESSAWARE:NO build\main.obj kernel32.lib user32.lib gdi32.lib /OUT:build\game.exe
if errorlevel 1 (
    echo Link failed
    exit /b 1
)

echo.
echo Build complete: build\game.exe
for %%F in (build\game.exe) do echo Size: %%~zF bytes
