; Assignment 5:
; Program Description:
;   Generates + prints a sequence of random integers and strings.
;
; Target platform: osx, 32-bit.
;   Uses asmlib + an irvine32 wrapper over asmlib.
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: 10/3/16
; Revisions: N/A (see git log)
; Date:              Modified by:
;

; tell asmlib to create a start procedure that calls _main and sets up I/O
%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

; irvine32 is a wrapper library for asmlib that emulates irvine32 from the book
; asmlib internals can still be used (I/O, etc), but this is discouraged, since
; these calls cannot be directly ported to windows.

section .data
    str01: db "Hello, Assignment 5!", 10, 0
        .len: equ $ - str01

    ; String separator used to print random values
    commaStr: db ", ",0

    ; Min / max values for N random numbers.
    ; Note: min inclusive, max exclusive: range = [randMin, randMax).
    randMin: dd -100
    randMax: dd 100 
section .bss
    ; String buffer used for part 2
    strbuf: resb 4096
section .text

; Define the number of random numbers + strings to print.
; Changing these affects both # things printed, and the output text saying # of
; things printed)
%define NUM_RANDOM_NUMBERS 30
%define NUM_RANDOM_STRINGS 20


; main() function. Note:
;   – name starts w/ an underscore (_main) b/c that's the osx nasm convention
;     for public symbols -- if you want to be able to hook it into a debugger,
;     it must start with an underscore on osx.
;     (note: this is NOT the convention on linux).
;   – gets called from a 'start' created by asmlib (ASMLIB_SETUP_MAIN)
;   – does NOT include a ret statement.
;   – DECL_FCN / END_FCN macros include a label, ret statement, and stack
;     frame instructions:
;       DECL_FCN foo
;           ...
;       END_FCN  foo
;   =>
;       foo:
;           push ebp
;           mov ebp, esp
;           ...
;           mov esp, ebp
;           pop ebp
;           ret
;   – Returning early WILL screw up the stack + stack frame, so all functions
;     using asmlib should instead jmp to a label right before function exit
;     instead.
;   – Stack frame instructions add a small amount of overhead to each function
;     call, but this is negligable. B/c all DECL_FCN / END_FCN procedures
;     contain stack frame instructions, the possibility of screwing up the stack
;     with eg. unbalanced push / pop instructions is mitigated (so long as
;     code doesn't touch ebp and explicit ret is avoided!)
;
DECL_FCN _main
    ; set lcg seed (asmlib). LCG is our random number implementation (a linear
    ; congruental generator), and our impl matches the c standard library.
    ; Note: LCG is a fairly poor PRNG, but is very simple to implement + fast.
    ; Irvine32 also uses a LCG, btw.
    LCG_SET_SEED dword 1876876839

    ; randomize() call seeds w/ current time (not yet implemented).
    ; call Randomize

    ; Note: using asmlib I/O here b/c it's more convenient (can _efficiently_ 
    ; replicate printf, though the macros are pretty fugly).
    ; 
    ; Everything else is written using irvine32 (specifically, wrappers around
    ; asmlib that emulates irvine32).
    ;
    ; printf("\n%d Random numbers: \n", NUM_RANDOM_NUMBERS)
    IO_ENTER_STDOUT
        WRITE_EOL
        WRITE_DEC NUM_RANDOM_NUMBERS
        WRITE_STR_LIT {" Random numbers:",10}
    IO_EXIT_STDOUT

    ; Display N random numbers using BetterRandomRange
    mov ecx, NUM_RANDOM_NUMBERS
    .brr_loop:
        ; Load min/max + call BetterRandomRange
        mov eax, [randMax]
        mov ebx, [randMin]
        call BetterRandomRange

        ; Write result (stored in eax) to stdout
        call WriteInt

        ; Loop condition (more complex to avoid printing last separator)
        sub ecx, 1
        jle .end_loop

        ; print separator ", " and continue
        mov edx, commaStr
        call WriteString
        jmp .brr_loop
    .end_loop:
    call Crlf

    ; printf("\n%d Random strings: \n", NUM_RANDOM_STRINGS)
    IO_ENTER_STDOUT
        WRITE_EOL
        WRITE_DEC NUM_RANDOM_STRINGS
        WRITE_STR_LIT {" Random strings:",10}
    IO_EXIT_STDOUT

    ; Display N random strings using CreateRandomString
    mov ecx, NUM_RANDOM_STRINGS
    jmp .str_loop
    .str_loop:
        ; call CreateRandomString(100, strbuf)
        mov eax, 100
        mov esi, strbuf
        call CreateRandomString

        ; add trailing '\0', b/c WriteString expects null-terminated strings.
        mov [esi+1], byte 0

        ; call WriteString (strbuf points to start of the string)
        mov edx, strbuf
        call WriteString

        ; Add Eol + continue
        call Crlf
        loop .str_loop
END_FCN _main


; BetterRandomRange( eax max, ebx min -> eax randomValue )
; returns a random 32-bit integer in [min, max)
DECL_FCN BetterRandomRange
    push ebx          ; save min
    sub eax, ebx      ; N = (max - min)
    call RandomRange  ; x = RandomRange(N)
    pop ebx           ; restore min
    add eax, ebx      ; x += min
END_FCN  BetterRandomRange


; CreateRandomString( eax maxLength, esi outStr )
; creates a random string 0-maxLength chars long, containing randomized 
; uppercase ascii letters.
DECL_FCN CreateRandomString
    push ecx          ; save registers
    push ebx

    call RandomRange  ; count = RandomRange( maxLength )
    mov ecx, eax      ; store in ecx; loop count times.
    .chrLoop:
        mov ebx, 'A'  ; x = BetterRandomRange('A', 'Z')
        mov eax, 'Z'
        call BetterRandomRange
        mov [esi], al ; *(outStr++) = (char)(x)
        inc esi
        loop .chrLoop
    pop ebx           ; restore registers
    pop ecx
END_FCN CreateRandomString

