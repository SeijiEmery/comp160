; Assignment 7, part 1
;   Encrypts / decrypts a string using a fixed encryption key + bitwise
;   rotation algorithm.
;
; Target platform: osx, 32-bit
;   depends on asmlib (../asmlib/)
;   uses rake (a ruby-based build system) for nasm builds
;
; Author: Seiji Emery (student: M00202623)
; Creation Date:  11/21/16
; Revisions, etc: https://github.com/SeijiEmery/comp160/tree/master/Assignment7
;

%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

STRBUF_SIZE equ 4096
section .bss
    ; Temp string buffer
    strbuf resb STRBUF_SIZE
section .data
    ; Rotation key (hardcoded)
    ; positive: rotate right, negative: rotate left; reversed for decrypt.
    key: db -5, 3, 2, -3, 0, 5, 2, -4, 7, 9
    .length: equ $ - key
section .text

;
; Encryption functions:
;

; To simplify the implementation, encryption / decryption is implemented as a
; single function (doEncrypt), which takes two function pointers that implement
; rotateLeft / rotateRight operations. For encrypt, we pass them in one order
; (positive key value => rotateRight, negative key value => rotateLeft), and 
; for decrypt we reverse them.

rotateLeft: 
    rol byte [edi], cl
    ret
rotateRight:
    ror byte [edi], cl
    ret

%define ROT_PLUS [ebp - 4]
%define ROT_NEG  [ebp - 8]

; RotateCypher_encrypt
;   inout edi plaintext => encrypted string
;   in    ecx string length
DECL_FCN RotateCypher_encrypt
    sub esp, 8
    mov ROT_PLUS, dword rotateRight
    mov ROT_NEG,  dword rotateLeft
    call RotateCypher_doEncrypt
END_FCN  RotateCypher_encrypt

; RotateCypher_decrypt
;   inout edi encrypted string => plaintext
;   in    ecx string length
DECL_FCN RotateCypher_decrypt
    sub esp, 8
    mov ROT_PLUS, dword rotateLeft
    mov ROT_NEG,  dword rotateRight
    call RotateCypher_doEncrypt
END_FCN  RotateCypher_decrypt

; RotateCypher_doEncrypt
;   inout  edi  plaintext <=> encrypted string
;   in     ecx  string length
;   in     ebp: ROT_PLUS / ROT_NEG function pointers (to do rotation)
RotateCypher_doEncrypt:
    push eax  ; Save registers
    push edx 
    push esi
    push edi

    ; Store string length in edx, since we're using cl for rotate instructions
    mov  edx, ecx     
    jmp .mainLoop
    .end:
        pop edi  ; Restore registers
        pop esi
        pop edx
        pop eax
        ret
    .mainLoop:
        ; Loop is broken into two parts:
        ; – rotateLoop iterates over min(remaining_bytes, key.size) bytes,
        ;   and does actual rotation w/ the encryption key (esi), and text pointer (edi).
        ; – mainLoop resets the encryption key ptr (esi), and runs rotateLoop
        ;   until remaining_bytes (edx) == 0.

        mov esi, key         ; reset key string (esi) to start
        mov eax, edx         ; set inner loop counter to the remaining # of bytes
        sub edx, key.length  ; reduce outer loop counter by key.length 
        jg  .clampToLength   ; if eax = edx < key.length, clamp to key.length

        test eax, eax        ; check for termination condition (inner loop counter == 0)
        jle .end
        jmp .rotateLoop      ; skip clamp() code
        .clampToLength:
            mov eax, key.length
        .rotateLoop:         ; repeat until inner loop counter == 0, then reset in mainLoop + continue
            mov cl, [esi]    ; load byte from encryption key
            inc esi
            cmp cl, 0        ; if key value negative, call ROT_NEG, else ROT_PLUS
            jl .rotateNegative
            .rotatePositive:
                push dword .endRotate  ; call ROT_PLUS, w/ return address set to .endRotate
                jmp  ROT_PLUS          ; (skips an extra ret + jmp)
            .rotateNegative:
                neg cl        ; negative, so negate => positive cl
                call ROT_NEG
            .endRotate:
            inc edi          ; advance text ptr + inner loop count
            dec eax
            jg .rotateLoop
            jmp  .mainLoop

;
; Helper functions:
;

; promptStr
;   in    edx  prompt_string
;   inout edi  buffer_ptr
;   in    ecx  buffer_size
;   out   ecx  read_bytes
promptStr:
    call WriteString        ; write prompt string 
    mov edx, edi
    call ReadString         ; read input string
    mov [edi + eax], byte 0 ; write string terminator (important!)
    mov ecx, eax            ; set ecx = input length 
    dec ecx
    ret

;
; Macros (wrap promptStr / WriteString)
;

; PROMPT_STR( string_literal, buffer_offset )
%macro PROMPT_STR 2
section .data
    DECL_STRING %%prompt, %1
section .text
    mov edx, %%prompt
    mov edi, strbuf
    add edi, %2
    mov ecx, STRBUF_SIZE
    sub ecx, %2
    call promptStr
%endmacro

; WRITE_STR( string_ptr )
%macro WRITE_STR 1
    mov edx, %1
    call WriteString
%endmacro

; WRITE_LIT( string_literal )
%macro WRITE_LIT 1
section .data
    DECL_STRING %%str, %1
section .text
    WRITE_STR %%str
%endmacro


;
; Program implementation:
;

; Prompt for plaintext, encrypt + print encrypted text, and decrypt + print decrypted text.
DECL_FCN rotateEncryptDemo
    sub esp, 16
    %define plaintextStr [ebp - 4]
    %define plaintextLen [ebp - 8]

    PROMPT_STR "Enter plaintext: ", dword 0
    mov plaintextStr, edi
    mov plaintextLen, ecx
   
    call RotateCypher_encrypt
    WRITE_LIT "Encrypted:       "
    WRITE_STR plaintextStr
    call Crlf

    mov edi, plaintextStr
    mov ecx, plaintextLen
    call RotateCypher_decrypt
    WRITE_LIT "Decrypted:       "
    WRITE_STR plaintextStr
    call Crlf
END_FCN rotateEncryptDemo

_main:
    call rotateEncryptDemo
    ret
