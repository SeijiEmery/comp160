global start

section .data
_intarray:    ; FEDCBA9876543210
    .data: dq 0x1000000000000000, 0x2000000000000000, 0x3000000000000000, 0x4000000000000000

section .text
start:
    call sayHello

    mov rcx, 4
    mov rsi, _intarray.data
    xor rax, rax

    .L1:
    add rax, [rsi]
    add rsi, 8
    sub rcx, 1
    jnz .L1

    call _writeHex64

    ; syscall exit(0)
    mov rax, 0x2000001   ; exit
    mov rdi, 0           ; argument
    syscall

section .bss
iobuf: resb 4096
section .data
hello:
    .msg:    db "Hello, World!", 10
    ; .length: dq 14
section .text

sayHello:
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, hello.msg
    mov rdx, 14
    syscall
    ret

; Writes value in rax as a 64-bit hexadecimal integer to stdout.
_writeHex64:
    push rsi
    push rdi
    push rdx
    push rbx
    push rax

    mov rsi, iobuf
    mov [rsi], BYTE 48
    mov [rsi+1], BYTE 120

    add rsi, 18
    call writeByte
    call writeByte
    call writeByte
    call writeByte
    call writeByte
    call writeByte
    call writeByte
    call writeByte

    mov rsi, iobuf
    mov [rsi+18], BYTE 10

    mov rax, 0x2000004  ; write
    mov rdi, 1          ; stdout
    mov rdx, 19         ; msg.length (ptr already stored in rsi)
    syscall

    pop rax
    pop rbx
    pop rdx
    pop rdi
    pop rsi
    ret

writeByte:
    dec rsi
    call writeHalfByte
    dec rsi
    call writeHalfByte
    ret

writeHalfByte:
    mov dl, al
    and dl, 0xf
    cmp dl, 0xA
    jl  .l
    add dl, 0x7
.l: add dl, 0x30
    mov [rsi], dl
    shr rax, 4
    ret





