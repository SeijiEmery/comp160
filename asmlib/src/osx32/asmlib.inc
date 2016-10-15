; asmlib/src/osx32/asmlib.inc
;
; This is a small library (work in progress) that provides 32-bit system calls
; and various utilities like string functions and generalized I/O on osx.
;
; Copyright 2016 Seiji Emery
;

;
; Note: at some point we will break this into multiple files and make our I/O
; crossplatform (given nasm and 32-bit calls), but due to time constraints,
; I'm just dumping this into one file.
;

;
; Special options:
;
;   define ASMLIB_SETUP_MAIN to tell the library to create a start procedure
;   that will setup I/O, call exit(0) by default, and call a function named _main.
;

;
; Config
;

; Defines size used for I/O buffer
%define IO_BUFFER_SIZE 4096

;
; General purpose macros
;

; DECL_FCN fcn_name macro:
; Declares the start of a function using the label fcn_name, and creates a esp/ebp stack frame.
%macro DECL_FCN 1
%1: 
    push ebp
    mov  ebp,esp
%endmacro

; END_FCN fcn_name macro:
; Declares the end of a function (fcn_name just included for readability).
; Expands to instructions that exit the stack frame + returns (ret).
%macro END_FCN 1
    mov esp,ebp
    pop ebp
    ret
%endmacro

; System calls, etc. Uses i386 osx conventions.
%define STDIN 0
%define STDOUT 1
%define STDERR 2

%macro EXEC_SYSCALL %1
    mov eax, %1
    int 0x80
%endmacro

%macro CALL_SYSCALL_EXIT 1
    push %1
    EXEC_SYSCALL 1
%endmacro

%macro CALL_SYSCALL_WRITE 3
    push %3
    push %2
    push %1
    EXEC_SYSCALL 4
%endmacro

;
; Library implementation
;

section .text
; Optional program setup
%ifdef ASMLIB_SETUP_MAIN
global start
start:
    call resetIO
    call _main
    call flushIO

    push 0
    call syscall_exit
%endif

section .bss
g_stdin_buffer:  resb IO_BUFFER_SIZE
g_stdout_buffer: resb IO_BUFFER_SIZE
g_stderr_buffer: resb IO_BUFFER_SIZE

section .data
g_stdin_offset: DWORD 0 
g_stdout_offset: DWORD 0
g_stderr_offset: DWORD 0

section .text




