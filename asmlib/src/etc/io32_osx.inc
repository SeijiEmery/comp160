
%macro WRITE_HEX_N 2
    push eax
    push ecx
    mov eax, %1
    mov ecx, %2
    call writeHex
    pop eax
    pop ecx
%endmacro

%macro WRITE_HEX_64 1
    WRITE_HEX_N %1 8
%endmacro

%macro WRITE_HEX_32 1
    WRITE_HEX_N %1 4
%endmacro

%macro WRITE_HEX_16 1
    WRITE_HEX_N %1 2
%endmacro

%macro WRITE_HEX_8 1
    WRITE_HEX_N %1 1
%endmacro

%macro WRITE_EOL
    mov [edi], BYTE 10
    inc edi
%endmacro

%macro WRITE_0x
    mov [edi+0], BYTE 48
    mov [edi+1], BYTE 120
    add edi, 2
%endmacro

%macro WRITE_STR 2
    push esi
    push ecx
    mov esi, %1
    mov ecx, %2
    call writeAsciiStr
    pop ecx
    pop esi
%endmacro

%macro WRITE_STRZ 1
    push esi
    mov esi, %1
    call writeAsciiStrz
    pop esi
%endmacro

%macro WRITE_DEC 1
    push eax
    mov eax, %1
    call writeDecimal
    pop eax
%endmacro

; Implementation note: All write*** integer algorithms work backwards:
; we repeatedly divide the integer by its base, and write the modulo
; to some output (the rdi pointer).
;
; This produces _reversed_ output, since we're writing what should be
; the last / lowest digit first (and we're used to reading left -> right,
; not vice versa), so the output will need to be re-reversed at some point.
;
; For writeHex <N bytes>, we know how many characters we're writing ahead
; of time (it's num_bytes * 2, since each digit repr by a 2-digit hex #),
; so we can just advance rdi by rcx * 2, and write the digits in reverse.
;
; For writeDecimal, we don't know how many characters we'll be writing,
; so we just write each digit out reversed, then explicitely re-reverse
; the output in a second loop.
;

; Writes rcx bytes from the value in rax to rdi as a hexadecimal integer.
DECL_FCN writeHex
    cmp ecx, 8    ; clamp rcx to [0, 8].
    jg  .clampTo8
    jmp .skip
    .clampTo8:
        mov ecx, 8
    .skip:

    shl ecx, 1     ; rcx *= 2
    push ecx
    add edi, rcx   ; rdi += num_bytes * 2

    .writeHalfByte:
        dec edi
        mov dl, al     ; load lowest byte of rax into dl
        and dl, 0xf    ; and use bitwise op to get lowest 4 bits
        cmp dl, 0xa
        jl .l1
             add dl, 0x7    ; if dl >= 10, add 0x37 (10 + 0x37 = 'A')
        .l1: add dl, 0x30   ; if dl <  10, add 0x30 (10 + 0x30 = '0')
        mov [edi], dl
        shr eax, 4      ; 
        loop .writeHalfByte

    pop ecx
    add edi, ecx  ; rdi += num_bytes * 2
END_FCN writeHex

DECL_FCN writeAsciiStrz
    push eax
    .l1:
        mov al, [esi]
        cmp al, 0
        je .end
        mov [edi], al
        inc esi
        inc edi
        jmp .l1
    .end:
    pop eax
END_FCN writeAsciiStrz

DECL_FCN writeAsciiStr
    push eax
    cmp  ecx, 0
    jle .end
    .l1:
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
        loop .l1
    .end:
    pop eax
END_FCN writeAsciiStr

DECL_FCN writeDecimal
    push ebx
    push edx
    push esi

    cmp  eax, 0     ; special case for rax == 0 (write '0' and return)
    je  .writeZero

    mov  ebx, 10
    push edi       ; save start ptr
    .writeDigitsReversed:
        xor edx, edx    ; clear rdx
        idiv ebx        ; rdx:rax /= rbx (10). quotient stored in rax, modulo in rdx.
        add dl, 0x30    ; [0-9] + 0x30 => ascii '0'-'9'
        mov [edi], dl   ; write to rdi
        inc edi
        cmp eax, 0      ; repeat until rax == 0
        jne .writeDigitsReversed

    pop  esi        ; restore start ptr (rsi) and save end ptr (rdi)
    push edi
    .reverseDigits:
        cmp esi, edi    ; until rsi >= rdi:
        jge .endReverse

        mov al, [esi]   ; swap [rsi], [rdi]
        mov dl, [edi]
        mov [esi], dl
        mov [edi], al
        inc esi         ; ++rsi, --rdi
        dec edi
        jmp .reverseDigits
    .endReverse:
    pop edi        ; restore end ptr after reversal
    jmp .end

    .writeZero:
        mov [edi], byte 0x30 ; write '0'
        inc edi
        jmp .end

    .end:
    pop esi
    pop edx
    pop ebx
END_FCN writeDecimal

















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


