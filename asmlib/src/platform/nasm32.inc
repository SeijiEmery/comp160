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

; Macro for getting "declaration type" (dword => dd, byte => db)
; and type size for use in other macros
%define TYPE_DECL(type) %{type}_decl_t
%define TYPE_RES(type)  %{type}_res
%define TYPE_SIZE(type) %{type}_sizeof

; Builtin types
%define byte_decl_t  db
%define word_decl_t  dw
%define dword_decl_t dd

%define byte_sizeof  1
%define word_sizeof  2
%define dword_sizeof 4

%define byte_res     resb
%define word_res     resw
%define dword_res    resd

; Native integer type
%define int_t dword
%define int_t_decl_t TYPE_DECL(int_t)
%define int_t_sizeof TYPE_SIZE(int_t)
%define int_t_res    TYPE_DECL(int_t)

; Native character type (UTF-8; for UTF-16 define as word)
%define char_t byte
%define char_t_decl_t TYPE_DECL(char_t)
%define char_t_sizeof TYPE_SIZE(char_t)
%define char_t_res    TYPE_RES(char_t)

; Native size type
%define size_t dword
%define size_t_decl_t TYPE_DECL(size_t)
%define size_t_sizeof TYPE_SIZE(size_t)
%define size_t_res    TYPE_RES(size_t)

; Native pointer type
%define ptr_t dword
%define ptr_t_decl_t TYPE_DECL(ptr_t)
%define ptr_t_sizeof TYPE_SIZE(ptr_t)
%define ptr_t_res    TYPE_RES(ptr_t)
