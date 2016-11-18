; asmlib/src/osx32/irvine32.inc
;
; This is an abstraction layer that provides partial irvine32 calls
; using my asmlib implementation. This should enable you to write
; mostly the same code on both osx and win32, for example.
;
; I'll hold that my library is better on account of being both lower
; and higher level than irvine32, and it is much more ambitious,
; though at the moment it is only partially complete and is missing
; a bunch of features. I'm pretty much adding things as I go along,
; and 100% compatibility with irvine32 is not guaranteed (ideally
; should be compatible but may contain bugs, and our implementation
; is very different).
;
; Also: in the attempt to be compatible with irvine32, this may be
; much less efficient than the asmlib interface.
;
; Copyright 2016 Seiji Emery
;


; Implemented:
; Clrscr : Writes a carriage return / linefeed
; Crlf : output a new line
; Gotoxy : Locate the cursor
; Random32 : Generates an unsigned pseudo-random 32-bit integer
; Randomize : Re-seeds the random number generator with the current time in seconds.
; RandomRange : Returns an unsigned pseudo-random 32-bit integer in EAX, between 0 and n-1.
; WriteChar : write a character to stdout
; WriteDec : write a decimal number to stdout
; WriteHex : Writes an unsigned 32-bit hexadecimal number to the console window.
; WriteHexB : Writes an unsigned 32-bit hexadecimal number to the console window.
; WriteInt : Writes a 32-bit signed binary integer to the console window in ASCII decimal.
; WriteString : output a null-terminated string

; Unimplemented:
; Delay : Delay certain microseconds
; IsDigit : Determines whether the character in AL is a valid decimal digit.
; DumpMem : Writes a range of memory to standard output in hexadecimal.
; ParseDecimal32: convert the number string to a decimal number
; ParseInteger32 : Converts a string containing a signed decimal integer to binary. 
; Str_length : compute the length of null-teminated string
; Str_compare : Compare two strings.
; Str_trim : Remove all occurences of a given character from the end of a string.
; Str_ucase : Convert a null-terminated string to upper case.
; BufferFlush: flush the buffer and reset the related variables
; ReadKeys: read certain number of characters from buffer
; ReadDec : read Decimal number from buffer
; ReadHex : Reads a 32-bit hexadecimal integer from the keyboard
; ReadInt : Reads a 32-bit signed decimal integer from standard input
; ReadString : read string from input buffer
; ReadChar : read a character from stdin
; WriteBin : write a 32-bit binary number to console( interface )
; WriteBinB : write a 32-bit binary number to console

%include "osx32/asmlib.inc"

%define IO_BUFFER_SIZE 4096
section .bss
    stdout_buffer: resb IO_BUFFER_SIZE
section .data
    stdout_ptr: dd 0
section .text

;
; Writing functions
;
%macro IO_ENTER_STDOUT 0
    push edi
    mov edi, stdout_buffer
%endmacro
%macro IO_EXIT_STDOUT 0
    sub edi, stdout_buffer
    SYSCALL_WRITE STDOUT, stdout_buffer, edi
    pop edi
%endmacro

; Clrscr()
DECL_FCN Clrscr
    ; Write clear command 27,"[2J"
    mov [stdout_buffer+0], byte 27  ; esc
    mov [stdout_buffer+1], byte '['
    mov [stdout_buffer+2], byte '2'
    mov [stdout_buffer+3], byte 'J'

    ; write reset to 0,0 command 27,"[0;0H"
    mov [stdout_buffer+4], byte 27  ; esc
    mov [stdout_buffer+5], byte '['
    mov [stdout_buffer+6], byte '0'
    mov [stdout_buffer+7], byte ';'
    mov [stdout_buffer+8], byte '0'
    mov [stdout_buffer+9], byte ';'
    mov [stdout_buffer+10],byte 'H'

    SYSCALL_WRITE STDOUT, stdout_buffer, 11
END_FCN Clrscr

; Gotoxy( dh screen_y, dl screen_x )
DECL_FCN Gotoxy
    ; Write equivalent of printf("^[[%d,%dH", screen_x, screen_y) to stdout
    IO_ENTER_STDOUT
    WRITE_CHR byte 27    ; esc
    WRITE_CHR byte '['
    push eax
    xor eax, eax
    mov al, dh
    push eax
    mov al, dl
    push eax
    
    ; write screen_x
    pop eax
    call writeDecimal32
    WRITE_CHR byte ';'

    ; write screen_y
    pop eax
    call writeDecimal32
    WRITE_CHR byte 'H'

    pop eax
    IO_EXIT_STDOUT
END_FCN  Gotoxy

; Clrf()
DECL_FCN Crlf
    mov [stdout_buffer], byte 10
    SYSCALL_WRITE STDOUT, stdout_buffer, 1
END_FCN  Crlf

; WriteChar(al chr)
DECL_FCN WriteChar
    mov [stdout_buffer], al
    SYSCALL_WRITE STDOUT, stdout_buffer, 1
END_FCN  WriteChar

; WriteDec( eax unsigned_value )
DECL_FCN WriteDec
    IO_ENTER_STDOUT
    push eax
    call writeUnsignedDecimal32
    pop eax
    IO_EXIT_STDOUT
END_FCN  WriteDec

; WriteHex( eax value )
DECL_FCN WriteHex
    IO_ENTER_STDOUT
    WRITE_HEX_32 eax
    IO_EXIT_STDOUT
END_FCN  WriteHex

; WriteHexB( eax value, ebx bytes = 1|2|4)
DECL_FCN WriteHexB
    IO_ENTER_STDOUT
    WRITE_HEX_N eax, ebx
    IO_EXIT_STDOUT
END_FCN  WriteHexB

; WriteInt( eax signed_value )
DECL_FCN WriteInt
    IO_ENTER_STDOUT
    push eax
    call writeDecimal32
    pop eax
    IO_EXIT_STDOUT
END_FCN  WriteInt

; WriteString( edx str )
DECL_FCN WriteString
    pushad
    IO_ENTER_STDOUT
        WRITE_STRZ edx
    IO_EXIT_STDOUT
    popad
    ; pushad
    ; mov esi, edx
    ; mov edi, stdout_buffer
    ; mov ecx, IO_BUFFER_SIZE
    ; call strncpy

    ; mov esi, edi
    ; sub edi, stdout_buffer
    ; mov ecx, edi
    ; mov eax, STDOUT
    ; call _sys_write
    ; popad
END_FCN  WriteString

; ReadString
;   inout edx buffer
;   in    ecx buffer_size
;   out   eax bytes_read
DECL_FCN ReadString
    push edx
    push esi

    mov eax, 1
    mov esi, edx
    call _sys_read
    
    pop esi
    pop edx
END_FCN ReadString

;
; Random functions
;

; Random32 (-> eax randomValue)
DECL_FCN Random32
    call lcgRand32
END_FCN  Random32

; RandomRange( eax upBound -> eax randomValue )
DECL_FCN RandomRange
    call lcgRandRange
END_FCN  RandomRange

; Randomize()
DECL_FCN Randomize
    IO_ENTER_STDOUT
    WRITE_STR_LIT {10,"Unimplemented: irvine32 Randomize()",10}
    IO_EXIT_STDOUT
    SYSCALL_EXIT -1
END_FCN  Randomize


