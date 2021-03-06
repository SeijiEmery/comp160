; Assignment 3:
; Program Description: 
;   Calculates (A + B) - (C + D) using eax,ebx,ecx,edx.
;   Includes I/O routines to print register state to stdout, and messages
;   describing each operation and the final result. Also includes hooks to
;   inspect registers / program state using lldb (_breakpoint_****** symbols).
;
; Target platform: osx, 32-bit.
;   Uses posix syscalls (write, exit) using bsd 32-bit calling conventions.
;   Should run on linux with minor modifications.
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: 9/07/16
; Revisions: N/A (see git log)
; Date:              Modified by:
;

global start
section .text
start:
    ; Setup I/O
    ; Note: rather than doing syscall writes for every I/O op, all of our I/O operations
    ; (write, etc) actually just write to a temp buffer referenced by edi. Since we're only
    ; doing limited I/O, this gets flushed at the end of our program (but could be flushed
    ; at any point so long as edi gets reset).
    ;
    ; As such, any I/O operation is really just:
    ;    mov [edi], <some byte>
    ;    inc edi
    ; 
    ; Followed by call flushIO at some point.
    ;
    call resetIO  ; sets up edi (points to io_buffer)
    call _main    ; enter main()
    call flushIO  ; calls syscall_write w/ contents of edi + io_buffer

    ; exit(0) (uses bsd syscall convention)
    push 0
    call syscall_exit

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

section .data ; Declare variables (note: these are memory locations, not constants)
_varA: dd 7000
_varB: dd -600
_varC: dd 50
_varD: dd -3
_varResult: dd 0
section .text

DECL_FCN _main
    ; Set registers to execute (A + B) - (C + D)
    ; (represented, conveniently, by rax = A, rbx = B, etc)
    .prettyPrintProgramDescription:
        WRITE_STR {10,"This program calculates the result of (A + B) - (C + D)"}
        WRITE_STR {10,"where  A = 7000,"}
        WRITE_STR {10,"       B = -600,"}
        WRITE_STR {10,"       C = 50,"}
        WRITE_STR {10,"       D = -3",10,10}

    mov eax,[_varA]
    mov ebx,[_varB]
    mov ecx,[_varC]
    mov edx,[_varD]
    _breakpoint_setValues:   ; set a breakpoint here in lldb to inspect values.
        WRITE_STR {"Set registers:          "}
        call dumpRegisters
    
    ; First addition operation: A += B, C += D.
    add eax,ebx
    add ecx,edx
    _breakpoint_addedValues: ; set a breakpoint here in lldb to inspect values.
        WRITE_STR {"Added A += B, C += D:   "}
        call dumpRegisters
    
    ; Second operation: A -= C.
    sub eax,ecx
    _breakpoint_done:        ; set a breakpoint here in lldb to inspect values.
        WRITE_STR {"Added A -= C:           "}
        call dumpRegisters

    mov [_varResult],eax
    .prettyPrintResults:
        WRITE_STR {10,"Result: "}
        call writeDecimal     ; writes the value in eax (our result) as a decimal string
        mov [edi],byte 10     ; write eol
        inc  edi    
END_FCN _main

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

;
; Helper functions
;

; define stdout
%define stdout 0

; Scratch buffer used by I/O
%define SCRATCH_MEM_SIZE 4096
section .bss
io_buffer: resb SCRATCH_MEM_SIZE  ; reserve N bytes

section .text

DECL_FCN resetIO
    mov edi,io_buffer
END_FCN  resetIO

DECL_FCN flushIO
    ; Flush I/O (syscall write)
    sub  edi,io_buffer    ; calculate num bytes in edi (edi - io_buffer)
    jle  .skip            ; skip iff no bytes to write (size == 0 or size < 0)

    ; clamp size to SCRATCH_MEM_SIZE
    cmp edi,SCRATCH_MEM_SIZE
    jle .noClamp
    mov edi,SCRATCH_MEM_SIZE
    .noClamp:

    push edi              ; push size
    push io_buffer        ; push &buffer[0]
    push stdout           ; push stdout (0, in this case...?)
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

