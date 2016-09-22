
; tell asmlib to create a start procedure that calls _main and sets up I/O
%define ASMLIB_SETUP_MAIN 

; Include asmlib (a collection of I/O routines I wrote for assignment 3)
%include "src/asmlib_osx.inc"

section .text
_main:
    WRITE_STR {"Hello, World!",10}
    ret
