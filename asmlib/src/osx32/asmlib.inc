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

;
; Config
;

; Defines size used for I/O buffer
%define IO_BUFFER_SIZE 4096

; void exit(int rval);
%macro SYSCALL_EXIT 1
    EXEC_SYSCALL SYS_EXIT, %1, dword 0
%endmacro

; user_ssize_t write(int fd, user_addr_t cbuf, user_size_t nbyte)
%macro SYSCALL_WRITE 3
    EXEC_SYSCALL SYS_WRITE, %1, %2, %3, dword 0
%endmacro

; function exit (eax exit_code)
DECL_FCN exit
    EXEC_SYSCALL SYS_EXIT, kax, dword 0
END_FCN  exit

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
    call exit
%endif

