;
; asmlib/src/algorithms/random.inc
;

section .text
; lcgNextRand( eax value -> eax nextValue )
; Generates a random number in the range [0, 2^31) using a 
; linear congruental generator. Uses coefficients from the 
; c standard library.
; Does NOT use an internal seed (pass the seed value in eax).
; See lcgRand32 and lcgRandRange for more usable versions.
;
DECL_FCN lcgNextRand
    push edx
    mov edx, 1103515245  ; multiplier coefficient form the c standard library
    mul edx
    add eax, 12345       ; additive coefficient from the c standard library
    and eax, 0x7fffffff  ; clamp to [0, 2^31] for some reason...?
    pop edx
END_FCN  lcgNextRand

section .data
    lcg_seed: dd 0
section .text

%macro LCG_SET_SEED 1
    mov [lcg_seed], %1
%endmacro
%macro LCG_GET_SEED 1
    mov %1, [lcg_seed]
%endmacro

; lcgRand32 (-> eax randomValue)
; Generates a random 32-bit integer.
DECL_FCN lcgRand32
    LCG_GET_SEED eax
    call lcgNextRand
    LCG_SET_SEED eax
END_FCN  lcgRand32

; lcgRandRange( eax upBound -> eax randomValue )
; Generates a random integer in the range [0, eax).
; Uses the internal seed associated with LCG_GET_SEED / LCG_SET_SEED
DECL_FCN lcgRandRange
    push ebx            ; save registers
    push edx
    push eax            ; save up bound

    LCG_GET_SEED eax    ; get random number on [0, 2^31)
    call lcgNextRand
    LCG_SET_SEED eax

    pop ebx             ; restore up bound
    xor edx, edx        ; divide (edx:eax) /= ebx
    div ebx             ; after div, eax = quot, edx = rem

    mov eax, edx        ; the remainder is our result, so store that in eax

    pop edx             ; restore registers
    pop ebx
END_FCN lcgRandRange
