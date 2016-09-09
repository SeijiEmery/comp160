
global start

section .data
str_hello: db "Hello, World!",10,0

section .text
start:
    ; Enter main()
    call _main

    push -1
    call syscall_exit

;
; function main ()
;
_main:
    push 14
    push str_hello
    push 0
    call syscall_write

    ; Set registers to execute (A + B) - (C + D)
    ; (represented, conveniently, by rax = A, rbx = B, etc)
    mov eax,7
    mov ebx,8
    mov ecx,5
    mov edx,3
    _breakpoint_setValues:   ; set a breakpoint here in lldb to inspect values.
    call dumpRegisters
    call dumpRegisters
    call dumpRegisters
    
    ; First addition operation: A += B, C += D.
    add eax,ebx
    add ecx,edx
    _breakpoint_addedValues: ; set a breakpoint here in lldb to inspect values.
    call dumpRegisters
    
    ; Second operation: A -= C.
    sub eax,ecx
    _breakpoint_done:        ; set a breakpoint here in lldb to inspect values.
    call dumpRegisters
    
    ; exit(0) -- Uses bsd syscall convention.
    push 0
    call syscall_exit
    ret
;
; End main().
;

;
; System calls (uses i386 bsd conventions).
; Arguments are passed on the stack in reverse order.
;

; exit (int exitcode).
syscall_exit:
    mov eax,1 ; syscall number
    int 0x80  ; bsd syscall interrupt

    ; Note: no ret b/c exit() kills the process and does not return.


; write (int fd, user_addr_t cbuf, user_size_t nbyte)
syscall_write:
    mov eax,4 ; syscall number
    int 0x80
    ret

; define stdout
%define stdout 0

;
; Helper functions, etc.
;

; Scratch buffer used by I/O
%define SCRATCH_MEM 1024
; section .bss
; io_buffer: resb SCRATCH_MEM  ; reserve N bytes

section .data
    str_eax: db "eax = 0x",0
    str_ebx: db "  ebx = 0x",0
    str_ecx: db "  ecx = 0x",0
    str_edx: db "  edx = 0x",0
    str_esp: db "  esp = 0x",0
    str_ebp: db "  ebp = 0x",0

    io_buffer: times SCRATCH_MEM db 0

%macro DECL_FCN 1
%1: 
    push ebp
    mov  ebp,esp
%endmacro
%macro END_FCN 1
    mov esp,ebp
    pop ebp
    ret
%endmacro

section .text

; Writes a zero-delimited c string in esi to edi.
writeStr:
    push eax  ; save eax
    xor eax,eax
    .loop:
    mov al,[esi]
    cmp al,0
    jz .exit

    mov [edi],al
    inc esi
    inc edi
    jmp .loop
    .exit:
    pop eax
    ret


; writes value in eax as a hexadecimal string to [edi]
DECL_FCN writeHex32

    push ebx
    push edx

    add edi,8
    call writeByte
    call writeByte
    call writeByte
    call writeByte
    add edi,8

    pop edx
    pop ebx
    xor eax,eax

END_FCN writeHex32

writeByte:
    dec edi
    call writeHalfByte
    dec edi
    call writeHalfByte
    ret

writeHalfByte:
    xor edx,edx
    mov ebx,16
    div ebx
    cmp edx,10
    jl  .writeDec
    jge .writeHex
    .writeDec:
    add dl, 30h
    mov [edi],dl
    ret
    .writeHex:
    add dl, 37h
    mov [edi],dl
    ret

; writes value in eax as a hexadecimal string to [edi]
DECL_FCN writeHex
    push ebx
    push edx
    push esi

    mov esi,edi  ; store original edi in esi

    cmp eax,0
    jnz .l1

    ; Value is zero, so just write '0' to edi
    mov [edi],byte 30h ; '0'
    inc edi
    jmp .end

    ; Otherwise:

    ; call writeHalfByte until eax == 0
    .l1:
    call writeHalfByte
    inc edi
    cmp eax, 0
    jg .l1

    ; Reverse output (since we actually wrote digits in reverse)
    .l2:
    dec edi
    mov al,[edi]
    mov [esi],al
    inc esi
    cmp edi,esi
    jg .l2
    mov edi,esi

    .end:
    pop esi ; restore values
    pop edx
    pop ebx
END_FCN writeHex

%define writeReg writeHex32

; dumpRegisters(): writes contents of rax,rbx,rcx,rdx to stdout.
DECL_FCN dumpRegisters
    push eax
    push ebx
    push ecx
    push edx

    push esi
    push edi

    push ebp
    mov  ebp,esp

    mov edi,io_buffer

    ; write "eax = " to io_buffer
    mov esi,str_eax
    call writeStr
    call writeReg

    ; write "ebx = " to io_buffer
    mov esi,str_ebx
    call writeStr
    mov eax,ebx
    call writeReg

    ; write "ecx = " to io_buffer
    mov esi,str_ecx
    call writeStr
    mov eax,ecx
    call writeReg

    ; write "edx = " to io_buffer
    mov esi,str_edx
    call writeStr
    mov eax,edx
    call writeReg

    mov esi,str_esp
    call writeStr
    mov eax,esp
    call writeReg

    mov esi,str_ebp
    call writeStr
    mov eax,ebp
    call writeReg

    ; add '\n' character
    mov [edi],byte 10
    inc edi
    
    ; calculate buffer_size in edi
    sub edi, io_buffer

    ; call write(stdout, io_buffer, buffer_size)
    push edi
    push io_buffer
    push 0
    call syscall_write

    mov esp,ebp
    pop ebp

    pop edi
    pop esi

    pop edx
    pop ecx
    pop ebx
    pop eax
END_FCN dumpRegisters



