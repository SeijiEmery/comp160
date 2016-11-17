; nasm32.inc
;
; Provides defines for writing cross-platform 32 / 64 bit code in nasm.
; Defines the following:
;   kax / kbx / kcx / etc., set of registers, which expand to eax or rax
;   registers depending on if you included nasm32.inc or nasm64.inc.
;
;   Type definitions for char_t, ptr_t, and size_t (platform dependent),
;   and macros for extracting the size / declaration keyword / reserve
;   keyword for that type, via TYPE_SIZE(t), TYPE_DECL(t), and TYPE_RES(T),
;   respectively.
;
; Guidelines:   
;   Use al / ax / eax registers for fixed-size values, and kax registers
;   for pointers + size types.
;
;   Use TYPE_*** macros for type sizes and declarations.
;       TYPE_SIZE(byte) => 1
;       TYPE_DECL(byte) => db
;       TYPE_RES(byte)  => resb
;   Defined for: byte, word, dword, qword (iff x64), char_t, size_t / ptr_t / int_t.
;
;   Use %ifdef PLATFORM_x86 / %ifdef PLATFORM_x64 directives to guard 
;   platform-specific code.
;
%define PLATFORM_x86

;
; Cross-platform register defines:
; k** registers = e** on 32-bit, r** on 64-bit.
; Use these for pointer registers, etc.,
;
%define kax eax
%define kbx ebx
%define kcx ecx
%define kdx edx
%define ksp esp
%define kbp ebp
%define ksi esi
%define kdi edi

;
; Cross-platform typedefs. Use in replace of dword, etc.
;

; Builtin types
%define decl_byte  db
%define decl_word  dw
%define decl_dword dd

%define sizeof_byte  1
%define sizeof_word  2
%define sizeof_dword 4

%define res_byte     resb
%define res_word     resw
%define res_dword    resd

; Native integer type
%define int_t        dword
%define decl_int_t   decl_dword
%define sizeof_int_t sizeof_dword
%define res_int_t    res_dword

; Native character type (UTF-8; for UTF-16 define as word)
%define char_t        byte
%define decl_char_t   decl_byte
%define sizeof_char_t sizeof_byte
%define res_char_t    res_byte

; Native size type
%define size_t        dword
%define decl_size_t   decl_dword
%define sizeof_size_t sizeof_dword
%define res_size_t    res_dword

; Native pointer type
%define ptr_t        dword
%define decl_ptr_t   decl_dword
%define sizeof_ptr_t sizeof_dword
%define res_ptr_t    res_dword

