section .text

; ============================================================
; wndproc -- Window procedure
; ============================================================
wndproc:
    sub     rsp, 28h

    cmp     edx, WM_DESTROY
    je      .quit
    cmp     edx, WM_CLOSE
    je      .quit
    cmp     edx, WM_PAINT
    je      .paint

    call    DefWindowProcA
    add     rsp, 28h
    ret

.quit:
    xor     ecx, ecx
    call    PostQuitMessage
    xor     eax, eax
    add     rsp, 28h
    ret

.paint:
    add     rsp, 28h            ; undo wndproc entry sub
    sub     rsp, 0B8h           ; own frame (184 = 11*16+8, aligned)

    ; BeginPaint
    mov     rcx, [g_hwnd]
    lea     rdx, [rsp + 68h]    ; PAINTSTRUCT
    call    BeginPaint
    ; HDC is PAINTSTRUCT.hdc at [rsp + 68h]

    ; StretchDIBits(hdc, 0, 0, winW, winH, 0, 0, SCR_W, SCR_H, bits, &bmi, 0, SRCCOPY)
    mov     dword [rsp + 60h], 00CC0020h   ; rop = SRCCOPY
    mov     dword [rsp + 58h], 0           ; iUsage = DIB_RGB_COLORS
    lea     rax, [g_bmi]
    mov     [rsp + 50h], rax               ; lpbmi
    mov     rax, [g_bits]
    mov     [rsp + 48h], rax               ; lpBits
    mov     dword [rsp + 40h], SCR_H       ; SrcHeight
    mov     dword [rsp + 38h], SCR_W       ; SrcWidth
    mov     dword [rsp + 30h], 0           ; ySrc
    mov     dword [rsp + 28h], 0           ; xSrc
    mov     dword [rsp + 20h], WIN_H       ; DestHeight
    mov     r9d, WIN_W                     ; DestWidth
    xor     r8d, r8d                       ; yDest
    xor     edx, edx                       ; xDest
    mov     rcx, [rsp + 68h]               ; hdc from PAINTSTRUCT
    call    StretchDIBits

    ; EndPaint
    mov     rcx, [g_hwnd]
    lea     rdx, [rsp + 68h]    ; PAINTSTRUCT
    call    EndPaint

    xor     eax, eax
    add     rsp, 0B8h
    ret
