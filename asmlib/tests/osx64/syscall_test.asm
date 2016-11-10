
%include "asmlib.inc"

global start
section .data
lit_helloMsg: DECL_STRZ {"Hello, World!",10}

section .bss
strbuf: resb 4096
    .length: equ 4096

section .text
start:
    call writeCommandlineArgs

    mov  rdi, 1
    mov  rsi, lit_helloMsg
    mov  rdx, lit_helloMsg.length
    call syscall_write

    mov  rdi, 1
    mov  rsi, strbuf
    mov  rdx, strbuf.length
    call syscall_read

    mov rdi, 1
    mov rsi, strbuf
    mov rdx, rax
    call syscall_write

    mov  rdi, 0
    call syscall_exit

section .bss
argc: resq 1
argv: resq 1
envp: resq 1

%macro movmem 2
    mov rax, %1
    mov %2, rax
%endmacro

section .text
writeln:
    mov [rdi], byte 10
    inc rdi

    lea rsi, [rel strbuf]
    sub rdi, rsi
    mov rdx, 1
    xchg rdx, rdi
    call syscall_write
    lea rdi, [rel strbuf]
    ret
setupIO:
    lea rdi, [rel strbuf]
    ret

%define writeChr RDI_WRITE_CHR
%define writeStr RDI_WRITE_STR
%define writeUint RDI_WRITE_UINT
%define writeLit  RDI_WRITE_LIT
; %define writeUint64 io_writeUInt64

DECL_FCN writeCommandlineArgs
    %define var_argc [rbp + 16]
    %define var_argv [rbp + 24]

    call setupIO
        writeLit "argc = "
        writeUint var_argc
        call writeln

        mov rbx, 0
        .writeArgs:
            mov rsi, [rbp + 24 + rbx * 8]
            test rsi, rsi
            jz   .endArgs

            push rsi
            writeLit "argv["
            writeUint rbx
            writeLit "] = "
            pop rsi

            mov rcx, rdi
            lea rax, [rel strbuf - 1024]
            sub rcx, rax
            call strncpy
            inc rbx
            call writeln
            jmp .writeArgs
        .endArgs:
        call writeln
END_FCN writeCommandlineArgs


; writeUint64 (rdi buffer, rax value )
writeUint64:
    push rbx
    push rdx
    push rsi

    test rax, rax
    jz .writeZero

    mov rbx, 10
    push rdi    ; save start ptr
    .writeDigitsReversed:
        xor rdx, rdx      ; clear rdx
        idiv rbx          ; rdx:rax /= rbx (10). quotient stored in rax, modulo in rdx
        add dl, 0x30
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
    pop rbx
    ret

; SYS_CLASS_UNIX equ 0x2000000
; SYS_WRITE      equ 0x4
; SYS_READ       equ 0x3
; SYS_EXIT       equ 0x1

; ; syscall_write ( rdi fd, rsi buffer, rdx size ) => rax bytes_written
; syscall_write:
;     mov rax, SYS_CLASS_UNIX | SYS_WRITE
;     syscall
;     ret

; ; syscall_read ( rdi fd, rsi buffer, rdx size ) => rax bytes_written
; syscall_read:
;     mov rax, SYS_CLASS_UNIX | SYS_READ
;     syscall
;     ret

; ; syscall_exit ( rdi exit_code )
; syscall_exit:
;     mov rax, SYS_CLASS_UNIX | SYS_EXIT
;     syscall
;     ret
