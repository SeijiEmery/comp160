
;
; Macros
;

%macro DECL_FCN 1
%1:
    push rbp
    mov rbp, rsp
%endmacro
%macro END_FCN 1
    mov rsp, rbp
    pop rbp
    ret
%endmacro
%macro DECL_STRZ 1
    .ptr:    db %1,0
    .length: equ $ - .ptr
%endmacro

%macro RDI_WRITE_CHR 1
    mov [rdi], byte %1
    inc rdi
%endmacro
%macro RDI_WRITE_LN 0
    RDI_WRITE_CHR 10
%endmacro
%macro RDI_WRITE_STR 1
    mov rsi, %1
    mov rcx, %1.length
    call strncpy
%endmacro
%macro RDI_WRITE_LIT 1
    section .data
        %%lit:
        %%lit.ptr:    db %1,0
        %%lit.length: equ $ - %%lit.ptr
    section .text
        RDI_WRITE_STR %%lit
%endmacro
%macro RDI_WRITE_UINT 1
    mov rax, %1
    call writeUint64
%endmacro
%macro RDI_WRITE_INT 1
    mov rax, %1
    call writeInt64
%endmacro

%macro RDI_SETUP_IO 2
    mov %1, %2
%endmacro
%macro RDI_FLUSH_LN 1
    RDI_WRITE_LN
    RDI_FLUSH %1
%endmacro
%macro RDI_FLUSH 1
    push rsi
    mov  rsi, %1
    call rdiFlushBuffer
    pop  rsi
%endmacro

; rdiFlushBuffer ( rdi ptr, rsi source_buffer )
rdiFlushBuffer:
    sub rdi, rsi
    mov rdx, 1
    xchg rdx, rdi
    push rsi
    call syscall_write
    pop rdi
    ret


;
; System calls:
;
SYS_CLASS_UNIX equ 0x2000000
%macro DECL_SYSCALL 2
%1:
    mov rax, %2
    syscall
    ret
%endmacro

; syscall_write ( rdi fd, rsi buffer, rdx size ) => rax bytes_written
DECL_SYSCALL syscall_write, {SYS_CLASS_UNIX | 4}

; syscall_read ( rdi fd, rsi buffer, rdx size ) => rax bytes_written
DECL_SYSCALL syscall_read, {SYS_CLASS_UNIX | 3}

; syscall_exit ( rdi exit_code )
DECL_SYSCALL syscall_exit, {SYS_CLASS_UNIX | 1}


%macro DECL_IO_WRITE_INT_FCN 2
%1:
    push rbx
    mov rbx, %2
    call io_writeInt
    pop rbx
    ret
%endmacro

DECL_IO_WRITE_INT_FCN io_writeInt64, {IO_FLAGS_SIGNED_INT | IO_FLAGS_I64_T | 10}
DECL_IO_WRITE_INT_FCN io_writeInt32, {IO_FLAGS_SIGNED_INT | IO_FLAGS_I32_T | 10}
DECL_IO_WRITE_INT_FCN io_writeInt16, {IO_FLAGS_SIGNED_INT | IO_FLAGS_I16_T | 10}
DECL_IO_WRITE_INT_FCN io_writeInt8,  {IO_FLAGS_SIGNED_INT | IO_FLAGS_I8_T  | 10}

DECL_IO_WRITE_INT_FCN io_writeUInt64, {IO_FLAGS_I64_T | 10}
DECL_IO_WRITE_INT_FCN io_writeUInt32, {IO_FLAGS_I32_T | 10}
DECL_IO_WRITE_INT_FCN io_writeUInt16, {IO_FLAGS_I16_T | 10}
DECL_IO_WRITE_INT_FCN io_writeUInt8,  {IO_FLAGS_I8_T  | 10}

DECL_IO_WRITE_INT_FCN io_writeHex64, {IO_FLAGS_I64_T | 16}
DECL_IO_WRITE_INT_FCN io_writeHex32, {IO_FLAGS_I32_T | 16}
DECL_IO_WRITE_INT_FCN io_writeHex16, {IO_FLAGS_I16_T | 16}
DECL_IO_WRITE_INT_FCN io_writeHex8,  {IO_FLAGS_I8_T  | 16}

IO_FLAGS_SIGNED_INT equ 0x80000
IO_FLAGS_I8_T       equ 0x30000
IO_FLAGS_I16_T      equ 0x20000
IO_FLAGS_I32_T      equ 0x10000
IO_FLAGS_I64_T      equ 0x00000

;
; Generic writeInt function that can handle signed + unsigned values of 
; various types, and supports arbitrary bases. (eg. base 10, 16; can technically
; be any value > 1 -- binary (base 2) would be inefficient, but would work...).
;

; io_writeInt ( in rax value, in bx base, in ebx:32+ flags, inout rdi string_buffer )
io_writeInt:
    section .data
        .bitmaskTbl: dq 0xffffffffffffffff, 0xffffffff, 0xffff, 0xff 
        .signBitTbl: dq 0x8000000000000000, 0x80000000, 0x8000, 0x80
    section .text
    push rdx
    push rsi

    ; clamp register to type
    push   bx
    shr    ebx, 16
    and    ebx, 3

    lea edx, [rel .bitmaskTbl]
    and rax, [edx + ebx * 8]

    ; check signed...? 
    test ebx, 8
    jnz .noSign
        test rax, [edx + ebx * 8]
        jz .noSign

        lea edx, [rel .bitmaskTbl]
        xor rax, [edx + ebx * 8]
        inc rax

        RDI_WRITE_CHR '-'
    .noSign:
    xor rbx, rbx
    pop bx

    ; Write digits
    push rdi    ; save start ptr
    .writeDigitsReversed:
        xor rdx, rdx      ; clear rdx
        idiv rbx          ; rdx:rax /= rbx (10). quotient stored in rax, modulo in rdx
        add dl, 0x30
        cmp dl, 58
        jl .dec_chr       ; can assume this will branch predict...
            add dl, 8     ; convert from decimal to hex-base, or w/e.
        .dec_chr:
        mov [rdi], dl
        inc rdi
        test rax, rax
        jnz .writeDigitsReversed

    pop rsi     ; restore start ptr (rsi) and save end ptr (rdi)
    push rdi
    dec rdi
    .reverseDigits:
        cmp rsi, rdi
        jge .endReverse

        mov al, [rsi]
        mov dl, [rdi]
        mov [rsi], dl
        mov [rdi], al
        inc esi
        dec edi
        jmp .reverseDigits
    .endReverse:
    pop rdi
    jmp .end

    .writeZero:
        mov [rdi], byte 0x30
        inc rdi
        jmp .end
    .end:
    pop rsi
    pop rdx
    ret




strncpy:
    push rax
    xor  rax, rax
    .l1:
        dec rcx
        jl .l1_end

        mov  al, [rsi]
        test al, al
        jz .l1_end

        mov [rdi], al
        inc rsi
        inc rdi
        jmp .l1
    .l1_end:
    pop rax
    ret

















