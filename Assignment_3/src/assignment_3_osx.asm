
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
    chr_0: db 30h
    chr_A: db 41h

    io_buffer: times SCRATCH_MEM db 0

section .text

; Writes a zero-delimited c string in esi to edi.
writeStr:
    push eax  ; save eax
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
writeHex32:
    push ebp
    mov ebp,esp

    push ebx
    push edx

    add edi,8
    call .writeByte
    call .writeByte
    call .writeByte
    call .writeByte
    add edi,8

    pop edx
    pop ebx
    xor eax,eax

    mov esp,ebp
    pop ebp
    ret

    .writeByte:
    xor edx,edx
    mov ebx,10
    div ebx

    cmp edx,10
    cmovb  ebx,[chr_0]
    cmovae ebx,[chr_A]
    add dh,bl
    add dl,bl

    mov [edi-2],dh
    mov [edi-1],dl
    sub edi,2
    ret


; writes value in eax as a hexadecimal string to [edi]
writeHex:
    push ebp
    mov  ebp,esp

    push ebx
    push edx

    xor edx,edx

    cmp eax,0
    jnz .loop

    mov [edi],byte 30h ; '0'
    inc edi
    jmp .end

    .loop:
    ; divide value in eax by 10. Result stored as follows:
    ;  eax => quotient  (eax / 10)
    ;  edx => remainder (edx % 10)
    mov ebx,10
    div ebx

    ; Here's a bit of cleverness using the cmov instructions:
    ; adds edx += '0' if edx < 10,
    ;      edx += 'A' if edx >= 10.
    cmp    edx,10
    cmovb  ebx,[chr_0]
    cmovae eax,[chr_A]
    add edx,ebx

    ; store byte + advance
    mov [edi],dl
    inc edi

    cmp eax,0
    jnz .loop

    .end:
    pop ebx
    pop edx

    mov esp,ebp
    pop ebp
    ret


; dumpRegisters(): writes contents of rax,rbx,rcx,rdx to stdout.
dumpRegisters:
    push ebp
    mov  ebp,esp

    push eax
    push ebx
    push ecx
    push edx

    push esi
    push edi

    mov edi,io_buffer

    ; write "eax = " to io_buffer
    mov esi,str_eax
    call writeStr

    call writeHex32

    ; write "ebx = " to io_buffer
    mov esi,str_ebx
    call writeStr

    mov eax,ebx
    call writeHex32

    ; write "ecx = " to io_buffer
    mov esi,str_ecx
    call writeStr

    mov eax,ecx
    call writeHex32

    ; write "edx = " to io_buffer
    mov esi,str_edx
    call writeStr

    mov eax,edx
    call writeHex32

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

    pop edi
    pop esi

    pop edx
    pop ecx
    pop ebx
    pop eax

    mov esp,ebp
    pop ebp
    ret



