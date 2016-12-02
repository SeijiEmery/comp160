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
    stdin_buffer:  resb IO_BUFFER_SIZE
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

; Byte-packing macros (defined for little-endian; redefine for big-endian)
%define BP4(a,b,c,d) (a)|(b<<8)|(c<<16)|(d<<24)
%define BP3(a,b,c)   BP4(a,b,c,0)
%define BP2(a,b)     (a)|(b<<8)

; Clrscr()
DECL_FCN Clrscr
    ; Write clear command 27,"[2J"
    mov [stdout_buffer], dword BP4(27,'[','2','J')
    ; mov [stdout_buffer+0], byte 27  ; esc
    ; mov [stdout_buffer+1], byte '['
    ; mov [stdout_buffer+2], byte '2'
    ; mov [stdout_buffer+3], byte 'J'

    ; write reset to 0,0 command 27,"[0;0H"
    mov [stdout_buffer+4], dword BP4(27,'[','0',';')
    ; mov [stdout_buffer+4], byte 27  ; esc
    ; mov [stdout_buffer+5], byte '['
    ; mov [stdout_buffer+6], byte '0'
    ; mov [stdout_buffer+7], byte ';'
    mov [stdout_buffer+8], dword BP3(0,';','H')
    ; mov [stdout_buffer+8], byte '0'
    ; mov [stdout_buffer+9], byte ';'
    ; mov [stdout_buffer+10],byte 'H'

    SYSCALL_WRITE STDOUT, stdout_buffer, 11
END_FCN Clrscr

DECL_FCN ResetTextColor
section .data
    .clearColor: db 27,"[39;49m",0
    .clearColor.length: equ $ - .clearColor - 1 
    .clearAll:   db 27,"[0m",0
    .clearAll.length: equ $ - .clearAll - 1
section .text
    SYSCALL_WRITE STDOUT, .clearAll, .clearAll.length
END_FCN ResetTextColor



; Gotoxy( dh screen_y, dl screen_x )
DECL_FCN Gotoxy
    ; Write equivalent of printf("^[[%d,%dH", screen_x, screen_y) to stdout
    IO_ENTER_STDOUT
    mov [edi], word BP2(27,'[')
    inc edi
    inc edi

    ; WRITE_CHR byte 27    ; esc
    ; WRITE_CHR byte '['
    push eax
    xor eax, eax
    mov al, dl
    push eax
    mov al, dh
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

; Color definitions
black        equ 0
blue         equ 1
green        equ 2
cyan         equ 3
red          equ 4
magenta      equ 5
brown        equ 6
lightGray    equ 7
gray         equ 8 | black
lightBlue    equ 8 | blue
lightGreen   equ 8 | green
lightCyan    equ 8 | cyan
lightRed     equ 8 | red
lightMagenta equ 8 | magenta
yellow       equ 8 | brown
white        equ 8 | lightGray

; SetTextColor( ax color )
DECL_FCN SetTextColor
section .data
    ; Lookup table to translate DOS => SGR colors.
    ; Necessary b/c of different mappings.
    .colorLut:
        db "0" ; black/gray:           0/8
        db "4" ; blue/lightBlue:       1/9
        db "2" ; green/lightGreen:     2/10
        db "6" ; cyan/lightCyan:       3/11
        db "1" ; red/lightRed:         4/12
        db "5" ; magenta/lightMagenta: 5/13
        db "3" ; brown/yellow:         6/14
        db "7" ; lightGray/white:      7/15
    %macro WRITE_COLOR_CODE 1
        mov edx, eax
        and edx, 0x7
        mov dl, [edx + .colorLut]
        mov [edi+%1], dl
        test eax, 0x8
        jnz %%lskip
            mov [edi+%1+1], word BP3(';','1',0)
            inc edi
            inc edi
        %%lskip:
    %endmacro
section .text
    push eax
    push edx
    ; write("\x[4%s;3%sm", lut(color & 0xf, (color >> 4) & 0xf))
    IO_ENTER_STDOUT
    ; test eax, 0x8
    ; jnz .skip
    ;     ; mov [edi], word BP2(';','1')
    ;     ; add edi, 2
    ; .skip:

    mov [edi], dword BP4(27,'[','4',0)
    WRITE_COLOR_CODE 3
    
    shr eax, 4
    mov [edi+4], word BP2(';','3')
    WRITE_COLOR_CODE 6
    mov [edi+7], byte 'm'
    add edi, 8
    IO_EXIT_STDOUT
    pop edx
    pop eax
END_FCN SetTextColor


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

DECL_FCN ReadHex
    push esi
    push edx
    push ecx
    push ebx

    mov edx, stdin_buffer
    mov ecx, IO_BUFFER_SIZE
    call ReadString

    mov esi, stdin_buffer
    mov ebx, 16
    call parseInt

    pop ebx
    pop ecx
    pop edx
    pop esi
END_FCN  ReadHex

DECL_FCN ReadDec
    push esi
    push edx
    push ecx
    push ebx

    mov edx, stdin_buffer
    mov ecx, IO_BUFFER_SIZE
    call ReadString

    mov esi, stdin_buffer
    mov ebx, 10
    call parseInt

    pop ebx
    pop ecx
    pop edx
    pop esi
END_FCN ReadDec

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
