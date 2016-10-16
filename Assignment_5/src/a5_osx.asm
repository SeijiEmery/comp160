; Assignment 5:
; Program Description:
;
; Target platform: osx, 32-bit.
;   Uses posix syscalls (write, exit) using bsd 32-bit calling conventions.
;   Should run on linux with minor modifications.
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: 10/3/16
; Revisions: N/A (see git log)
; Date:              Modified by:
;

; tell asmlib to create a start procedure that calls _main and sets up I/O
%define ASMLIB_SETUP_MAIN 
%include "osx32/irvine32.inc"

section .data
    str01: db "Hello, Assignment 5!", 10, 0
    .len: equ $ - str01

section .text
DECL_FCN _main
    mov edx, str01
    call WriteString

    call Clrscr

    mov dh, 10
    mov dl, 5
    call Gotoxy

    mov edx, str01
    call WriteString
END_FCN _main

; section .data
;     lcg_seed: dd 5793654

; section .text
; DECL_FCN RandRange
;     sub eax, ebx
;     push ebx
;     push eax

;     mov eax, [lcg_seed]
;     call LCG_NextRand
;     mov [lcg_seed], eax
    
;     pop ebx

;     push edx
;     xor edx, edx
;     div ebx
;     mov eax, edx
;     pop edx

;     pop ebx
;     add eax, ebx

; END_FCN RandRange

; DECL_FCN LCG_NextRand
;     mov edx, 1103515245
;     mul edx
;     add eax, 12345
;     and eax, 0x7fffffff
; END_FCN LCG_NextRand

