;
; Assignment 6, part 1
;   Encrypts / decrypts a string using a string "password" and XOR-ing algorithm.
;

INCLUDE Irvine32.inc

.data
    lit_plainTextPrompt  BYTE "Enter plain text: ",0
    lit_encryptKeyPrompt BYTE "Enter encryption key: ",0
    lit_displayCypher    BYTE "Cypher text: ",0
    lit_displayDecrypted BYTE "Decrypted:   ",0
    STRBUF_SIZE equ 4096
.code

; Encrypt a string in-place using an encryption key (string) and XOR algorithm.
;   edi: source string
;   ecx: source string length
;   esi: null-terminated encryption key
xorEncrypt PROC USES eax ebx
    mov ebx, esi     ; save pointer to start of encryption key
    
    ; Sanity check arguments.
    cmp ecx, 0               ; Skip if string is empty (ecx == 0)
    jle L1_end
    cmp BYTE PTR [esi], 0   ; Skip if encryption key is empty (first byte is zero)
    jle L1_end
    L1:
        ; Load byte from encryption key string
        mov  al, BYTE PTR [esi]

        ; Wrap encryption key when we hit the last character
        test al,al
        jz   resetKeyStr
    L1_continue:

        ; xor src string w/ encryption key
        xor  BYTE PTR [edi], al

        ; Increment pointers + continue until ecx == 0
        inc  esi
        inc  edi
        loop L1
        jmp  L1_end
    resetKeyStr:
        mov esi, ebx
        jmp L1_continue
    L1_end:
    ret
xorEncrypt ENDP



















