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
%include "src/asmlib_osx.inc"

section .data

section .text
DECL_FCN _main
    WRITE_STR {"Hello, Assignment 5!",10}
    call flushIO

    ; call dumpRegisters
    ; pushad
    ; mov eax, 100
    ; call dumpRegisters
    ; call flushIO
    ; popad
    ; call dumpRegisters
    ; call flushIO

    ; mov eax, 11283098

    ; mov ecx, 10000

    .l1:
        push ecx
        and  ecx, 0xff

        .l2:
            mov eax, 200      ; max bound
            mov ebx, 100      ; min bound
            call RandRange
            push eax

            WRITE_HEX ecx

            push ecx
            ; call writeDecimal
            pop ecx
            ; WRITE_HEX eax

            WRITE_STR ", "
            ; WRITE_EOL
            pop eax
            loop .l2

        ; WRITE_STR "FOO"
        call flushIO
        pop ecx

        WRITE_HEX ecx
        sub ecx, 0x100
        WRITE_HEX ecx

        jg .l1
END_FCN _main

section .data
    lcg_seed: dd 575366210393654

section .text
DECL_FCN RandRange
    sub eax, ebx
    push ebx
    push eax

    mov eax, [lcg_seed]
    call LCG_NextRand
    mov [lcg_seed], eax
    
    pop ebx

    push edx
    xor edx, edx
    div ebx
    mov eax, edx
    pop edx

    pop ebx
    add eax, ebx

END_FCN RandRange

DECL_FCN LCG_NextRand
    mov edx, 1103515245
    mul edx
    add eax, 12345
    and eax, 0x7fffffff
END_FCN LCG_NextRand










