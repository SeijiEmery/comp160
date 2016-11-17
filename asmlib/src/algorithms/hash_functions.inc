;
; hash_functions.inc
; 
; Implements 2 string hash functions: djb2, sbdm, courtesy of
; http://www.cse.yorku.ca/~oz/hash.htm
;
; Requires the following includes:
;   platform/nasm**.inc
;   platform/nasm_macros.inc
;

; Note: uses cross-platform registers kax, kdx, etc., defined in
;   platform/nasm32.inc / platform/nasm64.inc, which expand to
;   eax / rax, edx / rdx, etc., depending on which was included.
;
; This is so that we can write cross-platform algorithms (32 / 64 bit)
; without having to worry about pointer sizes, etc.
;

%define hash_string hash_djb2

; djb2 string hash function
;   in  ksi string_ptr
;   in  ecx string_length
;   out kax hash_value
; Implements the following hash function:
;   hash(i) = hash(i-1) * 33 ^ str[i]
;   hash(0) = 5381
hash_djb2:
    mov  kax, 5381
    push kdx            ; reserve 1 register: kdx
    test ecx, ecx
    jz  .exit
    .loop:
        mov kdx, kax    ; kax = kax * 33 ^ str[i]
        shl kdx, 5      ; =>  kax = (kax + kax * 32) ^ str[i]
        add kax, kdx    ; =>  kax += (kax << 5) ^ str[i]
        xor kax, char_t [ksi]
        add ksi, TYPE_SIZE(char_t)
        loop ecx
    .exit:
    pop kdx
    ret

; sdbm string hash function
;   in  ksi string_ptr
;   in  ecx string_length (in bytes)
;   out kax hash_value
; Implements the following hash function:
;   hash(i) = hash(i-1) * 65599 + str[i]
;   hash(0) = 0
hash_sbdm:
    xor kax, kax
    push kdx           ; reserve 2 registers: kdx, kbx
    push kbx
    test ecx, ecx
    jz .exit
    .loop:
        mov kdx, kax   ; kax = kax * 65599 + str[i]
        mov kbx, kax   ; => kax = (kax << 6 + kax << 16 - kax) + str[i]
        shl kdx, 6     ; where:  kdx = kax << 6
        shl kbx, 16    ;         kbx = kax << 16
        add kdx, kbx   ; => kax = (kdx + kbx - kax) + byte [ksi]
        sub kdx, kax
        add kdx, char_t [ksi]
        add ksi, TYPE_SIZE(char_t)
        mov kax, kdx
        loop ecx
    .exit:
    pop kbx
    pop kdx
    ret
