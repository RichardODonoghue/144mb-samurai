// crt_stubs.c — minimal C runtime replacements (no CRT needed)
#include "build.h"

// Float-to-int helper (needed when no CRT)
int _fltused = 0;

void * __cdecl memset(void *d, int c, unsigned int n) {
    unsigned char *p = (unsigned char *)d;
    while (n--) *p++ = (unsigned char)c;
    return d;
}

void * __cdecl memcpy(void *d, const void *s, unsigned int n) {
    unsigned char *dp = (unsigned char *)d;
    const unsigned char *sp = (const unsigned char *)s;
    while (n--) *dp++ = *sp++;
    return d;
}

int __cdecl memcmp(const void *a, const void *b, unsigned int n) {
    const unsigned char *pa = (const unsigned char *)a, *pb = (const unsigned char *)b;
    while (n--) { if (*pa != *pb) return *pa - *pb; pa++; pb++; }
    return 0;
}

// Float math helpers (used for absolute value without math.h)
float __cdecl fabsf(float x) {
    union { float f; unsigned int u; } u = { x };
    u.u &= 0x7FFFFFFF;
    return u.f;
}

// Float to int truncation
int __cdecl _ftol2(float x) {
    return (int)x;
}

// 64-bit intrinsic helpers that MSVC sometimes needs
__int64 __cdecl _alldiv(__int64 a, __int64 b) {
    return a / b;
}

__int64 __cdecl _allrem(__int64 a, __int64 b) {
    return a % b;
}

unsigned __int64 __cdecl _aullrem(unsigned __int64 a, unsigned __int64 b) {
    return a % b;
}

// Security cookie (disabled with /GS- but defined to avoid linker errors)
unsigned __int64 __security_cookie = 0x00002B992DDFA232ull;
void __cdecl __security_check_cookie(unsigned __int64 cookie) { (void)cookie; }
