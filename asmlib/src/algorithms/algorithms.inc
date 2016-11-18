

; function strncpy
;   inout kdi dst_ptr
;   in    ksi src_ptr
;   inout kcx dst_remaining_size
strncpy:
    push kax
    xor kax, kax
    .l1:
        dec kcx
        jl .l1_end

        mov al, [ksi]
        test al, al
        jz .l1_end

        mov [kdi], al
        inc ksi
        inc kdi
        jmp .l1
    .l1_end:
    pop kax
    ret

; function strlen
;   inout ksi str
;   out   kcx length
strlen:
    push ksi
    mov kcx, -1
    sub al, al
    cld
    repne scasb
    not kcx
    dec kcx
    pop ksi
    ret

; memcmp
;   inout kdi mem1
;   in    ksi mem2
;   in    kcx num_bytes
; memcmp:
;     cld
;     cmp rcx, rcx
;     repe cmpsb
;     ret

