; Assignment 7, part 2
;   Implements an AddPackedDecimal function to add arbitrary-length packed 
;   decimal integers, using the daa + adc instructions.
;
;   This program executes AddPackedDecimal with 3 hardcoded argument sets
;   and prints the result.
;
; Target platform: osx, 32-bit
;   depends on asmlib (../asmlib/)
;   uses rake (a ruby-based build system) for nasm builds
;
; Author: Seiji Emery (student: M00202623)
; Creation Date:  11/23/16
; Revisions, etc: https://github.com/SeijiEmery/comp160/tree/master/Assignment7
;

; Include asmlib/osx32/irvine32.inc
; Tell asmlib to define a 'start' symbol for us, which calls _main() + handles 
; exit, etc. Note: public symbols start w/ underscores on osx / nasm.
%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

section .data

; Encapsulates data to be passed to / from AddPackedDecimal:
;   – Num bytes of each packed integer
;   – Arguments (binary packed decimal) + storage for result:
;        result = AddPackedDecimal(a, b)
;   – Expected result (we print both computed + expected results w/ visual comparison)
packed1:
    .bytes:    equ 2
    .a:        dw 0x4536,0      ; 4,536
    .b:        dw 0x7207,0      ; 7,207
    .result:   dw 0,0
    .expected: dw 0x1743,0x1    ; 11,743
packed2:
    .bytes:    equ 4
    .a:        dd 0x67345620,0  ; 67,345,620
    .b:        dd 0x54496342,0  ; 54,496,342
    .result:   dd 0,0
    .expected: dd 0x21841962,0x1 ; 121,841,962
packed3:
    .bytes:    equ 8
    .a:        dq 0x6734562000346521,0 ; 6,734,562,000,346,521
    .b:        dq 0x5449634205738261,0 ; 5,449,634,205,738,261
    .result:   dq 0,0
    .expected: dq 0x2184196206084782,0x1 ; 12,184,196,206,084,782

; String literals used in the program.
lit_descrip: db 10
db "This program implements addition of arbitrary-length packed decimal integers",10
db "using the x86 daa + adc instructions, as demonstrated by the following examples:",10,0

lit_plus:     db " + ",0
lit_eq:       db " = ",0
lit_result:   db "result:   ",0
lit_expected: db "expected: ",0

; Thousands decimal separator
DECIMAL_SEP_INTERVAL equ 3
DECIMAL_SEP_CHR      equ ','

; Helper macro
%macro WRITE_ADD_PACKED 1
    call Crlf

    ; Call DoAddPacked to print args and compute + display result.
    mov eax, %1.a
    mov ebx, %1.b
    mov edx, %1.result
    mov ecx, %1.bytes
    call DoAddPacked

    ; Display result (again), for side-by-side comparison w/ expected result
    mov edx, lit_result
    call WriteString
    mov esi, %1.result
    mov ecx, %1.bytes + 1
    call WritePackedDecimal
    call Crlf

    ; Display expected result
    mov edx, lit_expected
    call WriteString
    mov esi, %1.expected
    mov ecx, %1.bytes + 1
    call WritePackedDecimal
    call Crlf
%endmacro

; main() function
section .text
DECL_FCN _main
    mov edx, lit_descrip
    call WriteString

    WRITE_ADD_PACKED packed1
    WRITE_ADD_PACKED packed2
    WRITE_ADD_PACKED packed3
END_FCN  _main

; Note on functions -- I'm using a custom calling convention where:
; – Arguments are passed in registers, not the stack
; – All registers are assumed non-volatile and must be saved by the
;   callee unless marked otherwise.
; – All arguments (registers) are documented as following:
;   <usage> <register> <optional-type-info> <name>
; 
; Where usage is as follows:
;   – in: used as input parameter (may be a pointer / value type); volatile output
;   – out: used as output parameter (may be a pointer / value type); volatile input
;   – inout: used as input/output parameter. Value is stable.
;   – local / volatile: not a parameter, but used as a local variable w/out
;     saving state; volatile in/out
;
; There are other semantics for stack variables, which I won't go into here.
;
; Any registers marked as "volatile" must be caller-saved for their value
; to be preserved; I stick pretty closely to this standard, and the documentation
; (of asmlib) "should" be accurate.
;


; DoAddPacked: Displays + executes AddPackedDecimal operation.
;   in eax ptr-to-packed-int a
;   in ebx ptr-to-packed-int b
;   in edx ptr-to-packed-int result
;   in ecx num_bytes
DoAddPacked:
    push esi
    push edx

    mov esi, eax
    call WritePackedDecimal

    mov edx, lit_plus
    call WriteString

    mov esi, ebx
    call WritePackedDecimal

    pop edx
    call AddPackedDecimal
    push edx

    mov edx, lit_eq
    call WriteString

    pop edx
    add ecx, 1
    mov esi, edx
    call WritePackedDecimal
    call Crlf

    pop esi
    ret

; AddPackedDecimal: Executes result = (a + b) for packed decimal for num_bytes
; long arrays of packed decimal integers.
;   inout eax ptr-to-packed-int a
;   inout ebx ptr-to-packed-int b
;   inout edx ptr-to-packed-int result
;   inout ecx num_bytes
AddPackedDecimal:
    push esi
    push edi
    push edx
    push ecx

    mov esi, eax
    mov edi, ebx

    xor eax, eax
    add eax, 0
    .addLoop:
        mov al, [esi]
        adc al, [edi]
        daa
        mov [edx], al

        inc esi
        inc edi
        inc edx
        
        dec ecx
        jge .addLoop
    .endLoop:

    pop ecx
    pop edx
    pop edi
    pop esi
    ret

wpd_bufSize: equ 4096
section .bss
    wpd_scratchBuffer: resb wpd_bufSize
section .text


; WritePackedDecimal: Writes a packed integer to stdout
;   inout esi ptr-to-packed-int
;   inout ecx num-bytes
WritePackedDecimal:
    pushad

    ; Copy digits to scratchBuffer
    ; (each byte is two digits, eg. 0x45 = '4','5')
    mov edi, wpd_scratchBuffer
    .copyDigitsToBuffer:
        ; Copy low digit
        mov al, [esi]
        and al, 0xf
        or  al, 0x30
        mov [edi], al
        inc edi

        ; Copy high digit
        mov al, [esi]
        shr al, 4
        or  al, 0x30
        mov [edi], al
        inc edi

        inc esi
        loop .copyDigitsToBuffer

    ; Walk back to the 1st non-zero digit (or the 1st zero if all zeros)
    .searchFirstNonZero:
        dec edi
        cmp [edi], byte 0x30
        jnz .endSearch

        cmp edi, ebx
        jg .searchFirstNonZero
    .endSearch:

    ; Finally, we write the final string:
    ; – Write backwards (we want high digits 1st, now low digits)
    ; – Convert to ASCII (still in BCD)
    ; – Add ',' digit separators

    ; Set pointers
    mov esi, edi
    add edi, 1

    ; Calculate num_digits
    mov ecx, esi
    add ecx, 2
    sub ecx, wpd_scratchBuffer

    xor edx, edx
    mov eax, ecx
    add eax, 1
    mov ebx, DECIMAL_SEP_INTERVAL
    idiv ebx

    mov ebx, edx
    inc ebx

    mov edx, edi

    .writeLoop:
        mov al, [esi]
        mov [edi], al
        dec esi
        inc edi

        sub ebx,1
        je .writeSep

        dec ecx
        jle .endLoop
        jmp .writeLoop
    .writeSep:
        mov ebx, DECIMAL_SEP_INTERVAL
        mov [edi], byte DECIMAL_SEP_CHR
        inc edi

        sub ecx, 1
        jg .writeLoop

        ; Last char written was a sep -- unwind!
        dec edi
    .endLoop:

    ; Write terminator + call WriteString (string src saved in edx)
    mov [edi-2], byte 0
    call WriteString

    popad
    ret
