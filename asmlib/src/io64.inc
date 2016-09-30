
%macro WRITE_HEX_N 2
    push rax
    push rcx
    mov rax, %1
    mov rcx, %2
    call writeHex
    pop rax
    pop rcx
%endmacro

%macro WRITE_HEX_64 1
    WRITE_HEX_N %1 8
%endmacro

%macro WRITE_HEX_32 1
    WRITE_HEX_N %1 4
%endmacro

%macro WRITE_HEX_16 1
    WRITE_HEX_N %1 2
%endmacro

%macro WRITE_HEX_8 1
    WRITE_HEX_N %1 1
%endmacro

%macro WRITE_EOL
    mov [rdi], BYTE 10
    inc rdi
%endmacro

%macro WRITE_0x
    mov [rdi+0], BYTE 48
    mov [rdi+1], BYTE 120
    add rdi, 2
%endmacro

%macro WRITE_STR 2
    push rsi
    push rcx
    mov rsi, %1
    mov rcx, %2
    call writeAsciiStr
    pop rcx
    pop rsi
%endmacro

%macro WRITE_STRZ 1
    push rsi
    mov rsi, %1
    call writeAsciiStrz
    pop rsi
%endmacro

%macro WRITE_DEC 1
    push rax
    mov rax, %1
    call writeDecimal
    pop rax
%endmacro

; Implementation note: All write*** integer algorithms work backwards:
; we repeatedly divide the integer by its base, and write the modulo
; to some output (the rdi pointer).
;
; This produces _reversed_ output, since we're writing what should be
; the last / lowest digit first (and we're used to reading left -> right,
; not vice versa), so the output will need to be re-reversed at some point.
;
; For writeHex <N bytes>, we know how many characters we're writing ahead
; of time (it's num_bytes * 2, since each digit repr by a 2-digit hex #),
; so we can just advance rdi by rcx * 2, and write the digits in reverse.
;
; For writeDecimal, we don't know how many characters we'll be writing,
; so we just write each digit out reversed, then explicitely re-reverse
; the output in a second loop.
;

; Writes rcx bytes from the value in rax to rdi as a hexadecimal integer.
DECL_FCN writeHex
    cmp rcx, 8    ; clamp rcx to [0, 8].
    jg  .clampTo8
    jmp .skip
    .clampTo8:
        mov rcx, 8
    .skip:

    shl rcx, 1     ; rcx *= 2
    push rcx
    add rdi, rcx   ; rdi += num_bytes * 2

    .writeHalfByte:
        dec rdi
        mov dl, al     ; load lowest byte of rax into dl
        and dl, 0xf    ; and use bitwise op to get lowest 4 bits
        cmp dl, 0xa
        jl .l1
             add dl, 0x7    ; if dl >= 10, add 0x37 (10 + 0x37 = 'A')
        .l1: add dl, 0x30   ; if dl <  10, add 0x30 (10 + 0x30 = '0')
        mov [rdi], dl
        shr rax, 4      ; 
        loop .writeHalfByte

    pop rcx
    add rdi, rcx  ; rdi += num_bytes * 2
END_FCN writeHex

DECL_FCN writeAsciiStrz
    push rax
    .l1:
        mov al, [rsi]
        cmp al, 0
        je .end
        mov [rdi], al
        inc rsi
        inc rdi
        jmp .l1
    .end:
    pop rax
END_FCN writeAsciiStrz

DECL_FCN writeAsciiStr
    push rax
    cmp rcx, 0
    jle .end
    .l1:
        mov al, [rsi]
        mov [rdi], al
        inc rsi
        inc rdi
        loop .l1
    .end:
    pop rax
END_FCN writeAsciiStr

DECL_FCN writeDecimal
    push rbx
    push rdx
    push rsi

    cmp rax, 0     ; special case for rax == 0 (write '0' and return)
    je  .writeZero

    mov rbx, 10
    push rdi       ; save start ptr
    .writeDigitsReversed:
        xor rdx, rdx    ; clear rdx
        idiv rbx        ; rdx:rax /= rbx (10). quotient stored in rax, modulo in rdx.
        add dl, 0x30    ; [0-9] + 0x30 => ascii '0'-'9'
        mov [rdi], dl   ; write to rdi
        inc rdi
        cmp rax, 0      ; repeat until rax == 0
        jne .writeDigitsReversed

    pop rsi        ; restore start ptr (rsi) and save end ptr (rdi)
    push rdi
    .reverseDigits:
        cmp rsi, rdi    ; until rsi >= rdi:
        jge .endReverse

        mov al, [rsi]   ; swap [rsi], [rdi]
        mov dl, [rdi]
        mov [rsi], dl
        mov [rdi], al
        inc rsi         ; ++rsi, --rdi
        dec rdi
        jmp .reverseDigits
    .endReverse:
    pop rdi        ; restore end ptr after reversal
    jmp .end

    .writeZero:
        mov [rdi], byte 0x30 ; write '0'
        inc rdi
        jmp .end

    .end:
    pop rsi
    pop rdx
    pop rbx
END_FCN writeDecimal
