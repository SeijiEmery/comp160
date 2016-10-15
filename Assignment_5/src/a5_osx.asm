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
; %define ASMLIB_SETUP_MAIN 
%include "osx32/asmlib.inc"
section .data
section .text

global start
start:
    call _main
    push 0
    mov eax, 1
    int 0x80

DECL_FCN _main
    ; CALL_SYSCALL_EXIT -1
    ; mov rax, 10
    ; CALL_SYSCALL_EXIT -1

    section .data
        str01: db "Hello, Assignment 5!", 10
        .len: equ $ - str01
    section .text
        ; WRITE_STRZ str01
        ; CALL_SYSCALL_WRITE STDOUT, str01, 22
        push dword str01.len
        push dword str01
        push dword 1
        mov eax, 4
        sub esp, 4
        int 0x80

        CALL_SYSCALL_WRITE STDOUT, str01, str01.len
        CALL_SYSCALL_EXIT  -1

        ; sub esp, 16
        ; mov [esp-0xC], dword str01.len
        ; mov [esp-0x8], dword str01
        ; mov [esp-0x4], dword STDOUT
        ; mov [esp-0x0], dword STDOUT
        ; mov eax, 4
        ; int 0x80
        ; add esp, 16

        ; sub esp, 16
        ; mov [esp-0x0], dword str01.len
        ; mov [esp-0x0], dword str01
        ; mov [esp-0x4], dword STDOUT
        ; mov [esp-0x8], dword STDOUT
        ; mov eax, 4
        ; int 0x80
        ; add esp, 16



        push dword 10
        push dword 9
        push dword 8
        push dword 7
        push dword 6

        push dword -1
        push dword 0
        sub esp, 4
        mov eax, 1
        int 0x80


    CALL_SYSCALL_EXIT 0

    mov edi, g_stdout_buffer
    WRITE_STR_LIT {"Hello, Assignment 5!", 10}
    sub edi, g_stdout_buffer
    CALL_SYSCALL_WRITE STDOUT, g_stdout_buffer, edi

    CALL_SYSCALL_EXIT 0
    mov edi, 0
    ; WRITE_STR_LIT {"Hello, Assignment 5!",10}
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

            WRITE_HEX_N ecx, 4
            ; WRITE_HEX_32 ecx

            push ecx
            ; call writeDecimal
            pop ecx
            ; WRITE_HEX eax

            WRITE_STR_LIT ", "
            ; WRITE_EOL
            pop eax
            loop .l2

        ; WRITE_STR "FOO"
        call flushIO
        pop ecx

        WRITE_HEX_N ecx, 4
        ; WRITE_HEX_32 ecx
        sub ecx, 0x100
        ; WRITE_HEX_32 ecx
        WRITE_HEX_N ecx, 4

        jg .l1
END_FCN _main

section .data
    lcg_seed: dd 5793654

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

