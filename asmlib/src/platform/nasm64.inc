; nasm64.inc
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
%define PLATFORM_x64

;
; Cross-platform register defines:
; k** registers = e** on 32-bit, r** on 64-bit.
; Use these for pointer registers, etc.,
;
%define kax rax
%define kbx rbx
%define kcx rcx
%define kdx rdx
%define ksp rsp
%define kbp rbp
%define ksi rsi
%define kdi rdi

;
; Cross-platform typedefs. Use in replace of dword, etc.
;

; Builtin types
%define decl_byte  db
%define decl_word  dw
%define decl_dword dd
%define decl_qword dq

%define sizeof_byte  1
%define sizeof_word  2
%define sizeof_dword 4
%define sizeof_qword 8

%define res_byte     resb
%define res_word     resw
%define res_dword    resd
%define res_qword    resq

; Native integer type
%define int_t        qword
%define decl_int_t   decl_qword
%define sizeof_int_t sizeof_qword
%define res_int_t    res_qword

; Native character type (UTF-8; for UTF-16 define as word)
%define char_t        byte
%define decl_char_t   decl_byte
%define sizeof_char_t sizeof_byte
%define res_char_t    res_byte

; Native size type
%define size_t        qword
%define decl_size_t   decl_qword
%define sizeof_size_t sizeof_qword
%define res_size_t    res_qword

; Native pointer type
%define ptr_t        qword
%define decl_ptr_t   decl_qword
%define sizeof_ptr_t sizeof_qword
%define res_ptr_t    res_qword

%ifdef PLATFORM_OSX
    SYS_CLASS_UNIX equ 0x2000000
    SYS_EXIT  equ 1 | SYS_CLASS_UNIX
    SYS_READ  equ 3 | SYS_CLASS_UNIX
    SYS_WRITE equ 4 | SYS_CLASS_UNIX
%else
    SYS_EXIT  equ 1
    SYS_READ  equ 3
    SYS_WRITE equ 4
%endif

; Stdout, etc
STDIN  equ 0
STDOUT equ 1
STDERR equ 2

;
; System calls (uniform interface across 32 / 64 bit)
;

; function exit
;   in rax exit_code
_sys_exit:
    mov rdi, rax
    mov rax, SYS_EXIT
    syscall
    ret

; function write
;   in rax fd
;   in rsi buffer
;   in rcx length
_sys_write:
    push rdx
    mov  rdx, rcx
    mov  rdi, rax
    mov  rax, SYS_WRITE
    syscall
    pop  rdx
    ret

; function read
;   in rax fd
;   in rdi buffer
;   in rcx length
_sys_read:
    push rdx
    mov rdx, rcx
    mov rdi, rax
    mov rax, SYS_READ
    syscall
    pop rcx
    ret
