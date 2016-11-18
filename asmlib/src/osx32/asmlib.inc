; asmlib/src/osx32/asmlib.inc
;
; This is a small library (work in progress) that provides 32-bit system calls
; and various utilities like string functions and generalized I/O on osx.
;
; Copyright 2016 Seiji Emery
;
; Special options:
;
;   define ASMLIB_SETUP_MAIN to tell the library to create a start procedure
;   that will setup I/O, call exit(0) by default, and call a function named _main.
;

section .text
%include "src/platform/nasm32.inc"
%include "src/platform/nasm_macros.inc"
%include "src/algorithms/io.inc"
%include "src/algorithms/io_macros.inc"
%include "src/algorithms/hash_functions.inc"
%include "src/algorithms/random.inc"
%include "src/algorithms/printutils.inc"
%include "src/algorithms/algorithms.inc"

;
; Config
;

; Defines size used for I/O buffer
%define IO_BUFFER_SIZE 4096

; void exit(int rval);
%macro SYSCALL_EXIT 1
    mov eax, %1
    call _sys_exit
%endmacro

; user_ssize_t write(int fd, user_addr_t cbuf, user_size_t nbyte)
%macro SYSCALL_WRITE 3
    pushad
    mov eax, %1
    mov esi, %2
    mov ecx, %3
    call _sys_write
    popad
%endmacro

;
; Library implementation
;

section .text
; Optional program setup
%ifdef ASMLIB_SETUP_MAIN
global start
start:
    ; SET_WRITE_TARGET STDOUT
    call _main
    ; call flushIO
    mov kax, 0
    call _sys_exit
%endif

