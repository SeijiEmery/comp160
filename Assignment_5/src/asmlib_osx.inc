;
; asmlib_osx.inc
;
; This is a small library (work in progress) that provides 32-bit system calls,
; namely exit() and write(), and various string writing functions with an internal
; text buffer.
;
; The system calls are specific to osx 32-bit (and bsd), but the rest of the code
; is fairly portable. Will need to rewrite for 64-bit code.
;
; Note: this library uses edi for program output. Code that uses this register
; should save its value between io calls, or do:
;   call flushIO
;   other code...
;   call resetIO
;
; We also provide a default start procedure that calls _main + sets up / flushes io
; if ASMLIB_SETUP_MAIN is defined.
;

;
; Macros, etc
;

; Define size of the text buffer used for stdout. 
; Writing more than this many bytes between calls to flushIO will overflow.
%define IO_BUFFER_SIZE 4096

; WRITE_STR {string_literal} macro: 
; Declares a local string literal (data section), and prints that string to dsi by calling writeStr.
%macro WRITE_STR 1
    section .data
        %%str: db %1,0
    section .text
        mov esi,%%str
        call writeStr
%endmacro 

; DECL_FCN fcn_name macro:
; Declares the start of a function using the label fcn_name, and creates a esp/ebp stack frame.
%macro DECL_FCN 1
%1: 
    push ebp
    mov  ebp,esp
%endmacro

; END_FCN fcn_name macro:
; Declares the end of a function (fcn_name just included for readability).
; Expands to instructions that exit the stack frame + returns (ret).
%macro END_FCN 1
    mov esp,ebp
    pop ebp
    ret
%endmacro

section .text

; Optional program setup
%ifdef ASMLIB_SETUP_MAIN
global start
start:
    call resetIO
    call _main
    call flushIO

    push 0
    call syscall_exit
%endif

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
    int 0x80  ; bsd syscall interrupt
    ret

; https://en.wikipedia.org/wiki/Standard_streams
%define STDIN  0
%define STDOUT 1
%define STDERR 2

section .bss
io_buffer: resb IO_BUFFER_SIZE

section .text
DECL_FCN resetIO
    mov edi, io_buffer
END_FCN  resetIO

DECL_FCN flushIO
    ; Flush I/O (syscall write)
    sub  edi,io_buffer    ; calculate num bytes in edi (edi - io_buffer)
    jle  .skip            ; skip iff no bytes to write (size == 0 or size < 0)

    ; clamp size to IO_BUFFER_SIZE
    cmp edi,IO_BUFFER_SIZE
    jle .noClamp
    mov edi,IO_BUFFER_SIZE
    .noClamp:

    push edi              ; push size
    push io_buffer        ; push &buffer[0]
    push STDOUT           ; push stdout (0, in this case...?)
    call syscall_write    ; syscall_write( file_descriptor, str_ptr, size )

    .skip:
    mov edi,io_buffer     ; reset I/O buffer
END_FCN flushIO


; Writes a zero-terminated string from esi to edi.
DECL_FCN writeStr
    push eax
    xor eax,eax
    .l1:
    mov al,[esi]
    cmp al,0
    jz .end

    mov [edi],al
    inc esi
    inc edi
    jmp .l1

    .end:
    pop eax
END_FCN writeStr

; Writes value in eax to edi as a hexadecimal string.
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

; Writes value in eax to edi as a hexadecimal string.
DECL_FCN writeHex16
    push ebx
    push edx

    add edi,4
    call writeByte
    call writeByte
    add edi,4

    pop edx
    pop ebx
    xor eax,eax
END_FCN writeHex16

; Writes value in eax to edi as a hexadecimal string.
DECL_FCN writeHex8
    push ebx
    push edx

    add edi,2
    call writeByte
    add edi,2

    pop edx
    pop ebx
    xor eax,eax
END_FCN writeHex8


; Helper function: writes the lower 256-bits of eax to edi.
writeByte:
    dec edi
    call writeHalfByte
    dec edi
    call writeHalfByte
    ret

; Helper function: writes the lower 16-bits of eax to edi.
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

; Writes value in eax to edi as a decimal string.
DECL_FCN writeDecimal
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

    ; divide eax by 10 + write digit until eax == 0
    .l1:
    xor edx,edx   ; divide eax by 10.
    mov ebx,10    ; after division, quotient stored in eax + remainder in edx.
    div ebx      

    add dl, 30h   ; add 30h (ascii '0') to convert to ascii 
    mov [edi], dl ; write digit to edi
    inc edi
    inc ecx       ; track num digits

    cmp eax,0     ; repeat until eax == 0
    jg .l1

    ; Reverse output (since we actually wrote digits in reverse)
    
    push edi      ; save original edi
    xor edx,edx

    .l2:
    dec edi       ; swap [esi] (front value) + [edi] (back value)
    mov al,[edi]
    mov dl,[esi]
    mov [edi],dl
    mov [esi],al
    inc esi

    cmp edi,esi   ; repeat while edi > esi
    jg  .l2
    
    pop edi       ; restore original edi

    .end:
    pop esi ; restore values
    pop edx
    pop ebx
END_FCN writeDecimal

; WRITE_REG <register>: calls writeHex32 using the passed in register.
%macro WRITE_REG 1
    mov eax,%1
    call writeHex32
%endmacro
%define WRITE_HEX WRITE_REG

%macro WRITE_EOL 0
    mov [edi],byte 10
    add edi,1
%endmacro

; dumpRegisters(): writes contents of eax,ebx,ecx,edx to edi.
DECL_FCN dumpRegisters
    push eax
    push ebx
    push ecx
    push edx
    push esi

    push ebp
    mov  ebp,esp

    ; write register values (calls writeHex32; see WRITE_REG impl)
    WRITE_STR {"eax = "}
    WRITE_REG eax

    WRITE_STR {"  ebx = "}
    WRITE_REG ebx

    WRITE_STR {"  ecx = "}
    WRITE_REG ecx

    WRITE_STR {"  edx = "}
    WRITE_REG edx

    WRITE_STR {"  esp = "}
    WRITE_REG esp

    WRITE_STR {"  ebp = "}
    WRITE_REG ebp

    ; add '\n' character
    mov [edi],byte 10
    inc edi

    mov esp,ebp
    pop ebp

    pop esi

    pop edx
    pop ecx
    pop ebx
    pop eax
END_FCN dumpRegisters


