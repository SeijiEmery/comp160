;
; asmlib/algorithms/io.inc
;
; Requires the following includes:
;   platform/nasm**.inc
;   platform/nasm_macros.inc
;

; flushIO:
;   in eax fd
;   in edi buffer_ptr
;   in esi buffer_start
;   in ecx buffer_size
flushIO:
    sub kdi, ksi
    jle .skip
        cmp kdi, kcx
        jle .sizeOk
        mov kdi, kcx
        .sizeOk:
        ; write( fd, buffer_start, buffer_used_length )
        EXEC_SYSCALL SYS_WRITE, kax, ksi, kdi
    .skip:
    ret

; Implementation note: All write*** integer algorithms work backwards:
; we repeatedly divide the integer by its base, and write the modulo
; to some output (the edi pointer).
;
; This produces _reversed_ output, since we're writing what should be
; the last / lowest digit first (and we're used to reading left -> right,
; not vice versa), so the output will need to be re-reversed at some point.
;
; For writeHex <N bytes>, we know how many characters we're writing ahead
; of time (it's num_bytes * 2, since each digit repr by a 2-digit hex #),
; so we can just advance edi by ecx * 2, and write the digits in reverse.
;
; For writeDecimal, we don't know how many characters we'll be writing,
; so we just write each digit out reversed, then explicitely re-reverse
; the output in a second loop.
;

; Writes ecx bytes from the value in eax to edi as a hexadecimal integer.

; writeHex( eax value, ecx num_digits, edi out_buffer )
;   does not preserve eax / ecx (use WRITE_HEX_**** to preserve both)
DECL_FCN writeHex
    cmp ecx, 8    ; clamp ecx to [0, 8].
    jg  .clampTo8
    jmp .skip
    .clampTo8:
        mov ecx, 8
    .skip:

    shl ecx, 1     ; ecx *= 2
    push ecx
    add edi, ecx   ; edi += num_bytes * 2

    .writeHalfByte:
        dec edi
        mov dl, al     ; load lowest byte of eax into dl
        and dl, 0xf    ; and use bitwise op to get lowest 4 bits
        cmp dl, 0xa
        jl .l1
             add dl, 0x7    ; if dl >= 10, add 0x37 (10 + 0x37 = 'A')
        .l1: add dl, 0x30   ; if dl <  10, add 0x30 (10 + 0x30 = '0')
        mov [edi], dl
        shr eax, 4     ; eax /= 16
        loop .writeHalfByte

    pop ecx
    add edi, ecx  ; edi += num_bytes * 2
END_FCN writeHex

; writeAsciiStrz( esi str, edi out_buffer )
;   does not preserve esi (use WRITE_STR for register preservation)
DECL_FCN writeAsciiStrz
    push eax
    .l1:
        mov al, [esi]
        cmp al, 0
        je .end
        mov [edi], al
        inc esi
        inc edi
        jmp .l1
    .end:
    pop eax
END_FCN writeAsciiStrz

; writeAsciiStrz( esi str, ecx num_bytes, edi out_buffer )
;   does not preserve esi / ecx (use WRITE_STR for register preservation)
DECL_FCN writeAsciiStr
    push eax
    cmp ecx, 0
    jle .end
    .l1:
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
        loop .l1
    .end:
    pop eax
END_FCN writeAsciiStr

; writeDecimal32( eax value, edi out_buffer )
;   does not preserve eax (use WRITE_DEC for register preservation)
DECL_FCN writeDecimal32
    test eax, 0x80000000     ; Handle negative numbers:
    jz .isPositive
        xor eax, 0xffffffff
        inc eax
        mov [edi], byte 45   ; negative sign '-'
        inc edi
    .isPositive:
    call writeUnsignedDecimal32
END_FCN writeDecimal32


; writeUnsignedDecimal32( eax value, edi out_buffer )
;   does not preserve eax (use WRITE_DEC for register preservation)
DECL_FCN writeUnsignedDecimal32
    push ebx
    push edx
    push esi

    cmp eax, 0     ; special case for eax == 0 (write '0' and return)
    je  .writeZero

    mov ebx, 10
    push edi       ; save start ptr
    .writeDigitsReversed:
        xor edx, edx    ; clear edx
        idiv ebx        ; edx:eax /= ebx (10). quotient stored in eax, modulo in edx.
        add dl, 0x30    ; [0-9] + 0x30 => ascii '0'-'9'
        mov [edi], dl   ; write to edi
        inc edi
        cmp eax, 0      ; repeat until eax == 0
        jne .writeDigitsReversed

    pop esi        ; restore start ptr (esi) and save end ptr (edi)
    push edi
    dec edi        ; must move back 1 for loop (normally, edi points to the 
                   ; _next_ chr, but here we want it to point to the last written chr)
    .reverseDigits:
        cmp esi, edi    ; until esi >= edi:
        jge .endReverse

        mov al, [esi]   ; swap [esi], [edi]
        mov dl, [edi]
        mov [esi], dl
        mov [edi], al
        inc esi         ; ++esi, --edi
        dec edi
        jmp .reverseDigits
    .endReverse:
    pop edi        ; restore end ptr after reversal
    jmp .end

    .writeZero:
        mov [edi], byte 0x30 ; write '0'
        inc edi
        jmp .end

    .end:
    pop esi
    pop edx
    pop ebx
END_FCN writeDecimal32











