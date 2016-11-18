;
; Assignment 6, part 1
;   Encrypts / decrypts a string using an encryption key (plaintext password) 
;   and XOR-ing algorithm.
;

%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

STRBUF_SIZE equ 4096
section .data
    ; String literals for prompts, etc
    lit_plainTextPrompt  db "Enter plain text:      ",0
    lit_encryptKeyPrompt db "Enter encryption key:  ",0
    lit_displayCypher    db "Cypher text:           ",0
    lit_displayDecrypted db "Decrypted:             ",0
section .bss
    ; Temp string buffer
    strbuf resb STRBUF_SIZE
section .text


; Encrypt a string in-place using an encryption key (string) and XOR algorithm.
;   edi: source string
;   ecx: source string length
;   esi: null-terminated encryption key
DECL_FCN xorEncrypt
    mov ebx, esi     ; save pointer to start of encryption key
    
    ; Sanity check arguments.
    cmp ecx, 0               ; Skip if string is empty (ecx == 0)
    jle .L1_end
    cmp [esi], byte 0   ; Skip if encryption key is empty (first byte is zero)
    jl .L1_end
    .L1:
        ; Load byte from encryption key string
        mov  al, [esi]

        ; Wrap encryption key when we hit the last character
        test al,al
        jz   .resetKeyStr
    .L1_continue:

        ; xor src string w/ encryption key
        xor  [edi], al

        ; Increment pointers + continue until ecx == 0
        inc  esi
        inc  edi
       
        loop .L1
        jmp  .L1_end
    .resetKeyStr:
        mov esi, ebx
        jmp .L1_continue
    .L1_end:
END_FCN xorEncrypt

%macro mWriteStr 1
    mov edx, %1
    call WriteString
%endmacro

; Using Irvine32 I/O, prompt user to input a plain text + password, 
; call xorEncrypt to encode / decode this string, and display results.
DECL_FCN xorEncryptDemo
    xor ecx, ecx
    sub esp, 16

    %define textStr    [ebp - 4]
    %define textLen    [ebp - 8]
    %define cryptStr [ebp - 12] 

    ; Prompt user for plain text.
    mWriteStr lit_plainTextPrompt

    ; Fetch input
    mov edx, strbuf
    mov ecx, STRBUF_SIZE
    call ReadString

    ; Save pointer + size of plaintext string, and write '\0' to end of string
    mov textStr, edx
    mov textLen, eax
    mov [edx + eax+1], byte 0

    ; Prompt user for encrypt key
    mWriteStr lit_encryptKeyPrompt

    ; Fetch input. We'll reuse strbuf, which means we'll need to adjust the
    ; ReadString ptr + size so we don't overwrite the plaintext string.
    
    mov edx, textStr
    add edx, textLen
    add edx, 2
    mov cryptStr, edx

    mov ecx, STRBUF_SIZE
    sub ecx, textLen
    sub ecx, 1

    call ReadString
    mov [edx + eax + 1], byte 0

    ; Call xorEncrypt to encrypt string
    mov edi, textStr
    mov ecx, textLen
    mov esi, cryptStr
    call xorEncrypt

    ; Display result
    mWriteStr lit_displayCypher
    mWriteStr textStr
    call Crlf

    ; Call xorEncrypt to decrypt string
    mov edi, textStr
    mov ecx, textLen
    mov esi, cryptStr
    call xorEncrypt

    ; Display result
    mWriteStr lit_displayDecrypted
    mWriteStr textStr
    call Crlf
END_FCN xorEncryptDemo

_main:
    call xorEncryptDemo
    mov eax, 0
    call _sys_exit
    ret
