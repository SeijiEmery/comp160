; asmlib/src/osx32/asmlib.inc
;
; This is a small library (work in progress) that provides 32-bit system calls
; and various utilities like string functions and generalized I/O on osx.
;
; Copyright 2016 Seiji Emery
;

;
; Note: at some point we will break this into multiple files and make our I/O
; crossplatform (given nasm and 32-bit calls), but due to time consteaints,
; I'm just dumping this into one file.
;

;
; Special options:
;
;   define ASMLIB_SETUP_MAIN to tell the library to create a start procedure
;   that will setup I/O, call exit(0) by default, and call a function named _main.
;

;
; Config
;

; Defines size used for I/O buffer
%define IO_BUFFER_SIZE 4096

;
; General purpose macros
;

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

; System calls, etc. Uses i386 osx conventions.
%define STDIN  0
%define STDOUT 1
%define STDERR 2

; osx 32-bit syscalls. 
; Note: these use a 16-byte aligned stack, apparently:
; https://filippo.io/making-system-calls-from-assembly-in-mac-os-x/
;

%macro PRE_EXEC_SYSCALL 0
    push ebp
    mov ebp, esp
    and esp, 0xffffffff ; advance to next 16-byte boundary
%endmacro

%macro EXEC_SYSCALL 1
    mov eax, %1
    int 0x80
    mov esp, ebp
    pop ebp
%endmacro

; void exit(int rval);
%macro SYSCALL_EXIT 1
    PRE_EXEC_SYSCALL
    push %1
    sub esp, 4
    ; push %1
    ; sub esp, 4
    EXEC_SYSCALL 1
%endmacro

; user_ssize_t write(int fd, user_addr_t cbuf, user_size_t nbyte)
%macro SYSCALL_WRITE 3
    PRE_EXEC_SYSCALL
    push %3
    push %2
    push %1
    sub esp, 4
    EXEC_SYSCALL 4
%endmacro

%undef PRE_EXEC_SYSCALL
%undef EXEC_SYSCALL

;
; I/O macros
;

; SET_IO( fd, buffer, buf_sz )
%macro SET_IO 3
    mov edi, %2
%endmacro

; FLUSH_IO( fd, buffer, buf_sz )
%macro FLUSH_IO 3
    sub edi, %2
    jle %%invalidOrZeroBytes
    cmp edi, %3
    jle %%sizeOk
        mov edi, %3
    %%sizeOk:
    SYSCALL_WRITE %1, %2, edi
    %%invalidOrZeroBytes:
    mov edi, %2
%endmacro

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
    WRITE_HEX_N %1, 8
%endmacro

%macro WRITE_HEX_32 1
    WRITE_HEX_N %1, 4
%endmacro

%macro WRITE_HEX_16 1
    WRITE_HEX_N %1, 2
%endmacro

%macro WRITE_HEX_8 1
    WRITE_HEX_N %1, 1
%endmacro

%macro WRITE_EOL 0
    mov [edi], BYTE 10
    inc edi
%endmacro

%macro WRITE_0x 0
    mov [edi+0], BYTE 48
    mov [edi+1], BYTE 120
    add edi, 2
%endmacro

%macro WRITE_CHR 1
    mov [edi], byte %1
    inc edi
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

%macro WRITE_STR_LIT 1
section .data
    %%str: db %1
section .text
    WRITE_STRZ %%str
%endmacro

%macro WRITE_DEC 1
    push eax
    mov eax, %1
    call writeDecimal32
    pop eax
%endmacro

%macro SET_WRITE_TARGET 1
    push eax
    mov eax, %1
    call setWriteTarget
    pop eax
%endmacro

;
; Library implementation
;

section .text
; Optional program setup
%ifdef ASMLIB_SETUP_MAIN
global start
start:
    ; SET_WRITE_TARGET STDOUT
    call _main
    ; call flushIO
    SYSCALL_EXIT 0
%endif

section .text

; Implementation note: All write*** integer algorithms work backwards:
; we repeatedly divide the integer by its base, and write the modulo
; to some output (the edi pointer).
;
; This produces _reversed_ output, since we're writing what should be
; the last / lowest digit first (and we're used to reading left -> right,
; not vice versa), so the output will need to be re-reversed at some point.
;
; For writeHex <N bytes>, we know how many characters we're writing ahead
; of time (it's num_bytes * 2, since each digit repr by a 2-digit hex #),
; so we can just advance edi by ecx * 2, and write the digits in reverse.
;
; For writeDecimal, we don't know how many characters we'll be writing,
; so we just write each digit out reversed, then explicitely re-reverse
; the output in a second loop.
;

; Writes ecx bytes from the value in eax to edi as a hexadecimal integer.

; writeHex( eax value, ecx num_digits, edi out_buffer )
;   does not preserve eax / ecx (use WRITE_HEX_**** to preserve both)
DECL_FCN writeHex
    cmp ecx, 8    ; clamp ecx to [0, 8].
    jg  .clampTo8
    jmp .skip
    .clampTo8:
        mov ecx, 8
    .skip:

    shl ecx, 1     ; ecx *= 2
    push ecx
    add edi, ecx   ; edi += num_bytes * 2

    .writeHalfByte:
        dec edi
        mov dl, al     ; load lowest byte of eax into dl
        and dl, 0xf    ; and use bitwise op to get lowest 4 bits
        cmp dl, 0xa
        jl .l1
             add dl, 0x7    ; if dl >= 10, add 0x37 (10 + 0x37 = 'A')
        .l1: add dl, 0x30   ; if dl <  10, add 0x30 (10 + 0x30 = '0')
        mov [edi], dl
        shr eax, 4     ; eax /= 16
        loop .writeHalfByte

    pop ecx
    add edi, ecx  ; edi += num_bytes * 2
END_FCN writeHex

; writeAsciiStrz( esi str, edi out_buffer )
;   does not preserve esi (use WRITE_STR for register preservation)
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

; writeAsciiStrz( esi str, ecx num_bytes, edi out_buffer )
;   does not preserve esi / ecx (use WRITE_STR for register preservation)
DECL_FCN writeAsciiStr
    push eax
    cmp ecx, 0
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

; writeDecimal32( eax value, edi out_buffer )
;   does not preserve eax (use WRITE_DEC for register preservation)
DECL_FCN writeDecimal32
    test eax, 0x80000000     ; Handle negative numbers:
    jz .isPositive
        xor eax, 0xffffffff
        inc eax
        mov [edi], byte 45          ; '-'
        inc edi
    .isPositive:
    push ebx
    push edx
    push esi

    cmp eax, 0     ; special case for eax == 0 (write '0' and return)
    je  .writeZero

    mov ebx, 10
    push edi       ; save start ptr
    .writeDigitsReversed:
        xor edx, edx    ; clear edx
        idiv ebx        ; edx:eax /= ebx (10). quotient stored in eax, modulo in edx.
        add dl, 0x30    ; [0-9] + 0x30 => ascii '0'-'9'
        mov [edi], dl   ; write to edi
        inc edi
        cmp eax, 0      ; repeat until eax == 0
        jne .writeDigitsReversed

    pop esi        ; restore start ptr (esi) and save end ptr (edi)
    push edi
    dec edi        ; must move back 1 for loop (normally, edi points to the 
                   ; _next_ chr, but here we want it to point to the last written chr)
    .reverseDigits:
        cmp esi, edi    ; until esi >= edi:
        jge .endReverse

        mov al, [esi]   ; swap [esi], [edi]
        mov dl, [edi]
        mov [esi], dl
        mov [edi], al
        inc esi         ; ++esi, --edi
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
END_FCN writeDecimal32


; lcgNextRand( eax value -> eax nextValue )
; Generates a random number in the range [0, 2^31) using a 
; linear congruental generator. Uses coefficients from the 
; c standard library.
; Does NOT use an internal seed (pass the seed value in eax).
; See lcgRand32 and lcgRandRange for more usable versions.
;
DECL_FCN lcgNextRand
    push edx
    mov edx, 1103515245  ; multiplier coefficient form the c standard library
    mul edx
    add eax, 12345       ; additive coefficient from the c standard library
    and eax, 0x7fffffff  ; clamp to [0, 2^31] for some reason...?
    pop edx
END_FCN  lcgNextRand

section .data
    lcg_seed: dd 0
section .text

%macro LCG_SET_SEED 1
    mov [lcg_seed], %1
%endmacro
%macro LCG_GET_SEED 1
    mov %1, [lcg_seed]
%endmacro

; lcgRand32 (-> eax randomValue)
; Generates a random 32-bit integer.
DECL_FCN lcgRand32
    LCG_GET_SEED eax
    call lcgNextRand
    LCG_SET_SEED eax
END_FCN  lcgRand32


; lcgRandRange( eax upBound -> eax randomValue )
; Generates a random integer in the range [0, eax).
; Uses the internal seed associated with LCG_GET_SEED / LCG_SET_SEED
DECL_FCN lcgRandRange
    push ebx            ; save registers
    push edx
    push eax            ; save up bound

    LCG_GET_SEED eax    ; get random number on [0, 2^31)
    call lcgNextRand
    LCG_SET_SEED eax

    pop ebx             ; restore up bound
    xor edx, edx        ; divide (edx:eax) /= ebx
    div ebx             ; after div, eax = quot, edx = rem

    mov eax, edx        ; the remainder is our result, so store that in eax

    pop edx             ; restore registers
    pop ebx
END_FCN
