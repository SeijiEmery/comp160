; Assignment 8, part 1
;   Implements + runs tests for a Euclidean GCD algorithm.
;
; Target platform: osx, 32-bit
;   depends on asmlib (../asmlib/)
;   uses rake (a ruby-based build system) for nasm builds
;
; Author: Seiji Emery (student: M00202623)
; Creation Date:  11/28/16
; Revisions, etc: https://github.com/SeijiEmery/comp160/tree/master/Assignment7
;

%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

section .data
gcd_inputs:
    dd 35, 15
    dd 72, 18
    dd 31, 17
    dd 128, 640
    dd 121, 88
    .length: equ 5

lit_gcd_lp: db "gcd(",0
lit_gcd_cm: db ", ",0
lit_gcd_rp: db ") = ",0

section .text
run_gcd_tests:
    pushad
    mov esi, gcd_inputs
    mov ecx, gcd_inputs.length
    .testLoop
        mov eax, [esi]
        mov ebx, [esi + 4]
        add esi, 8
        call print_gcd
        loop .testLoop
    popad
    ret

; print_gcd: Prints gcd arguments + result (calls gcd(a, b)).
;   in eax a
;   in ebx b
print_gcd:
    ; Write args: "gcd(%d, %d) = %d\n"
    push eax
    mov edx, lit_gcd_lp
    call WriteString
    call WriteDec
    mov edx, lit_gcd_cm
    call WriteString
    mov eax, ebx
    call WriteDec
    mov edx, lit_gcd_rp
    call WriteString
    pop eax

    ; call gcd() + print result
    call gcd
    call WriteDec
    call Crlf
    ret

; gcd: Calculates the greatest common denominator of 2 unsigned numbers.
;   in eax a
;   in ebx b
;   out eax result
;   local edx (volatile)
;
gcd:
    cmp eax, ebx       ; if a < b,
    jge .noswap
        xchg eax, ebx  ; swap(a, b)
    .noswap:

    .div_loop:
        xor edx, edx
        idiv ebx       ; let r = a % b
        mov eax, ebx   ; let a = b, b = r
        mov ebx, edx
        test edx, edx  ; if r == 0, return a.
        jnz .div_loop
    ret

DECL_FCN _main
    call run_gcd_tests
END_FCN  _main


