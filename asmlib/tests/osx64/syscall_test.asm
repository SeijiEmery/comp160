
global start
section .data
lit_helloMsg: db "Hello, World!\n",0
    .length: equ $ - lit_helloMsg
strbuf: resb 4096
    .length: equ 4096

section .text
start:
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

SYS_CLASS_UNIX equ 0x2000000
SYS_WRITE      equ 0x4
SYS_READ       equ 0x3
SYS_EXIT       equ 0x1

; syscall_write ( rdi fd, rsi buffer, rdx size ) => rax bytes_written
syscall_write:
    mov rax, SYS_CLASS_UNIX | SYS_WRITE
    syscall
    ret

; syscall_read ( rdi fd, rsi buffer, rdx size ) => rax bytes_written
syscall_read:
    mov rax, SYS_CLASS_UNIX | SYS_READ
    syscall
    ret

; syscall_exit ( rdi exit_code )
syscall_exit:
    mov rax, SYS_CLASS_UNIX | SYS_EXIT
    syscall
    ret
