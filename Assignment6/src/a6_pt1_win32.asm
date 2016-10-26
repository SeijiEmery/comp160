;
; Assignment 6, part 1
;   Encrypts / decrypts a string using an encryption key (plaintext password) 
;   and XOR-ing algorithm.
;

INCLUDE Irvine32.inc
INCLUDE Macros.inc

STRBUF_SIZE equ 1024
.data
    ; String literals for prompts, etc
    lit_plainTextPrompt  BYTE "Enter plain text: ",0
    lit_encryptKeyPrompt BYTE "Enter encryption key: ",0
    lit_displayCypher    BYTE "Cypher text: ",0
    lit_displayDecrypted BYTE "Decrypted:   ",0

    ; Temp variables we use in xorEncryptDemo:
    ; Worth putting here since this entire data segment will fit in cache.
    plainTextPtr  DWORD 0
    plainTextSize DWORD 0
    encryptKeyPtr DWORD 0

    ; Temp string buffer
    strbuf BYTE STRBUF_SIZE DUP ?
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


; Using Irvine32 I/O, prompt user to input a plain text + password, 
; call xorEncrypt to encode / decode this string, and display results.
xorEncryptDemo PROC USES esi edi edx eax ecx
    push ebp        ; save stack frame
    mov  ebp, esp

    ; Prompt user for plain text.
    mov edx, OFFSET lit_plainTextPrompt
    call WriteString

    ; Fetch input
    mov edx, OFFSET strbuf
    mov ecx, STRBUF_SIZE
    call ReadString
    call Crlf

    ; Save pointer + size of plaintext string, and write '\0' to end of string
    mov [plainTextPtr],  edx
    mov [plainTextSize], ecx
    mov BYTE PTR [edx + ecx], 0

    ; Prompt user for encrypt key
    mov edx, OFFSET lit_encryptKeyPrompt
    call WriteString

    ; Fetch input. We'll reuse strbuf, which means we'll need to adjust the
    ; ReadString ptr + size so we don't overwrite the plaintext string.
    mov edx, OFFSET strbuf
    add edx, [plainTextSize]
    inc edx

    mov ecx, STRBUF_SIZE
    sub ecx, [plainTextSize]
    dec ecx

    call ReadString
    call Crlf

    ; Save pointer; write '\0' to end of both strings.
    mov [encryptKeyPtr], edx
    mov BYTE PTR [edx + ecx], 0

    ; Call xorEncrypt to encrypt string
    mov edi, [plainTextPtr]
    mov ecx, [plainTextSize]
    mov esi, [encryptKeyPtr]
    call xorEncrypt

    ; Display result
    mov edx, OFFSET lit_displayCypher
    call WriteString
    mov edx, OFFSET plainTextPtr
    call WriteString
    call Crlf

    ; Call xorEncrypt to decrypt string
    mov edi, [plainTextPtr]
    mov ecx, [plainTextSize]
    mov esi, [encryptKeyPtr]
    call xorEncrypt

    ; Display result
    mov edx, OFFSET lit_displayDecrypted
    call WriteString
    mov edx, OFFSET plainTextPtr
    call WriteString
    call Crlf

    mov  esp, ebp   ; restore stack frame + return
    pop  ebp
    ret
xorEncryptDemo ENDP

main PROC
    call xorEncryptDemo

    ; Calling ReadChar() to force program to wait, since exit doesn't always
    ; seem to wait for input (bug). Press return to exit.
    call ReadChar
    exit
main ENDP
END main