;
; asmlib/algorithms/io_macros.inc
;
; Companion to + depends on asmlib/algorithms/io.inc
;

; SET_IO( fd, buffer, buf_sz )
%macro SET_IO 3
    mov kdi, %2
%endmacro

; FLUSH_IO( fd, buffer, buf_sz )
%macro FLUSH_IO 3
    pushad
    mov kax, %1
    mov ksi, %2
    mov kcx, %3
    call flushIO
    popad
    mov kdi, %2
%endmacro

%macro WRITE_HEX_N 2
    push kax
    push kcx
    mov kax, %1
    mov kcx, %2
    call writeHex
    pop kax
    pop kcx
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
    mov [kdi], BYTE 10
    inc kdi
%endmacro

%macro WRITE_0x 0
    mov [kdi+0], BYTE 48
    mov [kdi+1], BYTE 120
    add kdi, 2
%endmacro

%macro WRITE_CHR 1
    mov [kdi], byte %1
    inc kdi
%endmacro

%macro WRITE_STR 2
    push ksi
    push kcx
    mov ksi, %1
    mov kcx, %2
    call writeAsciiStr
    pop kcx
    pop ksi
%endmacro

%macro WRITE_STRZ 1
    push ksi
    mov ksi, %1
    call writeAsciiStrz
    pop ksi
%endmacro

%macro WRITE_STR_LIT 1
section .data
    %%str: db %1,0
section .text
    WRITE_STRZ %%str
%endmacro

%macro WRITE_DEC 1
    push kax
    mov kax, %1
    call writeDecimal32
    pop kax
%endmacro

%macro SET_WRITE_TARGET 1
    push kax
    mov kax, %1
    call setWriteTarget
    pop kax
%endmacro
