;
; asmlib/algorithms/io.inc
;
; Requires the following includes:
;   platform/nasm**.inc
;   platform/nasm_macros.inc
;


section .text

; flushIO:
;   in kax fd
;   in kdi buffer_ptr
;   in ksi buffer_start
;   in kcx buffer_size
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
; to some output (the kdi pointer).
;
; This produces _reversed_ output, since we're writing what should be
; the last / lowest digit first (and we're used to reading left -> right,
; not vice versa), so the output will need to be re-reversed at some point.
;
; For writeHex <N bytes>, we know how many characters we're writing ahead
; of time (it's num_bytes * 2, since each digit repr by a 2-digit hex #),
; so we can just advance kdi by kcx * 2, and write the digits in reverse.
;
; For writeDecimal, we don't know how many characters we'll be writing,
; so we just write each digit out reversed, then explicitely re-reverse
; the output in a second loop.
;

; Writes kcx bytes from the value in kax to kdi as a hexadecimal integer.

; writeHex( kax value, kcx num_digits, kdi out_buffer )
;   does not preserve kax / kcx (use WRITE_HEX_**** to preserve both)
DECL_FCN writeHex
    cmp kcx, 8    ; clamp kcx to [0, 8].
    jg  .clampTo8
    jmp .skip
    .clampTo8:
        mov kcx, 8
    .skip:

    shl kcx, 1     ; kcx *= 2
    push kcx
    add kdi, kcx   ; kdi += num_bytes * 2

    .writeHalfByte:
        dec kdi
        mov dl, al     ; load lowest byte of kax into dl
        and dl, 0xf    ; and use bitwise op to get lowest 4 bits
        cmp dl, 0xa
        jl .l1
             add dl, 0x7    ; if dl >= 10, add 0x37 (10 + 0x37 = 'A')
        .l1: add dl, 0x30   ; if dl <  10, add 0x30 (10 + 0x30 = '0')
        mov [kdi], dl
        shr kax, 4     ; kax /= 16
        loop .writeHalfByte

    pop kcx
    add kdi, kcx  ; kdi += num_bytes * 2
END_FCN writeHex

; writeAsciiStrz( ksi str, kdi out_buffer )
;   does not preserve ksi (use WRITE_STR for register preservation)
DECL_FCN writeAsciiStrz
    push kax
    .l1:
        mov al, [ksi]
        cmp al, 0
        je .end
        mov [kdi], al
        inc ksi
        inc kdi
        jmp .l1
    .end:
    pop kax
END_FCN writeAsciiStrz

; writeAsciiStrz( ksi str, kcx num_bytes, kdi out_buffer )
;   does not preserve ksi / kcx (use WRITE_STR for register preservation)
DECL_FCN writeAsciiStr
    push kax
    cmp kcx, 0
    jle .end
    .l1:
        mov al, [ksi]
        mov [kdi], al
        inc ksi
        inc kdi
        loop .l1
    .end:
    pop kax
END_FCN writeAsciiStr

; writeDecimal32( kax value, kdi out_buffer )
;   does not preserve kax (use WRITE_DEC for register preservation)
DECL_FCN writeDecimal32
    test kax, 0x80000000     ; Handle negative numbers:
    jz .isPositive
        xor kax, 0xffffffff
        inc kax
        mov [kdi], byte 45   ; negative sign '-'
        inc kdi
    .isPositive:
    call writeUnsignedDecimal32
END_FCN writeDecimal32


; writeUnsignedDkcimal32( kax value, kdi out_buffer )
;   does not preserve kax (use WRITE_DEC for register preservation)
DECL_FCN writeUnsignedDecimal32
    push kbx
    push kdx
    push ksi

    cmp kax, 0     ; special case for kax == 0 (write '0' and return)
    je  .writeZero

    mov kbx, 10
    push kdi       ; save start ptr
    .writeDigitsReversed:
        xor kdx, kdx    ; clear kdx
        idiv kbx        ; kdx:kax /= kbx (10). quotient stored in kax, modulo in kdx.
        add dl, 0x30    ; [0-9] + 0x30 => ascii '0'-'9'
        mov [kdi], dl   ; write to kdi
        inc kdi
        cmp kax, 0      ; repeat until kax == 0
        jne .writeDigitsReversed

    pop ksi        ; restore start ptr (ksi) and save end ptr (kdi)
    push kdi
    dec kdi        ; must move back 1 for loop (normally, kdi points to the 
                   ; _next_ chr, but here we want it to point to the last written chr)
    .reverseDigits:
        cmp ksi, kdi    ; until ksi >= kdi:
        jge .endReverse

        mov al, [ksi]   ; swap [ksi], [kdi]
        mov dl, [kdi]
        mov [ksi], dl
        mov [kdi], al
        inc ksi         ; ++ksi, --kdi
        dec kdi
        jmp .reverseDigits
    .endReverse:
    pop kdi        ; restore end ptr after reversal
    jmp .end

    .writeZero:
        mov [kdi], byte 0x30 ; write '0'
        inc kdi
        jmp .end

    .end:
    pop ksi
    pop kdx
    pop kbx
END_FCN writeDecimal32











